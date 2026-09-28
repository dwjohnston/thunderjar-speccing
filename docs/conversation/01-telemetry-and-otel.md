# Telemetry and OpenTelemetry for coding agents

_Source: `docs/conversation_json.md` lines 1–85. See [README](README.md) for context._

**Covers:** OpenTelemetry hooks package vs Claude Code's native OTel support; traces/spans; which harnesses (Claude Code, Codex, Qwen Code, OpenCode) have native telemetry. Includes an aside on Claude chat capabilities and product feedback about background tasks in voice mode.

# Telemetry for coding agents

**User:** I have you in voice chat mode, so you're not really going to be able to show me code blocks. What we're doing is talking about telemetry as it relates to coding agents, and generally being able to

**User:** observe what their coding agent has done. That's for the purpose of optimizing the agent, or comparing the performance of different models, that kind of thing. Specifically, things we're interested in are examining where the sub-agents respond, and examining whether certain skills were invoked.

**Agent:** Right, telemetry for coding agents — that's a great area, especially with your Thunderjar work in mind. So you're essentially wanting observability hooks around agent execution: which sub-agents got spun up and what they returned, and which skills or tools actually got invoked during a run, so you can compare that across models.

Is the goal here something you'd bolt onto Thunderjar itself, or is this a separate tracing layer you're thinking about?

**User:** And then potentially... So this is a Thunderjar thing ultimately, but what we're talking about is probably using existing tools to do this. Is introspection the right word? Now, where did I get to? Whether certain skills were invoked. Another thing we're really interested in is token cost. I was having a play with the OpenTelemetry hooks package, so here's your first task: take a look at the OpenTelemetry hooks. You can take your time, put yourself into extra thinking mode. How does that thing actually work? From what I'm seeing, it just adds boilerplate to the harness's hooks configuration, and that's just going to make calls to the OTel hooks package for each of those hooks. It doesn't sound like it's doing anything particularly smart — you could just be doing a little curl command there instead. So can you take a look at that please?

**Agent:** Let me look into that properly — the OpenTelemetry hooks package for coding agent harnesses.

Right, found it. It's the `o11y-dev/opentelemetry-hooks` package, and your instinct is basically correct.

Here's how it actually works: it installs a CLI called `otel-hook`, which registers itself into your agent's hook configuration — so for Claude Code, that's your settings file's PreToolUse, PostToolUse, and so on. Each hook event comes in over standard in as JSON, gets picked up by this Python process, gets reshaped into an OpenTelemetry span or event, and shipped out over O-T-L-P to whatever backend you're using, then it writes back a small JSON blob to standard out saying "continue: true" so the harness knows to carry on. So yes, structurally it is exactly what you guessed: boilerplate glue that turns each hook invocation into an outbound telemetry call. There's no cleverness in the middle, no sampling logic, no local aggregation. You could absolutely replace it with a lightweight script doing the same job, including a raw curl call to an O-T-L-P endpoint, if you wanted to skip the dependency.

The one thing it does buy you is the multi-agent abstraction — one binary that knows the slightly different hook payload shapes across Cursor, Claude Code, Gemini, Copilot, and so on, and normalizes them into consistent span attributes. Do you want me to dig into what those normalized attributes actually look like, in case that's the part worth stealing for Thunderjar?

**User:** No, let's just talk about this. So if I start a session — in my command line I write `claude`, right, that starts a new session — and I go, yeah, create X file, right? That is going to do whatever, the session start hook. And then there's going to be pre-tool use and post-tool use hooks, etc. There are some questions here about how telemetry works. Because ultimately all of those should get associated with the same... what do you call a collection of spans relating to an operation? What I'm thinking about is when I'm using App Insights at work for regular applications, I search a trace ID and that gives you this full tree of spans tracking everything that happened in that operation. What do you call that collection of spans?

**Agent:** That collection is called a trace — same concept as App Insights, just OpenTelemetry's vocabulary for it. The trace is the whole tree, identified by a trace ID, and each individual timed thing inside it, your session start, each tool call, is a span, all sharing that same trace ID as their common root.

And yes, that's exactly how the Claude Code docs describe it — a `claude_code.interaction` span acts as the parent, and the hook spans, tool spans, and LLM request spans all nest underneath it, carrying a shared session ID so they collapse into one timeline in your backend.

**User:** Yes, okay, so does that mean that the payload that comes out of the hook — what do you call it, a hook invocation, the thing that's coming from the coding harness itself — includes the session ID? And that is how, when it gets put into your telemetry collector, it knows the trace ID to be able to correlate them?

**Agent:** Exactly right. Each hook invocation's JSON payload includes a session ID, and the hook script reads that off standard in, then either uses it directly as the trace ID or maps it into the correct trace context before shipping the span out.

Worth noting there are actually two slightly different mechanisms layered here. Claude Code's native OpenTelemetry export propagates proper W3C trace context, TRACEPARENT and TRACESTATE, so spans nest correctly without any extra work. But a hook script like the one we just looked at is a separate process spawned per event, so it has to reconstruct that correlation itself, typically by using the session ID as a consistent trace or resource attribute so your backend groups everything under one banner even though each hook call is technically a fresh, disconnected process.

**User:** Yeah, hang on, let's dig into that. Were you saying that Claude Code has its own sort of telemetry concept? And is that something I can use?

**Agent:** Yes — Claude Code ships with its own built-in OpenTelemetry support, no separate hooks package required. You set a couple of environment variables, `CLAUDE_CODE_ENABLE_TELEMETRY` and `OTEL_EXPORTER_OTLP_ENDPOINT`, point it at wherever you're collecting, and it starts streaming metrics and events natively.

