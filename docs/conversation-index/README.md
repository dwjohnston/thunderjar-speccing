# Conversation index

Query-side index over `../conversation/` (16 files, all small — none needs splitting;
largest is `12-terminology-renaming.md` at ~34 KB). This file is maintained by the
`query-conversation` skill's sub-agent. Never edit files under `../conversation/`.

The conversation's *own* README (`../conversation/README.md`) already carries a parts
table, a terminology-drift table and a decisions list — read it first, it is authoritative
for chronology. This index adds: a term→file map, aliases the source README doesn't list,
and a record of which questions have been answered from which files.

## File sizes / split status

| File | Size | Split? |
|---|---|---|
| 01-telemetry-and-otel.md | 13 KB | no |
| 02-token-usage-and-structured-output.md | 8 KB | no |
| 03-token-costs-and-prompt-caching.md | 11 KB | no |
| 04-skills-reasoning-and-turns.md | 22 KB | no |
| 05-investigating-failures-and-preserving-containers.md | 12 KB | no |
| 06-core-model-measurements-and-isolation.md | 10 KB | no |
| 07-storing-and-inspecting-results.md | 7 KB | no |
| 08-testing-thunderjar-cli-modes-and-dev-loops.md | 15 KB | no |
| 09-gaps-existing-config-and-content-hashing.md | 19 KB | no |
| 10-measurers-vs-measurements.md | 14 KB | no |
| 11-pre-spec-and-spec-feedback.md | 10 KB | no |
| 12-terminology-renaming.md | 34 KB | no |
| 13-spec-structure-and-workflows.md | 23 KB | no |
| 14-technical-summary-and-framing.md | 11 KB | no |
| 15-test-boundaries-and-export.md | 10 KB | no |

## Glossary / alias map

Terms as they appear in the conversation, and where they're discussed. The **bold** term is
the final one. Search the earlier aliases too — most of the conversation predates the rename.

| Final term | Earlier names / aliases used in the transcript | Where |
|---|---|---|
| **measuring instrument** | assertion (06–09), assertion pack, measurer (09–12), measurement provider, gauge, meter, probe, analyzer, yardstick, surveyor, caliper, tape measure, assessor, checker, reader, detector (all 12, rejected) | 06:31–39, 09:138, 10:116–128, 12:161–255 |
| **measurement** | measurement (stable throughout); "test", "check", "assertion" used loosely early | 10:84–105, 12:161–169 |
| **measure** (one value) | `MeasurementResult<T>`, "data point", "observation" | 10:96–105 |
| **Result** | "the outcome of a run", "summary", "JSON summary", "JSON report" | 07:15–39, 10:107–109 |
| built-in instruments | `fileCreated`, `file-present`, `grep`, `unitTest`, `importAndRun`, `mcpCalls` (deferred) | 09:91–93, 10:76–82, 10:118, 11:140 |
| `erroredWhileMeasuring` | — (introduced in the pasted terminology.md) | 10:99–105, 11:58–61 |
| `skipped` | — | 10:99–105 |
| **backfill** | "retroactively adding checks", "restore-and-backfill", "apply those new measurements later", "reapply measurements" | 09:166–178, 10:114–122, 10:154 |
| **postrun image** / **prerun image** | "committed container image", "start-of-run snapshot", "end-state snapshot", "preserved container" | 05:29–33, 11:46–56 |
| **container run** | "run", "test run", "iteration", "test case run" | 12 (rename), 10:67–69 |
| **run data store** | "metadata store", "metadata/summary store", "metadata layer" | 07:35–39 |
| **trace store** | "middle tier", "the bit worth adding: a middle tier" | 07:45–47 |
| **image store** | "container artifact store", "container layer", "registry" | 07:41–43 |
| structured result object | "SDK structured result object", "cost-tracking result object", "the JSON result object", `claude -p --output-format json`, `--output-format json` | 02:33–49, 08:37 |
| `modelUsage` | "model usage field" (spoken) vs "the plain usage field" | 02:21, 02:37 |
| token buckets | "input tokens", "output tokens", "cache creation tokens", "cache read tokens", "reasoning token counts" (Codex), "thinking token budget" | 03:37–41, 02:55, 04:69–75 |
| prompt cache isolation | `DISABLE_PROMPT_CACHING`, `prompt-cache-key` (⚠️ see correction below) | 03:47–83 |
| **experiment parameter definition** | "artifact", "jar definition", "run definition" (all 12, rejected) | 12:41–83 |
| test-suite measurement | "unit test measurer", "importAndRun", `testRunner: 'bun test'` (config field) | 09:76 (config), 10:112–122, 10:154 |

## Not present in the conversation (checked, no hits)

- **LLM-judge / LLM-as-a-judge / rubric / grader / semantic scoring measurements.** Grepped
  for `judge`, `rubric`, `grader`, `LLM.?as.?a.?judge`, `semantic`, `eval model`, `second
  model` across all 16 files — zero hits. The conversation never proposes using a model to
  score a run's output.
- Any explicit statement of *where the measuring-instrument process runs* (host vs. inside
  the container) as a decision. Only indirect hints — see topic map below.
- Any dollar-per-token conversion table or pricing config. Cost is only ever discussed as a
  number the harness hands you.

