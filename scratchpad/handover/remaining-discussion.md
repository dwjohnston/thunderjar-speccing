# Thunderjar spec — what's left to discuss

Snapshot as of 2026-10-01, branch `docker-execution-spec` in `thunderjar2/`, last commit
`c6353c9`.

## Context: how we got here

This list came out of working through the user's offline notes
(`spec/__offline_notes.md`, committed in `68bf83b`), written while reviewing the items
flagged in `spec/021-human-zone-out.md`. Those notes raised seven discussion points. A
review of that commit produced this list, in this order:

1. Aggregation result — the missing comparison primitive
2. Measurement identity — name vs hash, and how a changed measurement affects past results
3. Two storage tiers, not three, plus a prompt to stop that kind of contradiction
4. How harnesses and models relate
5. Floating parameters
6. How duration is collected
7. The `declareX()` wrapper convention

The notes also assigned three tasks: move measurements out of 060 into a new 065, write
an example folder structure in 051, and make clear that measurements are tied to tasks
but don't affect the parameter hash.

The session was forked, so some of these were handled in other branches of the
conversation. The current state of the files is taken as the source of truth.

### Settled since the offline notes

- **Items 3, 6, 7** were handled in a fork. 085 now describes two storage tiers with the
  trace store as a future addition. AGENTS.md has a convention against describing a fuller
  design and then walking it back. 085 has an Execution section (the execution wrapper
  writes `/thunderjar/run.json`), and 087 has `apiDurationMs`. 022 documents `declareX()`.
- **051** written (commit `e6e98af`): the configuration layout in a user's project.
  Generated types go in `_generated/` and are git-ignored (convention added to 022).
- **"Task instruction" renamed to "task"** (`e6e98af`). A task is the initial prompt given
  to the harness. Task measurements are *associated with* a task: they live in a
  `measurements/` folder beside it but are excluded from its content hash.
  `declareTask({ prompt })`, and the prompt reaches the harness as `ctx.taskPrompt`.
- **Item 1, aggregation result** (`7676ae5`). The unit of comparison combines every
  iteration of one permutation within one execution. It is stored, and recomputed
  whenever a measure changes. How values combine: **measurement-chosen** — each
  measurement declares `aggregate: ["mean", "max"]` from a menu typed by its instrument's
  value type. Instrument-owned aggregation is a v1 non-goal. Type-inferred and
  inferred-with-override were ruled out.
- **Item 2, measurement identity** (`7676ae5`). The name (filename) is the identity, and
  the content hash is the version. The hash covers instrument, config and bundled files,
  but not `aggregate`. A hash mismatch makes a stored measure stale; backfilling replaces
  it with no history kept. The set hash is derived from sorted `name:hash` pairs. Deleted
  measurements are kept in iteration Results but excluded from aggregation results
  (keep-but-exclude). A rename is treated as a delete plus an add (rename-is-new).
- **Item 4, how harnesses and models relate** (`c6353c9`). The harness declares a
  `models` map (model name → the ID it passes on the command line, as `ctx.modelId`). It
  is the only place that says which models a harness runs. The map is excluded from the
  harness's content hash; the resolved model ID goes into the parameter hash. A model's
  identity is its folder name. `harness` and `model` stay as a cross product in
  `declareExperiment`, and listing a model that one of the harnesses can't run is a type
  error (051, Typed names). Mixed experiments are declared as two experiments. Working
  demo of the types in `scratchpad/harness-model-types/index.ts`. Possible later change:
  move the map to its own file in the harness folder.
- `spec/003-critical-issues.md` added, for design problems that block other work. None
  open.
- AGENTS.md: undecided options are given short names, used in their headings, and never
  referred to by position.

## Needs discussion

1. **Floating parameters.** Mentioned in 085, never defined. The offline notes say this is
   the comparison flow that really matters ("the most recent commit", mostly for code
   state and prompt set, possibly harness and model versions). The tension is that a
   floating value has no fixed content hash, and comparability depends on content hashes.
   Likely answer: it resolves to a pinned value at execution time, and that value's hash
   is recorded. Needs confirming.
2. **Where measurements live in the spec.** The offline task was to move them from 060
   into 065 (065 is now the Model page, so the next free number is 067). Since then the user created an empty `086-collecting-measurements.md`, and
   085 already covers applying measurements. Proposal: 067 for how measurements are
   declared (instruments, `MeasurementContext`, `templateTest`), and 086 for how they are
   collected and stored, taken out of 085. Needs confirming before anything moves.
3. **The `testRunner` setting.** `templateTest` relies on it, but the only place it's
   configured is a comment in 051. Open: where it's configured (050, the global config
   page, is a stub), and how it gets into the measurement container. That second part
   probably joins "Thunderjar's own injected setup" in 020's To revisit.
4. **Reviewing 021.** The user flagged these as not yet reviewed: the `MeasurementContext`
   field list, the `templateTest` config shape, the types in 087 (`TokenCosts`,
   `reason` values, `/thunderjar/result.json`, never-zero-fill), and the remaining record
   shapes in 085 (`RecordedMeasure`, `ContainerRunRecord`, `measuredAt`, storing
   parameters by name and hash). This needs the user's own attention.

## Housekeeping (no decision needed)

- **030 open questions.** Four of its five bullets are now answered (aggregation result,
  measurements, backfill, comparing over time) and can be removed.
- **070** needs to be brought in line with 085 and 087.
- **Verifying the real output format.** From `002_launch-plan.md`: a bash script that runs
  each harness once and captures its output, committed alongside it. Use it to check 087's
  field names (they come from the Agent SDK's documentation, not a captured CLI run) and
  the Codex and OpenCode claims. Those claims come from the source design conversation,
  which also invented a `prompt-cache-key` header that doesn't exist.
- **`002_launch-plan.md`** uses an underscore and sits outside the 010/020 numbering.

## Parked in 020 To revisit

- Where harness images come from (who publishes them, where they're hosted, what happens
  for harnesses Thunderjar doesn't publish)
- Thunderjar's own injected setup in the image (OTel config, test runner)
- Prompt cache isolation between container runs (`prompt-cache-key` doesn't exist;
  options are detect rather than prevent, prefix variation, a pool of workspaces, or a
  5-minute TTL)
- How skipped and errored iterations count toward an aggregation result

## Suggested next

Item 1, floating parameters. It changes what `declareExperiment` looks like, and 051
already shows it.
