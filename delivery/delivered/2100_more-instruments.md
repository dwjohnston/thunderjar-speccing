# 2100: More instruments

Tasks can now declare `grep` measurements, which count matching lines, and `templateTest` measurements, which render a test template against the agent's output and count passing and failing tests. `thunderjar run` prints and stores these measures alongside the `fileCreated` measures from [2000](2000_first-measurement.md).

Areas: D

## Spec

- [060-test-case-parameters.md](../spec/060-test-case-parameters.md#templatetest) — `templateTest`: its config, the template, rendering through `writeFile`, `skipped` and `erroredWhileMeasuring`
- [060-test-case-parameters.md](../spec/060-test-case-parameters.md#measurement-context) — `exec` and `writeFile`, which the new instruments are the first to use
- [085-test-case-results.md](../spec/085-test-case-results.md#name-is-identity-hash-is-version) — the content hash covers bundled files, such as the template
- [085-test-case-results.md](../spec/085-test-case-results.md#how-a-measures-values-combine) — the `grep` and `templateTest` example declarations, and the value types that `aggregate` is typed against
- [066-task.md](../spec/066-task.md#task-measurements) — supporting files sit beside the measurement file

## Artifacts

- A `grep` instrument: `evaluate({ glob, pattern }, ctx): Promise<MeasurementResult<number>>`. It returns the number of lines that match `pattern` (a JavaScript regex) across every file that matches `glob`. It reads files through `ctx.glob` and `ctx.readFile`, so it doesn't depend on which `grep` the image has. If the glob matches no files, the measure is `skipped`, so a run with no output doesn't count as "0 `@ts-ignore`s".
- A `templateTest` instrument: `evaluate({ subject, template }, ctx): Promise<MeasurementResult<{ passed: number; failed: number }>>`.
  - The `subject` glob matching nothing gives `skipped`.
  - For each match, it fills in `{{subjectPath}}` and `{{defaultExport}}`. It writes the rendered test beside the subject with `ctx.writeFile`, runs it with `ctx.exec("bun test <path>")`, and reads the pass and fail counts. When there are several matches, their counts are summed.
  - A template that can't bind (for example, the subject has no export to bind to) or a test run that reports no results gives `erroredWhileMeasuring`.
  - `template` is a path relative to the measurement file. The config loader rejects a missing template with a clear error, in the style of [1400](1400_validation.md).
- Bundled files in the content hash. Each instrument names its file-valued config keys (`templateTest`: `template`). `hashMeasurement` then covers those files' contents as well as `instrument` and `config`. Editing a template makes the measure stale. Editing a sibling file that no config references doesn't.
- `declareMeasurement` is typed for all three instruments, so `aggregate: ["rate"]` on a `grep` measurement is a TypeScript error.
- Each measurement gets its own throwaway context. The host `openMeasurementContext` from [2000](2000_first-measurement.md) now works on a scratch copy of the run's `workspace/` and discards it afterwards. A rendered test therefore never ends up in the kept run directory, and a later `grep` never counts it. The Docker measurement container in backlog story 22 should keep the same isolation.
- Fixture: the fake agent now writes a real `isPrime.ts`, with a deliberate bug and one `@ts-ignore`. The `fake-is-prime` task gains `tsIgnoreCount` (`grep`) and `isPrimeTemplateTest` (`templateTest`), with its template beside it. The template has one test that fails against the bug.

```
$ thunderjar run fake-is-prime
Execution 01k4x9j2e8mqz3 (1 permutation × 2 iterations)
Output in /tmp/thunderjar/01k4x9j2e8mqz3

Permutation 1/1  node20 | baseline | snerk | fake-agent@1.0.0/fake | plain
  iteration 1/2  postrun-e01k4x9j2e8mqz3-h4f9a21c8-i1  exit 0  0.04s
    isPrimeTemplateTest  {passed: 4, failed: 1}
    isPrimeTsExists      true
    readmeExists         false
    tsIgnoreCount        1
  iteration 2/2  postrun-e01k4x9j2e8mqz3-h4f9a21c8-i2  exit 0  0.03s
    isPrimeTemplateTest  {passed: 4, failed: 1}
    isPrimeTsExists      true
    readmeExists         false
    tsIgnoreCount        1

2 container runs: 2 exited 0
Recorded in .thunderjar/.data/runs.json
```

Out of scope (story numbers are backlog positions): a configurable test runner (this story always uses `bun test`), user-defined instruments, and running inside a measurement container (story 22).

**Spec gaps.**

- `grep` appears only in an example. Its value type, whether `pattern` is a regex, and whether it counts lines, matches or files are all undefined. This story assumes a JavaScript regex, a line count, and `skipped` when no file matches.
- `templateTest` doesn't say how placeholders bind or what happens when `subject` matches several files. The spec's example template has `import { {{defaultExport}} }`, which imports a *named* export, so the placeholder's name and its use disagree. This story binds `{{defaultExport}}` to the subject's single exported function, whether it is a default or a named export, and sums the counts over all matches.
- [051](../spec/051-configuration-folder-structure.md) says `thunderjar.config.ts` holds a "test runner", but no page defines it, or how `templateTest` would read pass and fail counts from a runner other than Bun.
- The spec doesn't say whether measurements share one measurement container. If they do, a rendered test can leak into the next measurement. This story gives each measurement its own context.

## How to test

- Unit tests (layer 1 of [120](../spec/120-test-boundaries.md#1-pure-units)) run each instrument against fixture directories:
  - `grep`: no matching file is `skipped`, matches are counted across several files, and the regex is honoured
  - `templateTest`: no subject is `skipped`; a correct subject and a buggy one give the expected counts; a subject with no export is `erroredWhileMeasuring`
  - after `templateTest`, the fixture's source directory is unchanged
- Unit tests for `hashMeasurement` check that editing the template changes the hash, and that editing an unreferenced sibling file does not.
- Config loader tests check that a missing template gives a validation error.
- CLI tests use the fake harness, with the ULID generator and clock stubbed. They assert stdout exactly as above, and check that the kept `workspace/` has no rendered test in it.

- `bun test`
- `bun run typecheck`

## Human interventions

None.
