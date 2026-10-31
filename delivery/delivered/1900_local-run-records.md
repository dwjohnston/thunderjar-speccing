# 1900: Local run records

Each container run that `thunderjar run` executes is now recorded as a `ContainerRunRecord` in a local JSON file, and `thunderjar executions` lists the executions recorded so far, newest first.

Areas: E, F

## Spec

- [085-test-case-results.md](../spec/085-test-case-results.md#what-gets-written-to-the-run-data-store) — the `ContainerRunRecord` shape
- [085-test-case-results.md](../spec/085-test-case-results.md#execution) — the `execution` field, read from `run.json`
- [050-setup-and-configure.md](../spec/050-setup-and-configure.md#thunderjarconfigts) — `runDataStore` as a small pluggable interface
- [100-cli-reference.md](../spec/100-cli-reference.md#executions) — `executions` usage and output

## Artifacts

- A `RunDataStore` interface with the two methods this story needs. Later stories add fetch and re-measure.
  - `recordContainerRun(record: ContainerRunRecord): Promise<void>`
  - `listExecutions(testCase?: string): Promise<ExecutionSummary[]>`, newest first
- `jsonFileStore(path)`, the only implementation. It defaults to `.thunderjar/.data/runs.json`, which `init` already gitignores. A missing file means an empty store. Writes should not leave a half-written file behind.
- `run` writes one record after each container run from [1800](1800_fake-agent.md), so runs that finished before a crash are kept. Fields filled now:
  - `executionId`, `testCase`, `task`, `permutationHash` (the full hash), `iteration`, `postrunImage` (the postrun tag), `ranAt`
  - `parameters` by name and hash, and `harnessModel` (the resolved pair), from [1600](1600_hashes.md)
  - `execution` with `startedAt`, `finishedAt` and `exitCode` from `run.json`
  - `result` as `{}`; measures arrive in backlog story 12
  - `tokenCosts` and `execution.outcome` stay absent until backlog stories 17 and 23
- `thunderjar executions [<test case>]` prints the execution ID, test case and date for each execution.

```
$ thunderjar run fake-is-prime
…
2 container runs: 2 exited 0
Recorded in .thunderjar/.data/runs.json

$ thunderjar executions
01k4xb7q0c2tnv  fake-is-prime      2026-09-29 15:02
01k4x9j2e8mqz3  fake-is-prime      2026-09-29 14:30
01k4w3m8r5d1ha  is-prime-baseline  2026-09-28 09:12
```

Out of scope: a configurable store. `thunderjar.config.ts` keeps no `runDataStore` entry until the shared store in backlog story 27. `report` comes in backlog story 14.

**Spec gaps.**

- `ContainerRunRecord` has no test case field, but `executions` lists and filters by test case. This story adds `testCase: string` to the record.
- The spec says v1 ships only `sqliteStore`, but the backlog keeps a JSON file until backlog story 27. If the spec stands, the switch is to a new store behind the same interface, so nothing above the store changes.

## How to test

- Store tests run against a per-test temp file:
  - a record round-trips
  - a missing file lists no executions
  - executions are grouped and listed newest first, and can be filtered by test case
- CLI tests use the fake harness, with the ULID generator and clock stubbed:
  - `run` twice, then `executions` prints both, newest first
  - each record's `execution` matches its `run.json`
  - a `cli` that exits `3` is still recorded, with `exitCode: 3`

- `bun test`

## Human interventions

None.