The tracing side is newer and still in beta, but it already gives you that nested structure you were asking about: an interaction span as the root, with tool spans, hook spans, and LLM request spans as children, and when a sub-agent gets spawned via the agent tool, its spans nest under the parent's tool span too. So sub-agent visibility, hook timing, token usage, that's all there out of the box, which honestly might make that separate hooks package redundant for your use case, since Claude Code is already an OpenTelemetry client itself.

**User:** Yes. Okay. So, hey, do you have the ability to spawn sub-agents or to spawn other sessions?

**Agent:** Ah, good question. No, not in this conversation — I'm just the one Claude instance talking to you here in voice mode, I don't have a tool to spin up sub-agents or separate sessions myself.

That's really a Claude Code thing — when you're in the CLI and it dispatches work to the agent tool, that's Claude Code's own orchestration spinning up a sub-agent within its session. I don't have access to that machinery from here.

**User:** What about things like... I can see that Claude Cowork is a thing. You've also got that concept where the Claude web interface can access your desktop computer?

**Agent:** Right, those are two different things worth separating. "Claude Cowork" — let me actually check what that refers to, I don't want to guess.

Interesting timing actually — Cowork just got folded back into regular Claude chat as of a few weeks ago, mid-September. It used to run as a separate isolated environment where Claude could read and edit files and produce real documents autonomously in the background, and that's now merged into the main app so you don't pick between "chat" and "cowork" anymore.

That's distinct from Computer Use, which is the older, lower-level toolset, screenshot, click, type, where Claude directly drives your actual desktop, clicking around apps and browsers on your behalf. Cowork's more about autonomous file and task work in a sandboxed environment, Computer Use is literally taking the wheel on your screen.

**User:** Do you have... I mean, you have skills available to you, right?

**Agent:** I don't have "skills" in that formal sense, no — that's really a Claude Code and Cowork concept, packaged bits of instructions or scripts the agent can invoke for specific tasks. I'm this voice conversation instance with a fixed toolset: web search, memory, code execution, a few connectors like Gmail and Drive and Todoist. No pluggable skills system sitting underneath me.

**User:** Why, is that because you're in the voice chat situation? Because if I go — hang on, let me just open my Claude. I click Claude.ai and I go new session. And yeah, I can't see. This seems like it's Claude chat. But what I'm talking about is that in the past I've asked Claude to create me an Excel spreadsheet, and I can see it going off and invoking a skill that uses some Python package to create the spreadsheet. Also, it does seem like that Claude chat session has a whole bunch of pluggable skills.

**Agent:** Ah, right, yes — that's a real distinction. Regular claude dot ai chat does have that built-in skills system, things like the spreadsheet-creation skill that shells out to a Python package under the hood, document generation, and so on, all pluggable and automatically invoked when relevant.

Whether that's absent for me specifically because I'm voice mode, or just because this particular conversation surface wasn't configured with those skills loaded in, I honestly can't say for certain from in here — but functionally, yes, right now I don't have access to that skills layer, only the fixed tool list I mentioned.

**User:** Yeah, right. Anyway, if you did have the ability — it would be good feedback to give to Anthropic, which is that when we're in this chat mode, it can be good to say, "Hey, by the way, can you go and investigate this thing? It might take you ten or fifteen minutes. I don't want it to distract from the conversation." And so the idea is you'd spawn something up to be running in the background, without me, because I'm hands-free right now. Right?

**Agent:** That's a genuinely good piece of product feedback — hands-free voice is exactly the context where a long background investigation makes sense, since you can't exactly sit and stare at a progress bar while driving or cooking. The pattern you're describing, "kick this off, keep talking to me about other things, ping me when it's done" is basically async task delegation within a live voice session.

I don't have a channel to actually submit that feedback to Anthropic from here, but it's worth you flagging directly through the app's feedback option if you want it to land. Want me to note it in memory against your agent tooling interests, in case it's useful context later?

**User:** Okay, fair point. Yes, sure.

**Agent:** Done, noted. Anything else on the telemetry side, or shall we leave it there for now?

**User:** Yeah, okay. So, sorry, remind me where we got up to with the telemetry conversation.

**Agent:** Right, so we landed on: Claude Code already ships its own native OpenTelemetry support, no separate hooks package needed, you just set the telemetry enable flag and point it at an O-T-L-P endpoint. It gives you that nested trace structure natively, an interaction span as the root with tool calls, hooks, and sub-agent delegation all nesting underneath, correlated by session ID.

That third-party `opentelemetry-hooks` package we looked at first is really only useful if you need one consistent setup across multiple different agents, Cursor, Copilot, Gemini, and so on, not just Claude Code. Given you're focused on Thunderjar and Claude Code specifically, want to dig into what the native telemetry actually gives you for token cost and skill invocation tracking, since that was the other thing you flagged as important?

**User:** First, can you give me a comparison of other coding harnesses — specifically OpenCode, whichever other Chinese harnesses there are, Codex, Claude, I think that's it — and whether they have native telemetry?

**Agent:** Let me check on that across the board.

Good news across the board actually. Claude Code, Codex, and Qwen Code — which is Alibaba's harness, the closest thing to a mainstream Chinese entrant — all have native, built-in OpenTelemetry support, no third-party glue required, you just configure environment variables or a settings file and point it at an endpoint.

OpenCode is the odd one out. It's had off-and-on native support attempts, but there are open issues and reports of it being flaky or undocumented in practice, so people generally reach for a community plugin instead to get reliable OTLP export out of it. So if you're comparing model performance across harnesses for Thunderjar, three of your four give you clean native telemetry, and OpenCode is the one where you'd need a workaround.
