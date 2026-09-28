# Core model, measurements and isolation

_Source: `docs/conversation_json.md` lines 359–407. See [README](README.md) for context._

**Covers:** First statement of the Thunderjar model: code commit, prompt commit, model, harness version and task as parameters; root model vs delegated models; overlaying prompts; standard vs arbitrary measurements; pluggable assertion packs; no real credentials; fake MCP via dependency injection.

**User:** All right, look, let me explain how I've currently been conceptualizing Thunderjar. Essentially, the parameters are the commit of the code base and the commit of the prompts — and I can talk about that a bit more later. You've got the model, and you've got the harness version

**Agent:** Got it, that's a clean four-axis test matrix, code base commit, prompt commit, model, and harness version, go on.

**User:** And then you've got the, right? Right.

**User:** And then you've got the original prompt as well — the task. Now, the concept here is that it's always some kind of one-shot task. At higher levels of sophistication, a one-shot task might actually be quite involved — multiple agents, long-running type thing. But at least in my initial use case, we're really thinking about very quick tasks that complete in a minute or two. Right?

**Agent:** That makes sense as a starting scope, keeps the whole harness simpler while you validate the approach, before you have to deal with long-running multi-agent orchestration complicating your telemetry and container-snapshot strategy.

So with those five axes, code commit, prompt commit, model, harness version, and the task itself, each individual test run is really just one point in that matrix, run once, and the run count you mentioned earlier, the hundred parallel runs, that's presumably repeating the exact same point in the matrix multiple times to get your pass rate statistics, since the whole thing's probabilistic.

**User:** Yeah, exactly. All right. Oh, where was I going? Okay, just a couple of nuances. I mentioned the model. The idea is that if you do `claude -p`, you can choose a model to do the task. That's fine. But the thing to consider is that if your prompts include things like "delegate this to this specific model", it complicates things a little bit, because you're actually going to be running with models that aren't the model you said it was. So that's one thing to mention. But I think that's probably doable, because when you select a model with `claude -p`, you're really just specifying the root model. You're not really saying anything about the other models. I think that's fine.

**User:** So let me just tell you how I'm thinking about the code base commit and the prompt commit. Of course, the prompts are in the code base. So the way I'm thinking about this is, when you're creating your Docker container, it's a kind of `git checkout` the code commit, and then `git checkout` the prompt commit for `*.md`, type thing, to apply just the prompts. It's obviously a bit more complicated than that, but that's how I'm thinking about this thing working.

**Agent:** That's a clean way to decouple them, checking out the code at one commit and then overlaying just the prompt files from a separate commit lets you isolate whether a regression came from a code change or a prompt change without conflating the two, which is really the whole point of having them as separate axes in the first place.

And your point about the root model versus delegated models is a good one to flag clearly in your matrix design, since it means model as a parameter is really only pinning the entry point, the actual model mix for a given run is an outcome you observe and record via telemetry, not something you fully control upfront, which loops right back to why per-span model attribution in the trace matters so much for Thunderjar specifically.

**User:** Now, what else was there? Essentially, the way I'm thinking about this is that in your project you'll have something like a `.thunderjar` folder, and this contains all of what we'll call test cases.

**User:** Right. So a test case is selecting this specific kernel [commit?], this specific harness, etc. And then when you go and run that, it creates a Docker container with the code at that point and then executes it. And then — something I didn't talk about — is the measurements. You run your `claude -p` and eventually it exits. The way I'm thinking about this is that there are some standard outputs, standard results that you would test on: the text block that it comes back with, which you want to assert on; the list of commits — you want to check whether that list of commits exists, whether it committed at all, and you want to be checking the commit messages, or possibly exact hashes are something you care about; and then you've got the files changed, possibly as a delta. But of course you could always write any arbitrary test. For example, you might be specifying that there is a database in this Docker container, because the task involves updating a database. Then you would just be running arbitrary commands against that database to check whether it's in the right state or not.