## Topic map

### Measurements — how they're applied
- `06-core-model-measurements-and-isolation.md:29–39` — first statement: "standard" tier
  (final text block, commit list, files changed) vs "arbitrary" tier ("exec into the
  committed container image and run whatever script the test case author wrote"); pluggable
  assertion packs.
- `09-gaps...:166–178` — backfill. The canonical passage. Restore the preserved container,
  run new instruments against the already-existing final state, append to the same run's
  record. Plus the "iterating on measurers without re-running the agent" DX loop.
- `10-measurers-vs-measurements.md:71–109` — the pasted terminology.md: `registerMeasurer`
  signature, config type + value type generics, `MeasurementResult<T>` with
  `measured`/`skipped`/`erroredWhileMeasuring`.
- `10:112–142` — type vs instance; glob+pattern are config, not baked in; broad globs
  recommended over exact filenames.
- `10:144–163` — risks: shared named measurements rejected (many-to-many coupling);
  container-as-sufficient-proxy risk for runtime-dependent instruments.
- `11-pre-spec-and-spec-feedback.md:46–61` — base-image drift answered by preserving the
  start-of-run container too; all infra errors folded into `erroredWhileMeasuring`.
- `12-terminology-renaming.md:161–255` — measurements are observations, not verdicts; the
  measurer → measuring instrument rename; single-purpose constraint.
- `15-test-boundaries-and-export.md:20–21, 32, 58` — pipeline order "container run, then
  measuring instruments, then the metadata report"; instruments as "pure functions over
  fixture directories"; `docker run --rm <image> …` vs exporting the filesystem.

### Token costs and timing
- `01-telemetry-and-otel.md:17, 43, 83` — token cost named as a core goal; native OTel
  tracing gives nested interaction/tool/LLM-request spans with token usage.
- `02-token-usage-and-structured-output.md` (whole file) — the decision file. Per-session
  vs per-tool vs per-sub-agent; `OTEL_LOG_TOOL_DETAILS`; sub-agent under-counting in the
  plain `usage` field vs whole-tree `modelUsage`; `--output-format json` gets you the same
  result object from the CLI; per-harness comparison (Codex / OpenCode / Qwen).
- `03-token-costs-and-prompt-caching.md:37–41` — the four token buckets and their relative
  prices; `:47–83` — cache isolation via `prompt-cache-key` (⚠️ **this API does not
  exist** — see Corrections below).
- `04-skills-reasoning-and-turns.md:95–105` — parent span carries total tokens + total
  wall-clock; per-span model attribution for delegated sub-agents; explicit "summary object
  gives totals, only per-span trace gives per-model breakdown".
- `05-investigating-failures...:7–17` — OTel for spotting that cost spiked, JSONL transcript
  for reading why.
- `07-storing-and-inspecting-results.md:15, 39` — what lands in the metadata store:
  "pass/fail, cost, tokens, duration, per-model breakdown", keyed by iteration ID.
- `08-testing-thunderjar...:27, 37` — `docker wait` resolution triggers commit + "extract
  the JSON result and trace" + push; fake harness emits the same result-object shape.
- `13-spec-structure-and-workflows.md:45–53` — token cost as the driver for keeping each
  execution's resolved specifics as a dated record.

## Answered questions log

| Date | Question | Files read |
|---|---|---|
| 2026-09-29 | How/when measuring instruments are applied to a container run (inside vs outside, before vs after commit, instrument shape, backfill, built-ins, LLM-judge, skipped/errored outcomes) | 06, 09, 10, 11, 12, 15 |
| 2026-09-29 | How token counts/cost are collected for a container run (OTel vs `--output-format json` vs transcript; which fields; sub-agents; dollars; per-harness; duration) | 01, 02, 03, 04, 05, 07, 08, 13 |

## Notes for future queries

- The conversation's `spec/` references point at `/Users/davidjohnston/claude-workspace/thunderjar2/spec/`
  (repo root, **not** `docs/spec/`). `085-experiment-results.md` lives there.
- `docs/conversation_json.md` is the unsplit source; each part file names its source line
  range in its header. Prefer the split files.
- Line numbers cited in this index are 1-indexed lines of the split part files as of
  2026-09-29.

## Corrections — claims in the conversation that are factually wrong

The conversation is a design discussion, and its agent side sometimes states APIs with
full confidence that do not exist. Verify before repeating a technical claim from it.

- **`prompt-cache-key` (03:81–83) is not a real header.** There is no cache-key,
  cache-namespace or cache-partition parameter in the Claude API. Prompt caching isolates
  per workspace (per organization on Bedrock and Vertex) and nothing finer; the documented
  workarounds are separate workspaces or varying the prompt prefix. Any answer citing
  03:81–83 must carry this correction. The surrounding points do hold: the cache lives
  server-side so container isolation doesn't help (03:65), and cache-read tokens reveal
  contamination (03:37–41). Resolved in
  `spec/020-goals-non-goals.md` under "To revisit".
- **Treat the per-harness claims at 02:53–59 as unverified** — that Codex emits no
  rolled-up summary, and that OpenCode sometimes omits its final event. Same source, same
  confident register, not independently checked.
