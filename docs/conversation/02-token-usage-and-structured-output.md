# Token usage and structured output

_Source: `docs/conversation_json.md` lines 87–139. See [README](README.md) for context._

**Covers:** Per-session vs per-tool/per-sub-agent token attribution; the structured result object (Agent SDK, `claude -p --output-format json`); headless structured output across Codex, OpenCode and Qwen Code.

**User:** Right, okay. Now let's talk about token usage, because that is one of the big important parts. Let's start with Claude. Does its native telemetry tooling include reporting on token usage?

**Agent:** Yes, it does — token usage is actually one of the core metrics Claude Code's native telemetry reports, not an afterthought.

Confirmed, and there's a detail worth flagging. Yes, token input and output totals plus cumulative cost are core built-in metrics, exported per session, per model. But if you're on a Claude subscription rather than pay-as-you-go API billing, that cost figure is API-equivalent pricing, not your actual bill, so it's a relative comparison signal between models rather than a literal dollar amount.

For your comparison-across-models use case with Thunderjar, that's actually fine, since you care about relative token efficiency, not real invoicing. Want me to check whether Codex and Qwen Code report token usage the same granular way, input versus output, per session?

**User:** No, hang on. You mentioned it was per-session token usage, but really what we care about is potentially per-tool-call or per-agent token usage. The two scenarios I'd be interested in: one is where you just have a regular, long-running session with a bunch of different tool calls, and it comes out with whatever total cost in tokens, but you want to know where the lion's share of that token usage came from. The other is a session that spawns sub-agents, and you want to see the cost of the individual sub-agents.

**Agent:** Good, this actually answers both your scenarios pretty well.

For the first one, per-tool-call breakdown within a long session: yes, that's there. Each tool execution is its own span with token and duration data attached, and there's a flag, `OTEL_LOG_TOOL_DETAILS`, that specifically logs which tools are eating the most tokens. So you genuinely can find "the lion's share came from repeated file reads" or whatever it turns out to be.

For sub-agents, it's a bit more nuanced. The trace spans do nest sub-agent chains under their parent, so visually you can see the delegation tree, but there's actually an open feature request on the Claude Code repo asking for cleaner per-subagent token attribution, because right now the raw metrics counter aggregates rather than cleanly splitting by individual agent instance. The more reliable path the docs point to is the Agent SDK's cost-tracking result object, specifically a field called model usage, which gives you whole-tree token accounting including subagents, rather than the plain usage field which under-counts once nesting kicks in.

**User:** No. Sorry, continue.

**Agent:** Go ahead — what did you want to add?

**User:** I interrupted you, continue.

**Agent:** Right, so — worth flagging one more wrinkle before we move on. There's an open GitHub issue about the token usage metric itself being emitted as a plain counter rather than a histogram, which is the shape the OpenTelemetry Gen AI conventions actually expect for per-call distributions. Practically, that means some dashboards built strictly against the standard spec render empty tiles for Claude Code, even though the raw numbers are technically all there in the trace data.

So the honest picture for Thunderjar is: tool-level token breakdown, solid, works today. Sub-agent-level breakdown, the trace hierarchy shows you the shape of delegation, but for precise per-subagent numbers, you're better off reading the SDK's structured result object directly rather than trying to slice the OTel metrics stream. Want me to look at what that result object's shape actually looks like, field by field?

**User:** Yeah, sorry, you're going to need to tell me what is the SDK structured result object?

**Agent:** Right, so — Claude Code isn't just a CLI you type into, it's also available as an Agent S-D-K you can call from your own code, say a Python or TypeScript script. When you invoke it that way, instead of just watching text scroll past in a terminal, you get back a structured result at the end, a proper data object.

That result includes fields like the total cost in dollars, the duration of the API calls, and critically that model usage field, which breaks down token consumption across the whole session including anything sub-agents did. So rather than reading token data indirectly off exported telemetry spans, you'd be running your session through the SDK and reading token and cost numbers straight off that returned object, which is apparently the more accurate source once sub-agents are involved.

**User:** Yeah, okay, that's interesting. So in terms of Thunderjar: initially the approach was going to be running Claude headlessly, so `claude -p` and then your prompt, and then inspecting the file system, and if you're exporting the telemetry, looking at the exported telemetry, et cetera. That was the initial approach. But it sounds like a different approach would be to just run a Node script using the Claude SDK to go execute the things. That sounds like what you're saying — that would be a possibility.

**Agent:** Exactly right, that's a legitimate alternative path. Instead of shelling out to `claude -p` and then reaching for the file system or an exported telemetry stream afterward to reconstruct what happened, you'd write a small Node script against the Claude Agent SDK, kick off the query programmatically, and get cost, duration, and that whole-tree token usage handed straight back to you in the result object, no external collector or file scraping needed.

The trade-off is you'd be giving up the raw trace-level detail, which tool call ate what, exactly when a sub-agent spawned, since that granularity lives in the OTel spans, not the summary result. So it might actually be worth doing both: SDK result object for the headline numbers per run, OTel export if you want to drill into where inside the run the cost came from.

**User:** Yeah — is it possible to get that structured response object if you are calling it via the CLI tool?

**Agent:** Yes, absolutely, and this is good news for your original plan. Add `--output-format json` to your `claude -p` call, and it gives you back that same structured result object at the end, cost, token usage, session ID, all of it, no SDK required.

So you don't have to choose between the two approaches at all. Your original headless CLI plan already gets you the summary numbers for free via that flag, and if you want the deeper tool-by-tool or sub-agent trace detail, you layer OpenTelemetry export on top of that same CLI invocation. Keeps Thunderjar's architecture simpler, just parsing JSON off standard out rather than standing up an SDK integration.

**User:** Yeah, brilliant. Okay, so can you talk about what exists in this space for other harnesses?

**Agent:** So all four give you a headless, scriptable path with structured output, but the shape differs a bit.

Codex is actually the richest event stream of the bunch: `codex exec --json` gives you a JSON-lines feed with every step typed out, thread started, turn started, item completed, and a `turn.completed` event carrying input, output, and even reasoning token counts per turn. Interestingly there's an open GitHub issue on the Codex repo complaining there's no single rolled-up session summary object, so you'd have to aggregate those per-turn events yourself for a total.

OpenCode's `run --format json` gives similar raw event objects including a final step with tokens and cost, but there's a known bug where that final summary event can sometimes just not get emitted, so it's the least reliable of the four for scripted cost extraction right now. And Qwen Code mirrors Claude's pattern closely, `qwen --prompt` with `--output-format json`, giving you a clean single JSON payload, no envelope, straightforward to parse.

So net for Thunderjar, Claude and Qwen give you the cleanest single-shot structured result, Codex gives you the most granular per-turn detail but needs summing, and OpenCode is currently the shakiest to rely on for automated cost pipelines.
