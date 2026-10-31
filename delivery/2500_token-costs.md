# 2500: Token costs

After each container run, Thunderjar hands the harness's result file to that family's `collectTokenCosts` and records the token costs on the run. `run` prints each iteration's cost and a total. `show` prints cost and tokens per permutation and per container run, and leaves runs whose costs are unavailable out of the numbers. `remeasure` re-collects token costs after a collector changes.

Areas: C, E, F

## Spec

- [087-collecting-token-costs.md](../spec/087-collecting-token-costs.md#normalising-collecttokencosts) — the collector signature, `TokenCosts`, per-model and four buckets
- [087-collecting-token-costs.md](../spec/087-collecting-token-costs.md#when-collection-fails) — `absent` / `unparseable` / `notReported`, the wrapped collector call, and never zero-filling
- [087-collecting-token-costs.md](../spec/087-collecting-token-costs.md#backfilling-token-costs) — re-collecting with the current collector and the run's stored version and model ID
- [064-harness.md](../spec/064-harness.md#collecttokencosts-reading-back-the-cost) — `collectTokenCosts.ts` in the family folder, outside the pair hash
- [085-test-case-results.md](../spec/085-test-case-results.md#aggregation-results) — token costs are aggregated alongside the measures
- [110-cli-report-visualization.md](../spec/110-cli-report-visualization.md#show) — the `cost` and `tokens` lines in both `show` views, and the `$` column in `run`

## Artifacts

- `declareTokenCostCollector(fn)`, and the `TokenCosts` / `ModelTokenCosts` / `CollectorContext` types from 087. Config loading picks up each family's `collectTokenCosts.ts`. A family without one fails validation, as a missing `models.ts` does. The file stays out of the pair hash, as [1600](delivered/1600_hashes.md) already tests.
- `collectTokenCosts(collector, raw: string | undefined, ctx: CollectorContext): TokenCosts`. This is Thunderjar's wrapper. No file gives `absent`. A collector that throws, or returns something that isn't a `TokenCosts`, gives `unparseable`.
- Collection runs in the same step as measuring, from [2000](delivered/2000_first-measurement.md). It reads the raw file from the run's `MeasurementContext` and the version and model ID from the record's stored `harnessModel`, from [1900](delivered/1900_local-run-records.md). The new store method `recordTokenCosts(postrunImage, tokenCosts)` stores the result as `{ ...TokenCosts, collectorHash, collectedAt }`, mirroring a `RecordedMeasure`. `collectorHash` is the content hash of `collectTokenCosts.ts`.
- `aggregatePermutation` from [2300](delivered/2300_aggregation.md) gains `tokenCosts: { collected, inputTokens, outputTokens, cacheCreationTokens, cacheReadTokens, byModel, costUsd?: { total, perIteration } }`. Only `collected` runs count, and `collected` says how many there were. A run's cost is the sum of its models' `costUsd`, and it counts only if every model reported one. `perIteration` divides by the runs that have a cost, not by all iterations.
- `remeasure` from [2400](2400_remeasure.md) re-collects a run whose token costs are missing or whose `collectorHash` differs from the current collector's, then recomputes the aggregation results as it already does. If the hash matches, the run isn't retried, because a pure collector would give the same answer.
- Fixtures:
  - Checked-in scenarios use `fake-harness-alpha` and `fake-harness-beta` collectors with synthetic usage payloads and fake model IDs. Cover a delegated run whose flat `usage` disagrees with its per-model breakdown, an all-zero crash result, error text and an empty file. No real harness family or model identity belongs in these fixtures or unit tests.
  - The fake harness's `cli` writes its checked-in canned payload to `ctx.resultPath`. Each iteration reports `fake-model-small-001`: in 1,200, out 340, no cache, `$0.0042`, `costBasis: "list"`. Separate checked-in project states cover no result file, partial reporting and history collected with an older collector hash; tests never edit the collector between commands. A real collector is scaffolded and checked by `init` in 3300.

```
$ thunderjar run fake-is-prime
…
  iteration 1/2  postrun-e01k4x9j2e8mqz3-h4f9a21c8-i1  exit 0  0.04s  $0.004
    isPrimeTemplateTest  {passed: 4, failed: 1}
    …
2 container runs: 2 exited 0   total cost $0.008

$ thunderjar show fake-is-prime
…
  tsIgnoreCount        2/2       mean 1.0, max 1

  cost       $0.008 total   $0.004 / iteration
  tokens     in 2,400       out 680
  exit       2/2 exited 0
  duration   mean 0.04s, max 0.04s

$ thunderjar show postrun-e01k4x9j2e8mqz3-h4f9a21c8-i1
…
Cost      $0.004  (list)
Tokens    in 1,200   out 340   cache write 0, read 0
Duration  0.04s   exit code 0
```

- When some runs are unavailable, the execution view says so: `cost  $0.004 total  $0.004 / iteration  (1/2 collected)`. When none were collected, it prints `—` and the count. The container run view prints `unavailable (unparseable)` and so on. When a run used more than one model, it prints one `Tokens` line per model.

Out of scope (story numbers are backlog positions): reading the file from a measurement container (story 22); the real Claude Code harness and whether Thunderjar ships its collector (story 25); comparing costs across executions (story 19); `--json` (story 29). Until story 23, a run that exits non-zero has its token costs collected like any other.

**Spec gaps.**

- The spec has no way to tell that a collector changed. 064 excludes it from the pair hash, but backfill needs to know what is out of date. This story adds `collectorHash` to the stored token costs, the way measures carry a `contentHash`.
- `MeasurementContext.harnessResult` is a `string`, so it can't express "no file" (`absent`). The host context should expose `undefined` in that case.
- The spec's `tokens in … out …` lines don't say whether `in` includes cache tokens, and they hide the cache-read bucket that 087 calls the contamination signal. This story makes `in` plain `inputTokens`, shows the cache buckets in the container run view, and keeps all four in the aggregate.
- 085 says failed runs aren't measured, but it doesn't say whether their token costs are collected. They did spend tokens. Story 23 should decide, and collecting them seems right.

## How to test

Follow [the delivery testing strategy](testing-strategy.md) for fixtures, test placement, adapters and cleanup.

- Unit tests (layer 1 of [120](../spec/120-test-boundaries.md#1-pure-units)):
  - the fake collectors against synthetic payloads, including delegated fake models whose costs must come from the per-model breakdown
  - the wrapper for a missing file, a throw and a malformed return
  - aggregation with a mix of collected and unavailable runs, which must not zero-fill, and with a model missing `costUsd`
- CLI tests follow [the delivery testing strategy](testing-strategy.md). Run unchanged fake-harness scenarios through the real CLI and recording Docker, and assert stdout, stderr, exit code and stored costs. A `run` writes to an external `--data-dir`; `show` reads checked-in history. `remeasure` writes to an external store seeded with an exact copy of history whose collector hash is older than today's declaration, using saved postrun payloads; it re-collects without rerunning the agent. Also cover a checked-in case whose `cli` writes no result file, showing `absent` and `(1/2 collected)`. Normalize only genuinely variable output, not stored history or content hashes.

- `bun test`
- `bun run typecheck`

## Human interventions

None.
