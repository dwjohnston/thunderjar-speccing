# 2400: Remeasure

After a measurement is added or edited, `thunderjar remeasure <test case | execution>` applies it to past container runs without rerunning the agent. Only missing or stale measures are taken, and the affected aggregation results are recomputed. Until then, `show` marks stale measures. This is backlog story 16 ("backfill"), built as the spec's `remeasure` command.

Areas: D, E, F

## Spec

- [085-test-case-results.md](../spec/085-test-case-results.md#backfilling-measurements) — only missing or stale measures are taken, and the aggregation result is recomputed
- [085-test-case-results.md](../spec/085-test-case-results.md#name-is-identity-hash-is-version) — a stale measure is a content hash mismatch, and a re-taken measure replaces the old one
- [085-test-case-results.md](../spec/085-test-case-results.md#deleted-and-renamed-measurements) — deleted measures are kept but excluded, and a rename is a delete plus an add
- [100-cli-reference.md](../spec/100-cli-reference.md#remeasure) — `remeasure` usage, execution vs test case
- [110-cli-report-visualization.md](../spec/110-cli-report-visualization.md#remeasure) — example output, including the deleted-measurement line
- [110-cli-report-visualization.md](../spec/110-cli-report-visualization.md#an-execution) — the ``stale, run `remeasure` `` marker in `show`

## Artifacts

- `measureStatus(recorded: RecordedMeasure | undefined, measurement): "missing" | "stale" | "current"`. It compares the stored `contentHash` with `hashMeasurement` from [2000](delivered/2000_first-measurement.md) and [2100](delivered/2100_more-instruments.md).
- `planRemeasure(records, measurements): RemeasurePlan`. This pure function lists, per container run, the measurement names to take, and per execution, each current measurement's status and each deleted name with how many stored measures it has.
- `thunderjar remeasure <test case | execution>`. The argument resolves the way `show` resolves it in [2200](delivered/2200_show.md): execution ID first, then test case. A test case means all of its executions, from `listExecutions`. For each run with work to do, it opens a context with `openMeasurementContext`, calls `measureContainerRun` with just the planned measurements and stores the result with `recordMeasures`. It then recomputes **every** aggregation result of the executions it was given through the path from [2300](delivered/2300_aggregation.md), even if nothing needed measuring. That way an edited `aggregate` or a deleted measurement is also picked up.
- Untouched measures keep their value and `measuredAt`. Backfilled measures get the time they were taken.
- If the measurement opener cannot read a run's postrun image, that run is reported and skipped. The other runs are still measured, aggregates are refreshed from the records actually stored, and the command exits non-zero without losing its partial-success report.
- `show` marks stale measures. The execution view appends ``stale, run `remeasure` `` to any measure that has a stale contributing value. The container run view puts `(stale)` after the value.

Fixture scenario: scenario 8 holds historical records with missing and stale measurements, deleted `readmeExists` values, today's declarations, and saved postrun workspaces. Additional declaration-history cases belong in checked-in scenario state. Tests never edit measurement files or delete declarations.

```
$ thunderjar show fake-is-prime
...
  MEASURE              MEASURED  AGGREGATE
  isPrimeTemplateTest  2/2       sum {passed: 8, failed: 2}  stale, run `remeasure`
  isPrimeTsExists      2/2       rate 1.00
  tsIgnoreCount        2/2       mean 1.0, max 1
...

$ thunderjar remeasure 01k4x9j2e8mqz3
Execution 01k4x9j2e8mqz3  (2 container runs)
Current measurements for task is-prime:
  isPrimeTemplateTest  new / changed (5e3c8b12)
  isPrimeTsExists      up to date
  tsIgnoreCount        up to date
  readmeExists         deleted from task; 2 stored measures kept, excluded from aggregates

Measuring from each postrun image:
  4f9a21c8 i1  isPrimeTemplateTest  {passed: 4, failed: 2}
  4f9a21c8 i2  isPrimeTemplateTest  {passed: 4, failed: 2}

Updated 2 container runs. Recomputed 1 aggregation result.
The agent was not rerun.

$ thunderjar remeasure fake-is-prime
fake-is-prime has 2 executions (4 container runs)
  01k4x9j2e8mqz3  2 runs  2026-09-29  (already current, nothing to do)
  01k4xc5w7r1ta6  2 runs  2026-09-30

Measuring 2 container runs...  done
Updated 2 container runs. Recomputed 2 aggregation results.
```

Out of scope (story numbers are backlog positions): measuring in a Docker measurement container from the postrun image (story 22); leaving failed or timed-out runs unmeasured (story 23, until then `remeasure` measures them like `run` does); backfilling token costs (story 17); `--json` (story 29).

**Spec gaps.**

- The backlog calls the command `measure`, but the spec calls it `remeasure`. This story builds `remeasure`.
- The spec doesn't say whether an `erroredWhileMeasuring` measure is retried. Its hash still matches, so a strict reading never retries it. This story treats it as missing, so `remeasure` retries it. `skipped` is a real outcome, so it isn't retried.
- "Re-running an unchanged measurement overwrites it" implies a way to force a re-measure, but `remeasure` has no flag for it. None is added here.
- The spec doesn't say what happens when a run's postrun image cannot be opened. This story reports the run, skips it and exits non-zero.
- Recomputing on every `remeasure` goes beyond the spec's "recompute when a measure is backfilled". Without it, an edited `aggregate` or a deleted measurement never shows up in stored results (see [2300](delivered/2300_aggregation.md)).

## How to test

Follow [the delivery testing strategy](testing-strategy.md) for fixtures, test placement, adapters and cleanup.

- Unit tests (layer 1 of [120](../spec/120-test-boundaries.md#1-pure-units)) for `measureStatus` and `planRemeasure` cover a new measurement, an edited config, an edited bundled template, an edited `aggregate` only (not stale), a deleted measurement, a rename (the old name is deleted and the new one is missing) and an errored measure (retried).
- CLI tests follow [the delivery testing strategy](testing-strategy.md). Invoke `remeasure` and `show` against unchanged scenario 8, using `--data-dir` seeded with an exact copy of its checked-in store and the recording Docker's saved-workspace mappings. Check in any further historical states needed for the cases below; do not run an agent first or patch declarations or records. Assert complete stdout, stderr, exit code and the resulting store:
  - untouched measures keep their original `measuredAt`
  - a second `remeasure` reports nothing to do and changes no record
  - history recorded with different aggregate methods re-measures nothing when measurement hashes are current, but `show` reflects today's aggregate methods afterwards
  - an omitted postrun mapping gives a reported, skipped run and a non-zero exit; other available runs are updated, skipped records remain intact, and every selected aggregate is refreshed
  - an unknown argument prints an error and exits non-zero

- `bun test`
- `bun run typecheck`

## Human interventions

None.
