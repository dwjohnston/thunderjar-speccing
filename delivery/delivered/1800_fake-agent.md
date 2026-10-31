# 1800: Fake agent

`thunderjar run <test case>` (without `--dry-run`) now runs each container run on the host. It runs the harness `cli` command in a fresh local directory, inside Thunderjar's execution wrapper, and leaves the agent's result file and `run.json` (timing, exit code) behind. A fake harness whose `cli` is a `touch`/`echo` command exercises the whole loop without Docker or a real agent.

Areas: C, F

## Spec

- [064-harness.md](../spec/064-harness.md#cli-running-the-agent) — the `cli` context, and the result file it must leave at `ctx.resultPath`
- [080-docker-execution.md](../spec/080-docker-execution.md#the-execution-wrapper) — the wrapper: timeout, timing, exit code, `run.json` shape
- [066-task.md](../spec/066-task.md#timeout) — `timeoutSeconds` comes from the initial prompt
- [120-test-boundaries.md](../spec/120-test-boundaries.md#32-generating-the-post-run-image) — the fake agent is an ordinary harness family (`fake-agent@1.0.0/fake`), not a test-only code path
- [100-cli-reference.md](../spec/100-cli-reference.md#run) — `run` human output

## Artifacts

- `thunderjar run <test case>` executes, building on the loop and execution ID from [1700](1700_dry-run.md). `--dry-run` is unchanged.
- A `ContainerRunner` seam, injected into `run`: `runContainer(run: PlannedContainerRun): Promise<ExecutionFile>`. This story adds `createHostRunner(rootDir)`. Docker replaces it in backlog story 20 without changing the loop.
- One directory per container run, named by its postrun tag. It is the host's stand-in for the postrun image, and it is kept after the run so later stories can measure it:

```
$TMPDIR/thunderjar/<execution ID>/postrun-e01k4x9j2e8mqz3-h4f9a21c8-i1/
  workspace/         # the cli's working directory; starts empty for now
  thunderjar/
    result.json      # ctx.resultPath
    run.json         # { startedAt, finishedAt, exitCode }, written by the wrapper
```

- A host execution wrapper: it runs the rendered `cli` with `sh -c`, kills it after the initial prompt's `timeoutSeconds` (exit code `124`), and writes `run.json`.
- A fake harness family in the test fixtures, `fake-agent@1.0.0/fake`, whose `cli` writes a file into the workspace and a result file to `ctx.resultPath`.

```
$ thunderjar run fake-is-prime
Execution 01k4x9j2e8mqz3 (1 permutation × 2 iterations)
Output in /tmp/thunderjar/01k4x9j2e8mqz3

Permutation 1/1  node20 | baseline | snerk | fake-agent@1.0.0/fake | plain
  iteration 1/2  postrun-e01k4x9j2e8mqz3-h4f9a21c8-i1  exit 0  0.04s
  iteration 2/2  postrun-e01k4x9j2e8mqz3-h4f9a21c8-i2  exit 0  0.03s

2 container runs: 2 exited 0
```

Out of scope (story numbers are backlog positions): applying base image, code state and prompt set (`applyParameter` is ignored until Docker in story 20); filtering the environment to `requiredEnv` (story 25); recording runs (story 11); naming outcomes such as `timedOut` (story 23). Only the exit code is recorded here.

**Spec gaps.** The spec's wrapper is a shell snippet that uses GNU `date +%s%3N` and `timeout`. Neither works on a stock macOS host, so the host wrapper should be written in TypeScript and produce the same `run.json`. The spec also doesn't say what the `cli` command's working directory is. This story assumes the workspace (`/workspace` in the container).

## How to test

CLI tests run `run` against a fixture test case that uses the fake harness. The root directory is a per-test temp dir, and the ULID generator and clock are stubbed so stdout can be asserted exactly. Cases:

- the happy path: each iteration's directory has the fake agent's file in `workspace/`, a `result.json`, and a `run.json` with `exitCode: 0`
- a `cli` that exits `3`: `run.json` records `3`, and the remaining iterations still run
- a `cli` that sleeps past a 1-second `timeoutSeconds`: it is killed, and `run.json` records `124`

- `bun test`

## Human interventions

None.
