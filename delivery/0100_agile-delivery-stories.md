# Agile Delivery Stories

Draft / brainstorm only. An ordered list of stories for building Thunderjar
incrementally, so each story leaves a working application. Running real agents in Docker
comes late.

The key move is a **fake agent** (a shell command that writes a file) so everything
downstream can be built and tested before a real agent, or even Docker, is involved.

## Phase 1: Shell and config

1. **Hello world.** `npx thunderjar` is published to npm, prints "hello world!", and a
   landing page exists.
2. **Init.** `thunderjar init` scaffolds the folder structure with empty `declareX` stubs.
3. **Declarations load, with generated types.** The `declareX` functions are populated;
   `thunderjar plan` loads the config and lists what it found (parameters, tasks,
   test cases). Typed pair names are generated, so a typo in a test case is a
   TypeScript error.
4. **Validation.** Bad declarations produce clear errors, such as a missing file or an
   unknown parameter reference.
5. **Permutations.** `plan` expands a test case's matrix and prints each permutation
   with its names.
6. **Hashes.** `plan` also prints parameter hashes and the permutation hash. Renaming a
   key keeps the hash; editing content changes it.

## Phase 2: Fake runs on the host (no Docker)

7. **Dry run.** `thunderjar run` walks each permutation and iteration and prints what it
   would do.
8. **Fake agent.** `run` executes the harness `cli` command in a local temp directory.
   Using an `echo`/`touch` harness, it writes the result file and `run.json` (timing,
   exit code).
9. **Local run records.** Each run writes a `ContainerRunRecord` to a local JSON file
   store, with an execution ID and iterations.
10. **First measurement.** The `fileCreated` instrument runs against the temp directory,
    and the Result is stored.
11. **More instruments.** Add `grep`, then `templateTest`.
12. **Report.** `thunderjar report` prints a table of the latest execution.
13. **Aggregation.** `report` shows rate/mean/max across iterations per permutation.
14. **Backfill.** Add a new measurement, run `thunderjar measure`, and only the missing or
    stale measures are filled.

## Phase 3: Real agent output, still no Docker

15. **Token costs.** Add a `collectTokenCosts` collector, tested against canned result
    files. The report shows tokens and cost.
16. **Floating parameters.** `determineHash` entries resolve once per execution, and the
    report flags comparisons across a moving target.
17. **Compare executions.** `report` compares two executions and warns on a hash
    mismatch.

## Phase 4: Docker

18. **Prerun image.** `run` builds an image from base image + code state + prompt set,
    and the fake agent runs inside it.
19. **Postrun image.** Commit and tag it locally.
20. **Measurement container.** Measurements run in a throwaway container from the postrun
    image, and backfill works on old images.
21. **Failure handling.** Agent failure and timeout are recorded as outcomes and are not
    measured.
22. **Restore.** `thunderjar restore` opens a container from a postrun image.
23. **Real harness.** Claude Code runs in the container with `requiredEnv` passed
    through, and `doctor` checks credentials.

## Phase 5: Sharing and lifecycle

24. **Registry.** Push and pull images to a registry (the image store).
25. **Shared data store.** Run records live somewhere shared (the open question in
    [071-data-persistence.md](../spec/071-data-persistence.md)).
26. **Purge.** Remove old images.
27. **CI.** A CI workflow, non-interactive output and exit codes.
28. **Interactive report.** The visualization (explicitly out of scope for the first
    pass).

## Notes

- **Story 8 is the key move.** The harness `cli` is just a command, so running it on the
  host with a fake agent exercises most of the pipeline. Docker (18–20) then swaps in the
  execution environment without changing anything above it.
- **The data store is deliberately a JSON file until story 25**, so
  [071-data-persistence.md](../spec/071-data-persistence.md) stays an open question and
  doesn't block anything.
- **Story 6 could move earlier or later.** If hashes feel abstract, hold them until after
  story 9, when there are records to attach them to.
- **Not in the list:** shipped skills ([045](../spec/045-shipped-skills.md)) and the Biome
  rule generator. Both are candidates for a side track.
