# 2700: Compare executions

`thunderjar compare <execution-a> <execution-b>` sets two executions' aggregation results side by side. Permutations with the same hash are paired directly. When no hashes match, `compare` says which parameters differ and pairs the permutations by the parameters that did not change. It compares only the measurements whose name and content hash match in both, and names the rest. Each row shows A, B and the signed difference, with no verdict.

Areas: E, B, F

## Spec

- [100-cli-reference.md](../spec/100-cli-reference.md#compare) — usage. Reports differences and makes no judgement
- [110-cli-report-visualization.md](../spec/110-cli-report-visualization.md#compare) — the same-hash and different-hash outputs
- [085-test-case-results.md](../spec/085-test-case-results.md#aggregation-results) — the aggregation result is the unit of comparison, and it needs the same shape on both sides
- [085-test-case-results.md](../spec/085-test-case-results.md#name-is-identity-hash-is-version) — the measurement set hash. A measure is comparable where name and hash both match
- [020-goals-non-goals.md](../spec/020-goals-non-goals.md#non-goals-v1) — no notion of a regression, and no exit code for one
- [060-test-case-parameters.md](../spec/060-test-case-parameters.md#parameters-that-follow-a-moving-target) — a moved floating parameter gives a different permutation hash

## Artifacts

- `thunderjar compare <a> <b>`. Each argument resolves as in `show` from [2200](delivered/2200_show.md): execution ID first, then test case (its latest execution). It exits 0 whenever it compares, whatever the differences. It exits non-zero for an unknown argument, or when A and B ran different tasks. Results for different tasks can't be compared ([055](../spec/055-declaring-test-cases.md#one-task-not-measurements)).
- Each measure in `AggregationResult` from [2300](delivered/2300_aggregation.md) gains `contentHash`. This is the hash its stored values were taken with, or `"mixed"` when iterations disagree, for example after a partial `remeasure`. A mixed measure is never comparable. Old values aggregated as stale still carry their old hash, so `compare` can spot a version mismatch from stored results alone.
- `measurementSetHash(measures): string` hashes the sorted `name:contentHash` pairs, as in 085. Equal set hashes print `Measurement sets match.`
- `diffParameters(a, b): ParameterDiff[]`. For each kind, it reports whether the set of names and hashes differs between the two executions. It uses `resolved` from [2600](2600_floating-parameters.md) to label a moved floating parameter (`main @ 3c1d9e2 -> main @ 7a0f4b1`).
- `pairPermutations(a, b): { pairs, onlyInA, onlyInB }`. It pairs by permutation hash first, then pairs the rest by the kinds that did not differ. A kind with one value on each side is ignored when pairing. Anything that does not pair one-to-one is listed as unpaired, not guessed.
- `compareMeasures(a: AggregationResult, b: AggregationResult): MeasureComparison[]`. Each row is `comparable` (with differences), `versionDiffers`, `onlyInA` or `onlyInB`. The difference is one signed number per aggregate method (`mean +0.4, max +1`), and key by key for records (`passed -2, failed +2`). It is `=` when every number is zero. It also compares `cost / iteration` (from `tokenCosts.costUsd.perIteration` in [2500](2500_token-costs.md); `—` when either side has none) and `duration (mean)`.
- `show <execution>`'s `Moved since` block from 2600 stays, and gains a `Compare with: thunderjar compare <previous> <this>` line.

Different hashes, from checked-in historical executions of 2600's moving `main`, with different recorded resolved commits:

```
$ thunderjar compare 01k4x9j2e8mqz3 01k4xc5w7r1ta6
A  01k4x9j2e8mqz3  2026-09-29  fake-is-prime-main
B  01k4xc5w7r1ta6  2026-09-30  fake-is-prime-main
No permutation hashes match.

Parameters that differ
  codeState  main @ 3c1d9e2 (8e41b07a)  ->  main @ 7a0f4b1 (c5d93a10)   floating, moved

Pairing permutations by the parameters that did not change:
  A 6c2e90d4  <->  B b41d06f2   node20 | snerk | fake-harness-alpha@latest/fake-model-small @ 1.0.0 | plain

Measurement sets match.

Pair A 6c2e90d4 <-> B b41d06f2
  MEASURE              A                           B                           CHANGE
  isPrimeTemplateTest  sum {passed: 8, failed: 2}  sum {passed: 8, failed: 2}  =
  isPrimeTsExists      rate 1.00                   rate 1.00                   =
  readmeExists         rate 0.00                   rate 0.00                   =
  tsIgnoreCount        mean 1.0, max 1             mean 1.0, max 1             =
  cost / iteration     $0.004                      $0.004                      =
  duration (mean)      0.04s                       0.04s                       =
```

Same hashes, from checked-in historical executions whose `isPrimeTemplateTest` values were taken with different template versions (the 2400 scenario):

```
$ thunderjar compare 01k4xf8n3d0vb2 01k4xg2p6s9wc4
A  01k4xf8n3d0vb2  2026-10-01  fake-is-prime
B  01k4xg2p6s9wc4  2026-10-02  fake-is-prime
All 1 permutations match by hash.
Measurement sets differ. Comparing 3 of 4 measurements.
  isPrimeTemplateTest  A: d91f6a07  B: 5e3c8b12  not comparable (version differs)
Run `thunderjar remeasure 01k4xf8n3d0vb2` to give both executions the same measures.

Permutation 4f9a21c8  node20 | baseline | snerk | fake-harness-alpha@1.0.0/fake-model-small | plain
  MEASURE              A                  B                  CHANGE
  isPrimeTsExists      rate 1.00          rate 1.00          =
…
```

Out of scope (story numbers are backlog positions): `--json` and CI exit codes (story 29), and an interactive comparison view (story 30).

**Spec gaps.**

- 110 marks changes `better` / `worse`, but 020 and 100 say `compare` makes no judgement, and a measurement doesn't declare which direction is good. This story prints only the signed difference.
- 110's CHANGE gives one number for a multi-method aggregate (`mean 0.6, max 2` → `+0.8`) and abbreviates records (`sum 17/3` → `-2`). This story gives one difference per method and per key, and keeps the value format `show` already uses.
- The spec's aggregation result carries no content hash, so a stored result can't say which measurement version it combined. This story adds `contentHash` per measure.
- The spec shows pairing by unchanged parameters only by example, and doesn't say what happens when that pairing is ambiguous, or when A and B ran different tasks. This story lists ambiguous permutations as unpaired, and refuses to compare different tasks.

## How to test

Follow [the delivery testing strategy](testing-strategy.md) for fixtures, test placement, adapters and cleanup.

- Unit tests (layer 1 of [120](../spec/120-test-boundaries.md#1-pure-units)):
  - `pairPermutations` covers: all hashes match; one kind's content changed, as in 110's prompt set example; a floating code state moved; a matrix pair added on one side (unpaired); every kind differs (nothing pairs)
  - `compareMeasures` covers: non-zero differences per method and per record key; `versionDiffers`; `mixed`; a measure on one side only; missing cost
  - `measurementSetHash` ignores order
- CLI tests follow [the delivery testing strategy](testing-strategy.md). Invoke `compare` in place against checked-in historical executions, including matching hashes, moved parameters, measurement-version differences, mixed versions and ambiguous pairing. Keep today's declarations and saved artifacts fixed. Assert full stdout, stderr and exit code:
  - the two outputs above
  - copy the scenario's store unchanged to an external `--data-dir`, run `remeasure` using the saved postrun artifacts, then run the same `compare` against that external store: it prints `Measurement sets match.` and every row `=`; neither the checked-in history nor the declarations are changed
  - an unknown ID, or two test cases on different tasks, exits non-zero

- `bun test`
- `bun run typecheck`

## Human interventions

None.
