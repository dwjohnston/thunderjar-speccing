# What are the main parts missing from the Thunderjar spec?

## Context
Full read of `spec/` on 2026-10-10 (branch `codex/harness-model-pairs`, after commit
"Delete all open questions"). Launch plan phase 1–2: every stub is either specced or
recorded as a non-goal before implementation. Goal here: list the main gaps, then work
through them one at a time. Gaps already filed under "To revisit" in 020 are not repeated
as nodes unless they block something else.

## Nodes
- [ ] **N1 Measuring instruments have no spec** — open; user confirmed it needs doing
  - Claim: `grep`, `fileCreated`, `templateTest` are named but there is no instrument page.
  - Notes: no config shape or value type for `grep`/`fileCreated` (only seen in examples);
    no way to declare a user-defined instrument (no `declareInstrument` in 022, no folder
    in 051); `templateTest` bindings (`{{defaultExport}}`, `{{subjectPath}}`), multi-match
    behaviour and test runner unspecified (051 mentions a "test runner" config that 050
    doesn't have); value type is "a count" in 060 but `{passed, failed}` in 085.
- [ ] **N2 How a comparison between results is presented** — open (reframed by user)
  - Claim: the motivating scenarios (slow drift, nerfing) need a view over time; the spec
    only has `compare` of two executions.
  - Notes: "regression" is out of scope — recorded as a non-goal in 020, and removed from
    `run`'s exit code in 100. Still open: comparing more than two executions / a trend
    view, and the `--json` summary shape.
- [ ] **N3 Run data store is under-specified** — open
  - Claim: only `ContainerRunRecord` is typed; the rest of the store is one sentence.
  - Notes: no execution record (test case name, date, matrix, iterations) though
    `executions` and `remeasure <test case>` need one — `ContainerRunRecord` has no
    test case name; no type for the stored aggregation result (tokens/duration
    aggregation shape missing); store interface not defined; 070 is a stub with `_TBD_`.
  - [ ] **N3.1 Sharing the store between CI and a developer** — open: 071 lists four
    options, none chosen. Regression triage (040) depends on it.
- [~] **N4 Container run failure paths and runtime settings** — partly resolved
  - Done: `timeoutSeconds` on each initial prompt, so it is in the permutation hash (066;
    user chose this over a task-level `index.ts`, accepting the copy-paste); wrapper runs
    the harness under `timeout`; `Execution.outcome` = `completed | failed | timedOut`
    (080, 085); cost/resource limits are a non-goal (020).
  - [x] **N4.1 Is a failed run measured?** — resolved: no. Its Result is empty (080, 085).
    How it counts in an aggregation result stays in 020 To revisit, with missing values.
  - [ ] **N4.4 Token costs of a failed run** — open: collection reads the result file from
    the measurement container, which a failed run no longer gets. Collect anyway, or not?
  - [ ] **N4.2 Agent-proposed details to confirm** — open: timeout is required and in
    seconds; a failed run doesn't stop the execution; the postrun image is still committed.
  - [ ] **N4.3 Not yet covered** — open: failed build/push, resuming a partial execution,
    `docker run` details (network, user), shell quoting of `ctx.initialPrompt`.
- [x] **N5 OTel trace and transcript** — resolved: out of scope for v1; moved to a new
  "Soon to follow" section in 020, and the "live in the postrun image" claims removed.
- [x] **N6 Dangling links to deleted "Open questions" sections** — resolved: links removed
  from 020, 064, 100, 110. The underlying questions were dropped with them, not answered.
  - [ ] **N6.1 How a container run is named on the command line** — open: 090 uses
    `container-run-123`, 100 and 110 use the postrun tag.
- [ ] **N7 No Goals, and stub pages** — open
  - Claim: 020 has non-goals only; 010 states problems but not what Thunderjar does about them.
  - Notes: 130 is `_TBD_`; 020 and 070 end in `_TBD_` open-question sections; 003 empty.
- [-] **N8 Hashing is described, not defined** — parked: user is comfortable leaving it to
  implementation.
- [x] **N9 Shipped skill distribution** — resolved: installed with skills.sh
  (`npx skills add`), recorded in 045. Repository name in the example is a placeholder guess.
- [ ] **N10 Small stale spots** — open
  - Notes: 030 🙋‍♂️ note says "6 parameters"; 085 Storage says "parameter hash" for the
    permutation hash; 100 `init` says the example test case "depends on" 050, which
    already decides it; 120 asserts image "labels" that no page defines; 150 lists
    interactive mode in `src/cli/`; README describes 110 as out of scope and 130 as
    populated; no command re-collects token costs (087 backfill) unless `remeasure` does.

## Decisions
- "Regression" is not a v1 concept; Thunderjar presents comparisons only (from N2).
- Each initial prompt declares a required, hashed timeout; no cost or resource limits (from N4).
- A non-zero harness exit fails the container run, recorded as `failed` / `timedOut` (from N4).
- OTel traces and session transcripts are out of v1, "soon to follow" (from N5).
- Hashing algorithm is left to implementation (from N8).
- Skills are installed with skills.sh (from N9); real repository name not relevant yet.
- A failed or timed-out container run is not measured (from N4.1).
- "Soon to follow" stays out of AGENTS.md.

## Open questions
- N4.4: are token costs still collected for a failed run?
- N4.2: confirm the agent-proposed timeout details.
