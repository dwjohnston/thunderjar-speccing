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
| **test boundaries** (spec file `test-boundaries.md`, now `spec/120-test-boundaries.md`) | "testing strategy", `testing-strategy.md` (13:142, 13:177; renamed by David at 15:64), "testing boundaries" (David, 08:41), "testing this application" (08:7) | 08, 13:142–177, 15:7–93 |
| **recording adapter** | "dry-run adapter" (15:11), "print the Docker commands" / "assert on standard out" (David, 15:7), "a fake ... container that echoes a canned result object" (agent, 08:15), "dependency-inject anything non-deterministic" | 08:15, 15:7–17 |
| **fake harness** | "fake agent that is just a script" (David, 08:29), `node fake-agent.js` (08:37), "fake path" (08:49) | 08:29–39, 15:7, 15:19–23 |
| **artifact assertions** | "Layer 2.5", "image as the unit under test", "assertion-on-Docker-metadata layer" (08:51), "assertions on the docker image" (David, 15:41) | 08:45–51, 15:39–62 |
| **lifecycle tests** | "restore and purge", "prune" (08:47–53; later "purge"), "Layer 3" (15:25) | 08:47–53, 15:7, 15:25–28 |
| **real-harness smoke test** | "one gap remains" (15:34–35) | 15:34–35, 15:74 |
| layer numbering | 15:11–28 numbers CLI=1, Docker+fake harness=2, lifecycle=3, artifact=2.5, units unnumbered; 15:68–72 renumbers to 1 units, 2 CLI, 3 Docker, 4 artifact, 5 lifecycle (and still says "four layers" at 15:66 while listing five) | 15 |

## Not present in the conversation (checked, no hits)

- **"Correctness test" as a term.** Grepped `correctness` across all parts — zero hits. The
  conversation speaks only of measurements / measuring instruments / "unit test measurer".
- For Thunderjar's own tests: no test runner or directory layout, no coverage targets, no
  statement of which layers block CI (only that the smoke test is non-blocking and the
  Docker layer is "tagged" out of the fast loop), no fixture-image storage decision, no
  explicit "test via public interface, not internals" statement, no tests for backfill,
  OTel/trace extraction, or hash-mismatch warnings.
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

### Testing Thunderjar itself (test boundaries)
- `13-spec-structure-and-workflows.md:142, 177` — agent proposes a "testing strategy for
  Thunderjar itself" page, "separate from how the tool tests prompts"; David accepts
  ("Everything else yes", 13:160).
- `08-testing-thunderjar...:7–19` — first pass. Agent's three-way split: pure-ish unit
  tests / DI'd orchestration with a fake runtime / a handful of real-Docker integration tests.
- `08:29–39` — David's fake harness idea ("one of the harnesses be a fake harness"); agent:
  same harness-config mechanism, edge-case fake scripts (never commits, malformed JSON, timeout).
- `08:41–53` — David names "testing boundaries"; run, then search images, check tags,
  inspect image, assert on deterministic file changes; prune scenario; registry upload
  ("doesn't worry me too much").
- `08:59–71` — David wants the real CLI experience during development; rejects the idea that
  the interactive/TUI mode needs its own testing strategy ("testable both ways" with sensible DI).
- `15:7` — David's canonical statement: DI anything non-deterministic incl. Docker, print
  Docker commands, assert on stdout; real Docker + fake harness up to the metadata report;
  restore from an existing image and expect branches/files.
- `15:9–35` — agent's breakdown (recording adapters, same interface not a `--dry-run` path,
  normalise volatile output, view-model split, contract check on the fake harness, purge
  idempotency, throwaway local registry, golden-value hashing, non-blocking smoke test).
- `15:39–62` — David adds the artifact layer; agent expands (tag, git state, files, labels,
  base digest; inspection helper; `docker run --rm` vs export).
- `15:64–93` — David names the file `test-boundaries.md`; agent's final five-item list.
- Related, about testing *prompts* not Thunderjar: 09:174–178 (instrument authoring as TDD
  against a restored fixture), 12:161–167 (measurements are not pass/fail), 06:51–55 (fake
  MCP as DI for the workflow under test; out of scope per 11), 09:11–19 + 11:58–61 (infra
  flakiness vs measurement failure deferred, folded into `erroredWhileMeasuring`).

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
| 2026-10-01 | David's ideas on test boundaries for Thunderjar itself (layers, mock/real boundary, fake harness, artifact assertions, lifecycle, smoke test, open questions) | 08, 15, plus targeted lines of 06, 09, 10, 11, 12, 13 |

## Notes for future queries

- The conversation's `spec/` references point at `/Users/davidjohnston/claude-workspace/thunderjar2/spec/`
  (repo root, **not** `docs/spec/`). `085-experiment-results.md` lives there.
- `docs/conversation_json.md` is the unsplit source; each part file names its source line
  range in its header. Prefer the split files.
- Line numbers cited in this index are 1-indexed lines of the split part files as of
  2026-09-29 (re-checked 2026-10-01).
- Part 08 is voice-transcribed with garbled audio and cut-off agent turns (08:41–61); the
  prune test description is truncated mid-sentence at 08:53. `../conversation/README.md`
  refers to the spec file as `spec/12-test-boundaries.md`; it is now `spec/120-test-boundaries.md`.

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
