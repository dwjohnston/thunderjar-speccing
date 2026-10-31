# 2300: Aggregation

`thunderjar show <test case | execution>` now prints one aggregation result per permutation. For each measure it shows how many iterations were measured and the combination that measurement asked for in its `aggregate` (`rate`, `mean`, `max`, `sum`…), followed by the duration across iterations. Aggregation results are stored beside the container run records and are recomputed whenever a measure is recorded.

Areas: D, E, F

## Spec

- [085-test-case-results.md](../spec/085-test-case-results.md#aggregation-results) — what an aggregation result is, and that it is stored and recomputed on change
- [085-test-case-results.md](../spec/085-test-case-results.md#how-a-measures-values-combine) — the `AggregateFor<T>` menu, one key per chosen method, and `measured`
- [085-test-case-results.md](../spec/085-test-case-results.md#deleted-and-renamed-measurements) — a deleted measurement's stored measures are left out of aggregation results
- [110-cli-report-visualization.md](../spec/110-cli-report-visualization.md#an-execution) — the `MEASURED` / `AGGREGATE` table and the duration line

## Artifacts

- `aggregateMeasure(values, methods)`: combines one measurement's values across iterations, one key per method. It covers the whole menu: `rate` and `count` for booleans; `mean`, `median`, `min`, `max` and `sum` for numbers; and `sum` and `mean` key by key for `Record<string, number>`.
- `aggregatePermutation(records, measurements): AggregationResult`. It takes one permutation's iteration records and the task's current measurements, and returns `{ executionId, permutationHash, iterations, measures, duration: { mean, max } }`, where each measure is `{ measured, ...methods }`.
  - **Missing values are excluded and counted.** `skipped` and `erroredWhileMeasuring` iterations, and iterations without the measure, don't contribute a value. `measured` says how many did. When nothing was measured, the measure is `{ measured: 0 }`, with no method keys.
  - Only measurements the task declares today are aggregated. A stored measure whose file has been deleted stays in its Result, but it isn't aggregated.
  - Stale measures are still aggregated. Backlog story 16 marks them.
- New methods on the `RunDataStore` from [1900](1900_local-run-records.md): `recordAggregationResult(result)`, which overwrites by `(executionId, permutationHash)`, and `getAggregationResults(executionId)`. In `jsonFileStore`, the results sit in the same file as the run records.
- `run` recomputes and stores its permutation's aggregation result after each `recordMeasures` call from [2000](2000_first-measurement.md). Backfill in backlog story 16 should do the same through the same path. `run`'s own output is unchanged.
- The `show` execution view from [2200](2200_show.md) reads stored aggregation results and replaces the per-iteration columns with `MEASURED` and `AGGREGATE`, as in the spec. Per-iteration values are still available through `show <container run>`. The exit codes become one summary line.
- Fixture: the four `fake-is-prime` measurements declare `isPrimeTemplateTest: ["sum"]`, `isPrimeTsExists: ["rate"]`, `readmeExists: ["rate"]` and `tsIgnoreCount: ["mean", "max"]`.

```
$ thunderjar show fake-is-prime
Execution  01k4x9j2e8mqz3  (latest of fake-is-prime)
Test case  fake-is-prime
Task       is-prime
Date       2026-09-29 14:30

Permutation 4f9a21c8  (2 iterations)
  node20 | baseline | snerk | fake-agent@1.0.0/fake | plain

  MEASURE              MEASURED  AGGREGATE
  isPrimeTemplateTest  2/2       sum {passed: 8, failed: 2}
  isPrimeTsExists      2/2       rate 1.00
  readmeExists         2/2       rate 0.00
  tsIgnoreCount        2/2       mean 1.0, max 1

  exit       2/2 exited 0
  duration   mean 0.04s, max 0.04s
```

Out of scope (story numbers are backlog positions): stale marking and the `measure` command (story 16), cost and tokens in the aggregate (story 17), `compare` (story 19), and leaving failed or timed-out runs out of the aggregate (story 23). Until story 23, a run that exits non-zero is measured and aggregated like any other.

**Spec gaps.**

- How `skipped` and `erroredWhileMeasuring` iterations count is listed as unresolved ([020](../spec/020-goals-non-goals.md#to-revisit)). This story takes the spec's "likely answer": exclude them and show the count as `MEASURED`.
- The spec says to recompute "whenever a measure is added or backfilled", but editing a measurement's `aggregate`, or deleting a measurement file, records nothing, so nothing triggers a recompute and the stored result goes stale. Story 16's `measure` could recompute every aggregation result of the test case, even when it has no missing measures to fill.
- The spec gives no `AggregationResult` type, no rounding (its examples show `rate` to two places and `mean` to one), and no `median` rule for an even count. This story takes the mean of the two middle values.
- The spec's execution view has no exit codes. This story keeps a summary line until story 23 brings in outcomes.

## How to test

- Unit tests (layer 1 of [120](../spec/120-test-boundaries.md#1-pure-units)) for `aggregateMeasure` and `aggregatePermutation`:
  - the spec's five-iteration `is-prime` example gives exactly the spec's aggregation result, including `isPrimeTemplateTest` at `measured: 4`
  - every menu method, including `median` over an even count and `mean` over `{ passed, failed }`
  - all iterations skipped gives `{ measured: 0 }`
  - a stored measure with no current measurement is left out
- Type tests check that `aggregate: ["rate"]` on a numeric measurement is still a TypeScript error.
- Store tests check that `recordAggregationResult` overwrites by execution and permutation, and that `getAggregationResults` returns them in matrix order.
- CLI tests use the fake harness, with the ULID generator and clock stubbed, and assert stdout exactly as above. One fixture has an instrument that throws in one iteration only, and it shows `1/2`.

- `bun test`
- `bun run typecheck`

## Human interventions

None.
