# 3100: Failure handling

Each container run is now recorded with an outcome: `completed`, `failed` or `timedOut`. A run whose agent failed or timed out is still committed and still costed, but it isn't measured. `run`, `show`, `remeasure` and `compare` say how many runs completed instead of quietly averaging over fewer runs. This is backlog story 23.

Areas: C, D, E

## Spec

- [080-docker-execution.md](../spec/080-docker-execution.md#when-the-agent-fails) — exit code to outcome, still committed, not measured, and the execution carries on
- [085-test-case-results.md](../spec/085-test-case-results.md#execution) — `Execution.outcome` on the record
- [085-test-case-results.md](../spec/085-test-case-results.md#applying-measurements) — a failed or timed-out run is not measured
- [066-task.md](../spec/066-task.md#timeout) — `timeoutSeconds` comes from the initial prompt
- [020-goals-non-goals.md](../spec/020-goals-non-goals.md#to-revisit) — how failed runs count in aggregates is still open

## Artifacts

- `outcomeOf(exitCode): "completed" | "failed" | "timedOut"`. This pure function maps `0` → `completed`, `124` → `timedOut`, and anything else → `failed`. `run` stores the result as `execution.outcome` on each `ContainerRunRecord`, the field that [1900](delivered/1900_local-run-records.md) left out. Records written before this story have no `outcome`, so readers derive it from `exitCode` with the same function, and no migration is needed.
- `run` skips the measurement containers from [3000](3000_measurement-container.md) for any run that isn't `completed`. Its Result stays `{}`. The execution carries on with its remaining runs. **A failed agent is an observation, not an error, so `run` still exits 0.** A Docker or infrastructure failure isn't an outcome. It keeps its existing behaviour (stop, then a non-zero exit).
- **Token costs are still collected for failed and timed-out runs**, which settles the question 2500 left open. Those runs spent tokens, and leaving them out would make costs look lower than they are. Collection opens one context from the postrun image just for this, and no measurement runs in it. A timed-out harness usually wrote no result file, so its costs are `absent` and excluded, as [2500](2500_token-costs.md) already does.
- `aggregatePermutation` from [2300](delivered/2300_aggregation.md) gains `outcomes: { completed, failed, timedOut }`:
  - Measures combine values from `completed` runs only. Stale values stored on failed runs before this story are ignored. `measured` already counts what was combined, so `1/2` makes the gap visible.
  - Cost and duration still cover every run, because a timed-out run really did take that long and cost that much.
  - This story doesn't decide whether a failed run should count as, say, `false` in a `rate`. That is still the open question in 020.
- `planRemeasure` from [2400](2400_remeasure.md) leaves runs that aren't `completed` out of the measuring work, but still re-collects their token costs when the collector has changed. `remeasure` prints one line counting the runs it didn't measure.
- Display:
  - In `run`, each iteration line shows the outcome where it showed the exit code, and the summary counts the outcomes.
  - In `show <execution>`, an `outcome` line replaces `exit`.
  - In `show <container run>`, the run's outcome and exit code are shown, and its measures say `not measured (timedOut)`.
  - `compare` from [2700](2700_compare.md) adds a `completed` row (`2/2  1/2  -1`).
- Fixtures: reuse scenario 3's checked-in `fake-harness-alpha` versions that fail or time out and its `fails` and `times-out` test cases. Add checked-in canned result payloads where cost collection needs them, and historical records to scenario 8 where reporting needs them. Tests never rewrite an agent, prompt, exit code or stored record to manufacture a case.

```
$ thunderjar run fake-is-prime-failures
Execution 01k4xh7q2m5tr8 (2 permutations × 2 iterations)
Output in /tmp/thunderjar/01k4xh7q2m5tr8

Permutation 1/2  node20 | baseline | snerk | fake-harness-alpha@1.0.0/fake-model-small | fails
  prerun image   thunderjar:prerun-h8d3e5b70  built (3.1s)
  iteration 1/2  postrun-e01k4xh7q2m5tr8-h8d3e5b70-i1  failed (exit 3)  0.12s  $0.004
    not measured
  iteration 2/2  postrun-e01k4xh7q2m5tr8-h8d3e5b70-i2  failed (exit 3)  0.11s  $0.004
    not measured

Permutation 2/2  node20 | baseline | snerk | fake-harness-alpha@1.0.0/fake-model-small | hangs
  prerun image   thunderjar:prerun-h2a6f14c9  built (3.0s)
  iteration 1/2  postrun-e01k4xh7q2m5tr8-h2a6f14c9-i1  timedOut  1.00s  —
    not measured
  iteration 2/2  postrun-e01k4xh7q2m5tr8-h2a6f14c9-i2  timedOut  1.00s  —
    not measured

4 container runs: 2 failed, 2 timedOut   total cost $0.008
Committed 4 postrun images to thunderjar.

$ thunderjar show 01k4xh7q2m5tr8
…
Permutation 2a6f14c9  (2 iterations)
  node20 | baseline | snerk | fake-harness-alpha@1.0.0/fake-model-small | hangs

  MEASURE              MEASURED  AGGREGATE
  isPrimeTemplateTest  0/2       —
  …

  cost       —   (0/2 collected)
  outcome    0/2 completed, 2 timedOut
  duration   mean 1.00s, max 1.00s

$ thunderjar show postrun-e01k4xh7q2m5tr8-h2a6f14c9-i1
…
Measures  not measured (timedOut)
Cost      unavailable (absent)
Duration  1.00s   timedOut (exit code 124)
```

The `fake-is-prime` runs from earlier stories now print `completed` where they printed `exit 0`, and their summary says `2 container runs: 2 completed`.

Out of scope (story numbers are backlog positions): retrying failed runs; infrastructure-error output and CI exit codes (story 29); counting failed runs inside measure aggregates (the open question in 020).

**Spec gaps.**

- 080 says "no measurement container is started" for a failed run, but collecting its token costs needs the result file from the postrun image. This story opens a container only to collect them. 080 should say "no measurements are applied" instead, and 085 should say that failed runs' token costs are collected.
- 085 doesn't say whether cost and duration aggregates include failed runs. This story includes them.
- 110's `run` sample uses `done`, and its summary says "0 failed to run", which reads like an infrastructure count. Nothing shows a failed or timed-out iteration. This story prints the outcome names from 080.

## How to test

Follow [the delivery testing strategy](testing-strategy.md) for fixtures, test placement, adapters and cleanup.

- Unit tests (layer 1 of [120](../spec/120-test-boundaries.md#1-pure-units)):
  - `outcomeOf` for `0`, `124`, `3` and `137`
  - `aggregatePermutation` over a mix of outcomes: measures use completed runs only, cost and duration use all runs, and `outcomes` is correct
  - `planRemeasure` skips the measurements of failed runs but re-collects their stale costs
- CLI tests follow [the delivery testing strategy](testing-strategy.md). Invoke the real CLI against unchanged failure scenarios, recording Docker lifecycle state and an external `--data-dir`; configure the adapter's saved artifacts and command failures, not the project files. Assert stdout, stderr, exit code, records and commands:
  - a failed run is committed and gets a single `start` / `exec` / `rm` to collect its costs, and nothing per measurement
  - the execution carries on, and `run` exits 0
  - `show`, `remeasure` and `compare` print the lines above
  - a record without `outcome` still shows `completed`
- Keep host-runner exit-3 and timeout behavior in lower-layer runner tests. Command acceptance coverage uses the CLI; do not inject that runner into new command tests.
- Docker image tests (layer 3.2) live beside `run` as `run.docker.test.ts`. Invoke the CLI against unchanged scenario 3 using real Docker, an external `--data-dir` and a throwaway `--image-prefix`. Assert that the real wrapper kills its sleeping fake harness, records exit 124, and still commits the postrun image. Clean up all test-owned images, containers and data.

- `bun test`
- `bun run test:prepare && bun run test:docker`
- `bun run typecheck`

## Human interventions

None.
