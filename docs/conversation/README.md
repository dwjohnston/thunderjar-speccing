# Design conversation, split by topic

The source design conversation for Thunderjar ([`../conversation_json.md`](../conversation_json.md)),
split into chronological parts so you can read only the parts you need. Most of it was a
hands-free voice conversation, so user turns were originally transcribed speech.

## How to read these files

- **It's chronological, and ideas change as it goes.** Later parts often override earlier ones
  (see [Terminology drift](#terminology-drift) and [Decisions](#decisions)). The spec in
  [`../../spec/`](../../spec/README.md) is the current thinking. This conversation is background.
- **Agent turns are verbatim.** Some were cut off mid-sentence in the original, and they stay cut off.
- **User turns are lightly cleaned up.** Filler (um, uh, "you know"), false starts and
  repeated words are removed, and obvious speech-to-text errors are fixed
  ("snark" → snerk, "hotel hooks" → OTel hooks). Typed messages only have typos fixed.
  Nothing is meant to change the meaning.
- `[?]` or `[audio garbled]` marks a transcription the editor couldn't confidently repair.
- `_[Editor: …]_` marks an editorial note. Two things were left out. One is an unrelated
  interruption in part 07. The other is repeated tool boilerplate that wrapped the
  artifact comments in part 11.
- Each file starts with its source line range, in case you need to check the original.

## Parts

| # | File | Source lines | Covers |
|---|---|---|---|
| 01 | [Telemetry and OpenTelemetry](01-telemetry-and-otel.md) | 1–85 | OTel hooks package vs Claude Code's native OTel, traces and spans, native telemetry across harnesses |
| 02 | [Token usage and structured output](02-token-usage-and-structured-output.md) | 87–139 | Per-tool and per-sub-agent tokens, the structured result object (`--output-format json`), headless output in other harnesses |
| 03 | [Token costs and prompt caching](03-token-costs-and-prompt-caching.md) | 141–217 | Prefill vs decode pricing, cache tiers, cache isolation between parallel runs |
| 04 | [Skills, reasoning and turns](04-skills-reasoning-and-turns.md) | 219–317 | Skill invocation telemetry, how skills work, thinking/tool-use/text blocks, turns vs thinking budget, span shape, sub-agent model attribution |
| 05 | [Investigating failures and preserving containers](05-investigating-failures-and-preserving-containers.md) | 319–357 | Thinking blocks missing from OTel, JSONL transcripts, `docker commit`, registry costs, container forensics |
| 06 | [Core model, measurements and isolation](06-core-model-measurements-and-isolation.md) | 359–407 | First statement of the parameter matrix, standard vs arbitrary measurements, credentials, fake MCP |
| 07 | [Storing and inspecting results](07-storing-and-inspecting-results.md) | 409–486 | Metadata store, container registry, trace middle tier, telemetry view vs full restore |
| 08 | [Testing Thunderjar, CLI modes and dev loops](08-testing-thunderjar-cli-modes-and-dev-loops.md) | 488–580 | First pass at testing the tool, `docker wait`, fake harness, scriptable vs interactive CLI, dev loops, local vs CI provenance |
| 09 | [Gaps, existing config and content hashing](09-gaps-existing-config-and-content-hashing.md) | 582–753 | Gaps, the existing repo's config (pasted), name + hash identity, backfilling measurements |
| 10 | [Measurers vs measurements](10-measurers-vs-measurements.md) | 755–912 | The user's earlier terminology.md (pasted), type vs instance, globs, no shared measurements, risks |
| 11 | [Pre-spec and spec feedback](11-pre-spec-and-spec-feedback.md) | 914–1157 | Quick-fire decisions, the user's comments on the spec artifact |
| 12 | [Terminology renaming](12-terminology-renaming.md) | 1159–1407 | Conversation fork: experiment definition/execution, experiment parameter definitions, permutation, container run, measuring instrument |
| 13 | [Spec structure and workflows](13-spec-structure-and-workflows.md) | 1409–1610 | Local and CI workflows, pinned vs floating experiments, the spec file list |
| 14 | [Technical summary and framing](14-technical-summary-and-framing.md) | 1612–1745 | A condensed technical summary, and a prompt for a new agentic-coding session |
| 15 | [Test boundaries and export](15-test-boundaries-and-export.md) | 1747–1848 | Testing layers for Thunderjar (became `spec/12-test-boundaries.md`), exporting the conversation |

**Quick routing**

- Telemetry, tokens or caching: 01–04.
- Run preservation, storage and restore: 05, 07.
- Configuration, identity and hashing: 06, 09, 11, 12.
- Terminology: 10, 12. The current glossary is `spec/03-terminology.md`.
- UX and workflows: 08, 13.
- Testing Thunderjar itself: 08 (early), 15 (final).

## Terminology drift

The conversation uses several terms that were renamed later. These are the renames made
within the conversation. Check `spec/03-terminology.md` for the current terms.

| Earlier term (part) | Later term (part) |
|---|---|
| test case (06–09) | experiment. Written down, it's an **experiment definition**; one occasion of running it is an **experiment execution** (12) |
| axes / variables / run parameters, "artifact", "jar definition" (06, 09, 12) | **experiment parameters**, defined as hashed **experiment parameter definitions** (12) |
| code commit / prompt commit (06) | **code state** and **prompt set** parameters (09, 12) |
| run: one permutation (10) | **permutation** is the combination, **container run** is its execution (12) |
| assertion (06–09), measurer (09–12) | **measuring instrument** (12). **Measurement** is kept |

## Decisions

These are the notable decisions and where they were made. Later rows can override earlier ones.

- **Summary numbers** come from `claude -p --output-format json`. OTel is layered on for drill-down (02).
- **Cache isolation**: use a unique `prompt-cache-key` per run rather than disabling
  caching. That keeps caching working within a run (03). A separate spec page for this was
  later dropped from the file list (13).
- **Reasoning content** isn't exported by OTel. Use the on-disk JSONL transcripts, joined by session ID (05).
- **Preserve runs** with `docker commit`, push to a registry, and set a retention policy
  (05, 07). A start-of-run image or base image also becomes part of a run's identity (11).
- **Model parameter** pins only the root model. Delegated sub-agent models are observed outcomes (06).
- **No real credentials.** Runs are ephemeral (06). Faking MCP servers was proposed (06)
  and then made **out of scope** (11).
- **Storage** is a metadata store plus a container registry, with traces and transcripts
  kept alongside the metadata (07).
- **Fake harness** is just another harness config (08).
- **CLI** has a scriptable mode for CI and an interactive mode for local work (08).
  Iteration count defaults low (08).
- **Local vs CI** runs are handled by per-environment config files
  (`thunderjar.local.ts` / `thunderjar.ci.ts`), not hard-coded rules (08, then 11).
- **Deferred for the PoC**: cost/rate-limit guardrails and infra-flakiness retries (09).
  All errors are treated as a special ignored case for now (11).
- **Identity is name + content hash.** Parameters are folders whose content is hashed. This
  replaced the "never edit, create a v2" idea (09). Hash mismatches warn but still record
  the run (11). Definitions must be deterministic, and non-determinism is user error (09).
- **Harnesses** are hashed definition folders like prompt sets, with the harness version
  pinned per definition (11, 12).
- **New measurements** can be backfilled onto restored containers without rerunning the
  agent. Existing measurements can't change (09).
- **Measurements are copy-pasted per task**, not shared by reference (10).
  Broad globs are recommended over exact filenames (10).
- **`commitHash: 'HEAD'`** is for debugging only. Models an experiment references but its
  harness doesn't declare are a build-time validation error (11).
- **Measurements are observations, not pass/fail verdicts** (12).
- **Pinned experiments only** in the first pass. Floating experiments are deferred.
  Both kinds run on a weekly-ish cadence, never per commit (13).
- **Stack**: Bun, TypeScript (version 7), and linting to enforce file structure (11, 13).
