# 2000: First measurement

After each container run, `thunderjar run` applies the task's measurements to the run's kept directory and prints each measure. The measures are stored as the run's Result in its `ContainerRunRecord`. The first instrument is `fileCreated`: did the agent leave a file matching a glob?

Areas: D, E

## Spec

- [066-task.md](../spec/066-task.md#task-measurements) — `measurements/` beside `initial-prompts/`, one file per measurement, named by its file
- [060-test-case-parameters.md](../spec/060-test-case-parameters.md#measuring-instruments--measurements) — instrument, measurement, measure, `MeasurementResult`
- [060-test-case-parameters.md](../spec/060-test-case-parameters.md#measurement-context) — the `MeasurementContext` seam that instruments run against
- [085-test-case-results.md](../spec/085-test-case-results.md#the-result-record) — the `Result` and `RecordedMeasure` shapes, and what the content hash covers
- [085-test-case-results.md](../spec/085-test-case-results.md#applying-measurements) — measure after the run is preserved, on the same path that backfill will use

## Artifacts

- `declareMeasurement({ instrument, config, aggregate })`. It is typed by instrument, so a `config` that doesn't match its instrument is a TypeScript error. `aggregate` is required and type-checked, but it isn't used until aggregation in backlog story 15.
- The config loader reads `tasks/<task>/measurements/*.ts`. An unknown instrument gets a clear validation error, in the style of [1400](1400_validation.md).
- `hashMeasurement(measurement)` — the content hash over `instrument` and `config`. It leaves out `aggregate`, so editing `aggregate` never makes a measure stale. Editing a measurement changes no parameter or permutation hash.
- A `fileCreated` instrument: `evaluate({ glob }, ctx): Promise<MeasurementResult<boolean>>`. It gives `true` if the glob matches at least one file under the workdir.
- A measurement seam beside the `ContainerRunner` from [1800](1800_fake-agent.md): `openMeasurementContext(postrunTag): Promise<MeasurementContext>`. This story adds a host implementation over the run's kept directory. `workdir` and `glob` resolve in `workspace/`, `exec` runs `sh -c` there, and `harnessResult` is the contents of `thunderjar/result.json`. The Docker measurement container replaces it in backlog story 22.
- `measureContainerRun(measurements, ctx): Promise<Result>`. If an instrument throws, that measure is `erroredWhileMeasuring` and the other measures are still taken.
- A new store method on the `RunDataStore` from [1900](1900_local-run-records.md): `recordMeasures(postrunImage, measures: Result)`. It merges the measures into the existing record by name and overwrites any measure with the same name, which is what backfill in backlog story 16 needs. `run` still writes the record straight after the container run, then measures and calls `recordMeasures`. A crash while measuring therefore leaves a recorded run with an empty Result.
- Fixture: the task of the `fake-is-prime` test case gets two measurements. One matches the file the fake agent writes and one matches nothing, so the run shows both `true` and `false`.

```
$ thunderjar run fake-is-prime
Execution 01k4x9j2e8mqz3 (1 permutation × 2 iterations)
Output in /tmp/thunderjar/01k4x9j2e8mqz3

Permutation 1/1  node20 | baseline | snerk | fake-agent@1.0.0/fake | plain
  iteration 1/2  postrun-e01k4x9j2e8mqz3-h4f9a21c8-i1  exit 0  0.04s
    isPrimeTsExists  true
    readmeExists     false
  iteration 2/2  postrun-e01k4x9j2e8mqz3-h4f9a21c8-i2  exit 0  0.03s
    isPrimeTsExists  true
    readmeExists     false

2 container runs: 2 exited 0
Recorded in .thunderjar/.data/runs.json
```

Out of scope (story numbers are backlog positions): `grep` and `templateTest` (story 13); bundled files in the content hash, which arrive with `templateTest` (story 13); reading measures back in `report` (story 14); backfill (story 16); user-defined instruments. Runs that exit non-zero are still measured until story 23 skips them.

**Spec gaps.**

- `fileCreated` appears only as a name and in one example (`config: { glob }`, value `true`). The spec defines neither its config type, its value type, nor whether it can ever be `skipped`. This story assumes `{ glob: string }` → `boolean`, and the instrument is never `skipped`.
- `erroredWhileMeasuring` carries an `Error`, which doesn't survive JSON. Store `{ message }` instead.
- The spec doesn't say how a measurement's "bundled files" are found for its content hash. That is a decision for story 13.

## How to test

- Unit tests (layer 1 of [120](../spec/120-test-boundaries.md#1-pure-units)) run `fileCreated` against fixture directories: one with a matching file, one without, and one with a nested match.
- Unit tests for `hashMeasurement` check that editing `config` changes the hash, and that editing `aggregate` or renaming the file does not.
- Store tests check that `recordMeasures` merges into an existing record and overwrites a measure with the same name.
- CLI tests use the fake harness, with the ULID generator and clock stubbed. They assert stdout exactly as above. They also check that each record's `result` holds both measures with `contentHash`, `instrument` and `measuredAt`, and that an instrument that throws is recorded as `erroredWhileMeasuring` without stopping the run.

- `bun test`
- `bun run typecheck`

## Human interventions

None.
