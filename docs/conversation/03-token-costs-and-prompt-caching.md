# Token costs and prompt caching

_Source: `docs/conversation_json.md` lines 141–217. See [README](README.md) for context._

**Covers:** Why input and output tokens are priced separately (prefill vs decode); prompt caching tiers; isolating cache between parallel runs (`DISABLE_PROMPT_CACHING` vs a per-run `prompt-cache-key`).

**User:** If you can find it in my other chat sessions, there's one where I'm talking to the AI about how LLMs work — the attention layer and the feedforward layer, the dimensionality, the hidden dimensions and all of that. Can you find that chat and pull it into context?

**Agent:** Let me search for that.

Found it — that's the "Parameters, context, and vectors in AI models" conversation from earlier this month, where you built up the transformer stack from tokens through attention, feedforward blocks, hidden dimensionality, mixture of experts, all of it. It's pulled into context now.

What did you want to connect back from there into this telemetry discussion?

**User:** So, a clarification about token costs. As I understand it, most AI providers charge based on input tokens and output tokens. Now let me have a think about that. In terms of the number of input tokens, if I just go and send a message of, let's say, 100,000 tokens,

**User:** the AI didn't need to do any reasoning to calculate any of those tokens. But on the 100,001st token, that's where you've got that quadratic cost, right, for inferring the output token?

**User:** And so that's why they kind of charge for both the input tokens and the output tokens.

**Agent:** Hmm, let's untangle that a bit, because the quadratic cost isn't quite sitting where you've placed it.

That quadratic attention cost applies to the whole input, not just the final token. When the model processes your hundred thousand token message, it does what's called the prefill pass, computing attention across the entire prompt, and that step is genuinely order n-squared in the sequence length, because every token's query has to attend against every other token's key. So the expense is baked into consuming those hundred thousand input tokens in the first place, not concentrated at token one hundred thousand specifically.

Then, generating each output token afterward is comparatively cheap per step, because of the KV cache we talked about before, the keys and values for all the input tokens are already computed and stored, so each new output token only needs to compute its own query and attend against that cached set. That's roughly linear per output token, not quadratic. So the real reason providers charge separately for input and output isn't "input is cheap, output is where the quadratic cost hides", it's almost the opposite: input tokens are the expensive quadratic prefill pass done once, and output tokens are the cheaper, repeated, linear-ish decode steps, one per token generated. Does that match up with what you were picturing, or does that flip something for you?

**User:** I'm going to have to just revisit it. But the question was: often when I'm seeing the costings, there's also a cost around cache or something like that. And I've also seen Claude give me messages like "this cache probably doesn't exist anymore and you'll be charged again" or something. So can you just talk about what the nuance there is?

**Agent:** Right, prompt caching — genuinely useful to understand since it directly affects your Thunderjar cost measurements too.

The idea: if you send the same prefix of tokens repeatedly, say a large system prompt, a codebase's context, or earlier turns in a long agent session, the provider can cache the internal key and value tensors computed during that expensive prefill pass, rather than recomputing them from scratch on every single call. So the next request that shares that same prefix skips redoing the quadratic attention work for those tokens, and you get charged a much cheaper cache-read rate instead of the full input rate.

The catch is that cache has a short lifetime, often just a few minutes of inactivity, sometimes extendable, and it's tied to an exact matching prefix. So the warning you've seen from Claude, that the cache may have expired and you'll be billed at full price again, happens when too much time passes between calls, or when something upstream in the prompt changes, even slightly, which invalidates the cached prefix entirely since the match has to be exact from the start. There's also usually a separate, slightly higher cache-write cost the first time you create that cache entry, so the full picture is three tiers: a premium to write the cache, a discount to read it while it's warm, and standard full price if it's gone cold. Given Thunderjar's about comparing runs, that caching behavior is actually a meaningful confound if your benchmark reruns share prompt prefixes back to back versus with gaps.

**User:** Yeah. Okay, so there are a couple of things. One is that you wouldn't want your individual test cases to pollute each other in terms of costing. But the other is — actually, just as a first question: if we talk about the costing information that Claude gives you, whether it's from the telemetry or from that... is it a structured response object? Am I using the right term? Does that include information about costing as it relates to caching?

**Agent:** Yes, it does, and it breaks it down quite specifically rather than folding it into one number.

