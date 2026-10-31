# 3000: Measurement container

`run` and `remeasure` now measure each container run in throwaway measurement containers started from its postrun image, not in a copy of the run on the host. The postrun image is the only copy of the agent's end state. So `remeasure` can backfill a new or edited measurement onto any run whose image still exists, long after `$TMPDIR` is cleared, and the image is unchanged afterwards. This is backlog story 22.

Areas: D, C

## Spec

- [030-terminology.md](../spec/030-terminology.md#measurement-container) — started from the postrun image, files can be written into it and commands run, never committed
- [060-test-case-parameters.md](../spec/060-test-case-parameters.md#measurement-context) — instrument logic stays on the host, and the context's work happens in the container
- [080-docker-execution.md](../spec/080-docker-execution.md#why-commit-happens-before-measurement) — measure after commit, so first-pass measurement and backfill are the same path
- [085-test-case-results.md](../spec/085-test-case-results.md#applying-measurements) — the measurement step
- [087-collecting-token-costs.md](../spec/087-collecting-token-costs.md#backfilling-token-costs) — the harness's result file is read back from the image
- [100-cli-reference.md](../spec/100-cli-reference.md#remeasure) and [110-cli-report-visualization.md](../spec/110-cli-report-visualization.md#remeasure) — `remeasure` measures "in new measurement containers from each postrun image"
- [120-test-boundaries.md](../spec/120-test-boundaries.md#33-extracting-measurement-results-from-a-post-run-image) — layer 3.3, starting from a fixture postrun image
- [150-repository-layout.md](../spec/150-repository-layout.md#fixture-images) — the `postrun-committed` fixture image

## Artifacts

- The Docker adapter from [2800](2800_prerun-image.md) and [2900](2900_postrun-image.md) gains what a long-lived container needs. That is about `start(ref, { labels }): container`, which starts the container idling with the entrypoint overridden, and `exec(container, command, { cwd, stdin? })`. The recording adapter prints both, like the other commands.
- `createDockerMeasurementContext(docker, ref): Promise<MeasurementContext & { close() }>`. This is a Docker implementation of the `openMeasurementContext` seam from [2000](delivered/2000_first-measurement.md). It starts a container from `<repository>:<postrun tag>`, and `close()` always removes it, even when an instrument throws.
  - `workdir` is `/workspace`, and `exec` runs `sh -c` there.
  - `readFile` and `writeFile` go through `exec` (`cat`, and `cat >` with stdin).
  - `glob` lists files in the container and matches them on the host, with the same matcher as the host context. Thunderjar's runtime is never needed in the image.
  - `harnessResult` is `/thunderjar/result.json`, or `undefined` when the file is absent ([2500](2500_token-costs.md)).
- Each measurement still gets its own throwaway context, as in [2100](delivered/2100_more-instruments.md). Here that means one measurement container per measurement, so a rendered test never reaches a later `grep`. Token costs are collected through a context in the same step.
- Measurement containers carry a `thunderjar.measurement` label and the run's `postrunLabels` from 2900, so leftover containers can be found.
- The Docker measurement opener starts a container from the postrun image rather than copying its workspace to the host. Keep the runner's existing way of reading `run.json` through stdout; changing that is not required for measurement isolation. The host runner and host context remain available for lower-layer unit and context-contract tests, while command tests invoke the real CLI through recording Docker.
- `run` measures from the postrun image straight after the commit. If a measurement container can't be started, that run keeps an empty Result, the iteration line says so, the execution carries on, and `run` exits non-zero at the end. `remeasure` can then fill the Result later.
- `remeasure` from [2400](2400_remeasure.md) uses the same opener. Check image availability before starting each planned run's measurement container; report and skip an unavailable image while continuing other runs. Pulling from a registry waits for story 26. In CLI tests, configure availability in recording Docker state rather than deleting fixture artifacts.
- The fixture's `node20` base image installs a pinned Bun, because `templateTest` now runs `bun test` inside the container. This changes the base image hash and the permutation hash. As in 2800, expected hashes are regenerated deliberately in this change, and the samples keep `4f9a21c8`.
- Fixture image `thunderjar-test-fixtures:postrun-committed` is prepared from the checked-in Git scenario's `prerun-basic` by running its fake harness through the execution wrapper. It holds the committed `isPrime.ts`, `run.json` and canned usage result file. Keep the definition beside the scenario and register it in `test:prepare`; no test depends on another test's output. Restore (backlog story 24) reuses it.

```
$ thunderjar remeasure 01k4x9j2e8mqz3
Execution 01k4x9j2e8mqz3  (2 container runs)
Current measurements for task is-prime:
  isPrimeTemplateTest  new / changed (5e3c8b12)
  isPrimeTsExists      up to date
  tsIgnoreCount        up to date
  readmeExists         deleted from task; 2 stored measures kept, excluded from aggregates

Measuring in new measurement containers from each postrun image:
  4f9a21c8 i1  isPrimeTemplateTest  {passed: 4, failed: 2}
  4f9a21c8 i2  isPrimeTemplateTest  {passed: 4, failed: 2}

Updated 2 container runs. Recomputed 1 aggregation result.
The agent was not rerun.

$ docker image rm thunderjar:postrun-e01k4x9j2e8mqz3-h4f9a21c8-i2
$ thunderjar remeasure 01k4x9j2e8mqz3
…
  4f9a21c8 i2  postrun image thunderjar:postrun-e01k4x9j2e8mqz3-h4f9a21c8-i2 not found, skipped
…
```

Out of scope (story numbers are backlog positions): skipping measurement of failed or timed-out runs (story 23); pulling a missing postrun image from a registry (story 26); a configurable test runner.

**Spec gaps.**

- The spec says "a measurement container" per run. Giving each measurement its own container (2100's isolation) costs a container start per measurement, but a shared container lets one measurement's rendered files leak into the next. The spec should pick one.
- The spec says instrument logic runs on the host so that Thunderjar's runtime isn't needed in the image, but it doesn't say what the image does need. The context needs `sh`, `cat` and a way to list files, and `templateTest` needs its test runner (Bun here). This adds to the base image requirements raised in 2800.
- Nothing says whether a measurement container gets network access or the run's `requiredEnv`. This story gives it no env. Story 25 should keep API keys out of measurement containers unless the spec decides otherwise.

## How to test

Follow [the delivery testing strategy](testing-strategy.md) for fixtures, test placement, adapters and cleanup.

- A shared `MeasurementContext` contract suite runs against both the host context and the Docker context (the Docker half is in layer 3). Each implementation must give the same `glob`, `readFile`, `writeFile`, `exec` and `harnessResult` results on the same files, including an absent result file.
- CLI tests follow [the delivery testing strategy](testing-strategy.md). Invoke the real CLI against unchanged scenarios with recording Docker state and saved postrun artifacts; writable records go to an external `--data-dir`. Assert stdout, stderr, exit code, resulting records and the exact commands:
  - each iteration uses the existing execution and commit path, then a `start` / `exec` … / `rm` per measurement
  - an instrument that throws still removes its container
  - `remeasure` with a missing image issues no `start` for that run, prints the line above and exits non-zero
- Docker image tests (layer 3.3), beside the command as `*.docker.test.ts`, use real Docker and an independently prepared `postrun-committed` fixture image from a checked-in scenario. Apply the scenario's fake-harness task measurements and assert their literal values and canned token costs in the test. Afterwards, the image ID is unchanged, a fresh container has no rendered test file, and no test-owned container remains.
- The end-to-end `run` test from 2800 asserts that its measures come from containers. A separate `remeasure` case uses an unmodified copy of checked-in stale history and its saved postrun image, checks today's measurements, and proves the source store and declarations are unchanged; it does not edit a template between commands.

- `bun test`
- `bun run test:prepare && bun run test:docker`
- `bun run typecheck`

## Human interventions

None.