**Agent:** That all hangs together well, and it sounds like your assertions naturally split into two tiers. The standard ones you get for free just by the nature of how every test case runs, final text block, commit list with messages and hashes, whether it committed at all, changed files as a diff, those you could build one shared assertion library for since every test case produces them the same way regardless of task.

And then the arbitrary tier is genuinely open ended, run any command against the container's final state, query a database, check a file's exact contents, run the actual test suite the coding agent was supposed to satisfy, and that's really just exec into the committed container image and run whatever script the test case author wrote. Sounds like the standard tier is your fast, cheap, always on path, and the arbitrary tier is where the real per test case authoring effort goes.

**User:** Yes, that's a fair assessment. Now, something I'm thinking about is that you possibly have a pluggable architecture in terms of those standard tests. For example, in my project I might not have a database, I don't really care about database operations. But for someone else, a lot of their tests are going to be these database assertions, in which case, when they're configuring this thing, they want a first-class, easy-to-use assertions tool for databases. That's just an aside, by the way.

**Agent:** Makes sense, treat it like a plugin ecosystem, ship a small core of universal assertions, commits, files changed, final text, and let domain-specific assertion packs, database state, HTTP endpoint checks, whatever, be opt-in modules people add depending on what their test cases actually touch.

That also keeps your core lean for people like you who don't need database assertions at all, while still letting Thunderjar grow into other people's use cases without bloating the base tool, feels like the right shape for something you'd eventually want other people contributing test-case types to.

**User:** Right, okay. Now, I want to circle back to this — can you please remind me? One of the questions is around controlling access to actual sensitive stuff. For example, whether you would want to have real API keys — maybe give it a GitHub key so it can actually create a pull request? I'm actually questioning whether that's needed, because the idea of this being a test thing is that anything it does should be ephemeral. Your test scenario shouldn't actually be affecting anything in the real world.

**Agent:** That's the right instinct, and it follows directly from your own ephemeral-container design, if the whole point is that everything lives and dies inside that one Docker container's filesystem, then a real GitHub key that can push or open a PR against an actual remote repo is reaching outside that boundary into the real world, which breaks the ephemeral property you're relying on for safe, repeatable, parallel testing.

The cleaner pattern would be a local git remote, or no remote at all, so commit and push behavior gets exercised and asserted on entirely inside the container, and if a specific test case genuinely needs to validate real GitHub API interaction, that's a case for a sandboxed or mocked GitHub API rather than live credentials, keeps your hundred parallel runs from ever risking a real side effect, and keeps you from having to reason about secret rotation or scoped tokens for something that's fundamentally meant to be disposable.

**User:** Right.

**Agent:** Sounds like that settles that piece, then. Anything else on your mind for Thunderjar, or is that a good place to pause?

**User:** No, no. Okay. So there is a real question here. In my case, creating pull requests or whatever isn't really important. But what if that is the agentic flow someone is trying to test? How would you actually do that? It does sound like maybe this ends up being basically dependency injection for agentic workflows. Maybe we haven't really talked about MCP, but maybe you go, all right, if you're going to be creating pull requests, use this GitHub MCP, and then in our Thunderjar Docker container we give it a fake MCP. Maybe that's the way we would be doing this.

**Agent:** That's exactly the right shape for it, and dependency injection is a good name for the pattern too. The test case doesn't hard-code a real GitHub MCP server, it specifies an interface, a GitHub-shaped MCP, and Thunderjar's container setup swaps in whichever implementation matches the run, a real one for actual production validation, a fake or mock one that just records what calls were made and returns canned responses for routine automated testing.

That actually solves two problems at once, it keeps your hundred parallel runs safe and side-effect-free like we just discussed, and it gives you a clean new assertion surface, since the fake MCP can log every call it received, so you're no longer just checking file state or commits, you can assert did it call create-pull-request with these exact arguments, which is arguably a much more direct signal for that specific agentic flow than inferring intent from git history alone.