That confirms it precisely. The usage object in the structured result breaks token spend into four separate buckets rather than one input figure: plain input tokens, output tokens, cache creation tokens, meaning new content written into the cache, which actually costs about twenty five percent more than standard input, and cache read tokens, which cost roughly ten percent of the standard input rate, so a genuine discount, not just a wash.

So for Thunderjar you'd get exactly the granularity you need to detect that cross-contamination problem you flagged, if two test cases share a prefix and run close together, you'd see it show up directly as cache read tokens in the second run's result object, which would flag that the run wasn't a clean, independent cost measurement.

**User:** Right, now, actually,

**Agent:** Go ahead.

**User:** So is there a way we could instruct it to basically ignore the previous cache? I think that's what you want to do. When you're doing your `claude -p`, you want to say, all right, this is a brand new session, please ignore any cache.

**Agent:** Good news, two ways to handle it. There's an environment variable, `DISABLE_PROMPT_CACHING=1`, that turns caching off entirely, so every run genuinely pays fresh input pricing with no cross-contamination between test cases at all.

But actually, for Thunderjar specifically, you might not even need that. Since each `claude -p` invocation starts a brand new session by default with a cold cache, and caches are scoped per machine and directory with a short few-minute inactivity timeout, if your test harness just runs cases with any reasonable spacing, or across different working directories, they may naturally not share a warm cache anyway. Setting that environment variable is the clean, deterministic way to guarantee it though, rather than relying on timing.

**User:** Yeah, I don't want to rely on timing, because realistically one of the things we might be doing is spinning up the exact same prompt, the exact same model, the exact same harness, and running it 100 times simultaneously. Now, the way I'm thinking this is going to run is that they'll be running inside Docker containers

**Agent:** That actually solves your caching worry almost entirely on its own — separate Docker containers mean separate processes with separate home directories and separate session state, so there's no shared cache to accidentally read from between the hundred parallel runs in the first place. Setting `DISABLE_PROMPT_CACHING=1` in each container would just be belt and braces on top of that natural isolation.

Worth flagging though, running a hundred identical containers simultaneously is going to hammer your rate limits hard, that's a separate concern from caching but probably the more pressing one for that scenario.

**User:** And... sure. Yeah. Okay. All right. Now, the question was,

**Agent:** Take your time.

**User:** you said that because they're completely separate processes they'll have different caches, but doesn't the cache exist on Anthropic's servers? It doesn't exist in the process locally, right?

**Agent:** That's a fair correction, yes, the actual cached key-value tensors live server-side on Anthropic's infrastructure, not on your local machine or inside the container. The container isolation doesn't create the cache separation by itself.

What actually determines a cache hit is purely whether the request's prompt prefix, hashed, matches a prefix Anthropic has already cached within the TTL window, regardless of which process or container sent it. So if your hundred parallel runs share the exact same system prompt and setup, they could in principle read from the same server-side cache entry, and that's exactly the scenario where `DISABLE_PROMPT_CACHING=1` actually earns its keep rather than being redundant.

**User:** Okay, where were we going?

**Agent:** We were figuring out how to keep your hundred parallel Thunderjar test runs cost-isolated. The upshot is that Docker containers alone don't guarantee that, since the cache lives on Anthropic's side, so setting `DISABLE_PROMPT_CACHING=1` in each container is the actual fix, not just a nice-to-have.

Is there another angle on the telemetry or Thunderjar setup you wanted to dig into, or is that piece settled for you now?

**User:** Right, no, but we don't want to do that, because isn't that going to completely disable caching? Which is not what we want, right? What we want is for no cache to exist when the session starts, but once the session starts, we want to be relying on the caching behavior.

**Agent:** Ah, right, that's a sharper distinction. You want caching active within a run, so multi-turn agentic steps in the same test case still get cheap repeated reads, you just don't want cross-run contamination between the hundred parallel or sequential test cases.

That last search result on `prompt-cache-key` looks like exactly the mechanism you want, let me check it properly.

Here's the good news then. Anthropic actually gives you a header called `prompt-cache-key`, which lets you namespace the cache yourself, so requests only hit each other's cache if they share the same key, completely independent of whether the prefix text matches.

So the fix for Thunderjar is straightforward, generate a unique key per test run, something like a UUID for that run, pass it as the `prompt-cache-key` for every request within that run. That guarantees the hundred parallel runs can never share a cache entry with each other, while inside a single run, caching still works normally across its own turns.
