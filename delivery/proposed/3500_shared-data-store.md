# 3500: Shared data store

`runDataStore` can now be set in `thunderjar.config.ts`. With `postgresStore({ urlEnv: "THUNDERJAR_DB_URL" })`, CI and every developer's machine record to and read from one database. A developer can run `executions`, `show`, `compare` and `remeasure` on CI's runs, then `restore` one, which completes the regression triage loop. The local default becomes the spec's `sqliteStore`, which replaces 1900's JSON file. This is backlog story 27.

Areas: E, F

## Spec

- [071-data-persistence.md](../../spec/071-data-persistence.md) — the open question this story settles, by shipping a remote store
- [050-setup-and-configure.md](../../spec/050-setup-and-configure.md#thunderjarconfigts) — `runDataStore`, `sqliteStore` and `postgresStore({ urlEnv })`
- [050-setup-and-configure.md](../../spec/050-setup-and-configure.md#authentication) — the connection URL is read from the named variable by the host process only, and never written anywhere
- [100-cli-reference.md](../../spec/100-cli-reference.md#doctor) — `doctor` checks that `urlEnv` is set and that the store opens
- [040-user-experience.md](../../spec/040-user-experience.md#regression-triage) — the CI-to-developer hand-off this story enables
- [140-tooling.md](../../spec/140-tooling.md) — `bun:sqlite`. Bun's built-in Postgres client (`Bun.sql`) keeps the remote store dependency-free too.

## Artifacts

- **Decision: ship a remote store in v1.** Of 071's options, only a real database handles CI jobs and developers writing at once. The spec has already designed its config and authentication, and Bun includes a Postgres client. Passing the file around stays possible with `sqliteStore`, but nothing automates it.
- `declareConfig` accepts `runDataStore`, which is optional. The default is `sqliteStore({ path: ".thunderjar/.data/runs.sqlite" })`, and relative paths resolve from the project root, as in [2600](../2600_floating-parameters.md). `init` scaffolds the sqlite line, plus a commented-out `postgresStore` line. Because the config is TypeScript, a project can choose the store by environment.
- `sqliteStore({ path })` and `postgresStore({ urlEnv })` both implement the whole `RunDataStore` interface built up since [1900](../delivered/1900_local-run-records.md) (`recordContainerRun`, `listExecutions`, `getExecution`, `getContainerRun`, `recordMeasures`, `recordTokenCosts`, `recordAggregationResult`, `getAggregationResults`). Nothing above the store changes. `jsonFileStore` is removed, and an existing `runs.json` is not migrated.
- **One schema for both stores**: a few indexed columns (`executionId`, `testCase`, `permutationHash`, `iteration`, `postrunImage`, `ranAt`) plus the record as JSON, an aggregation results table and a `schema_version` table. Tables are created on first open. A database with a newer schema version is refused with "upgrade thunderjar". `postrunImage` is unique, so recording the same tag twice is an error.
- **Concurrent writers.** `recordMeasures` and `recordTokenCosts` merge inside a transaction, so two machines that remeasure different measurements of one run both keep their values. Recomputing an aggregation result reads the records and writes the result in one transaction.
- **Credentials.** `postgresStore` reads the URL from `process.env[urlEnv]` when it opens, never at config load. Validation ([1400](../delivered/1400_validation.md)) rejects a `urlEnv` that looks like a URL rather than a variable name. `redactUrl(url)` replaces the password with `***` in every message and in `doctor`. The URL never reaches a container, a record or the recording adapter.
- **Failing early.** Every command that opens the store fails first when `urlEnv` is unset or the database can't be reached. `run` opens the store before it builds anything, so a run can't execute and then have nowhere to record. If a write fails mid-execution, the execution stops with a non-zero exit, and the message names the postrun tag whose record is missing.
- `doctor`'s run data store check (from [3300](3300_real-harness.md)) reports the variable, the redacted URL and the schema version. It warns when the store is shared but `imageStore` isn't set ([3400](3400_registry.md)), because other machines then get records whose images they can't pull.
- `run`'s closing line names the store: `Recorded in .thunderjar/.data/runs.sqlite` or `Recorded in postgres://thunderjar:***@db.acme.internal/thunderjar`.

```
# thunderjar.config.ts
runDataStore: postgresStore({ urlEnv: "THUNDERJAR_DB_URL" }),

$ thunderjar doctor                       # developer's machine
…
✓ run data store   THUNDERJAR_DB_URL → postgres://thunderjar:***@db.acme.internal/thunderjar opens (schema 1)

$ thunderjar executions fake-is-prime
01k4xm6t9b3zq5  fake-is-prime      2026-10-02 03:00     # recorded by CI
01k4xg2p6s9wc4  fake-is-prime      2026-10-01 11:47

$ thunderjar show 01k4xm6t9b3zq5
…
$ thunderjar restore postrun-e01k4xm6t9b3zq5-h4f9a21c8-i1
Pulled ghcr.io/acme/thunderjar-images:postrun-e01k4xm6t9b3zq5-h4f9a21c8-i1 (2.4s)
…

$ unset THUNDERJAR_DB_URL; thunderjar run fake-is-prime
error: THUNDERJAR_DB_URL is not set (runDataStore)
Nothing was built.
```

Out of scope (story numbers are backlog positions): migrating `runs.json`, or copying local runs into the shared store; schema migrations beyond version 1; other remote backends and IAM-token auth; removing records along with images (story 28); `--json` and CI wiring (story 29).

**Spec gaps.**

- 050 says v1 ships only `sqliteStore` and that `postgresStore` comes later. 071's open question should be closed in favour of shipping both, and 050 updated.
- 050 doesn't say what `sqliteStore`'s relative `path` is relative to. This story uses the project root.
- A record doesn't say where it ran. Once CI and developers share a store, `executions` mixes their runs, and triage starts from "the run CI recorded". A `ranBy` (or `ci: boolean`) field on `ContainerRunRecord` would help.
- No page says whether a developer's local runs belong in the shared store. This story leaves that to the user's config.

## How to test

Follow [the delivery testing strategy](../testing-strategy.md) for fixtures, test placement, adapters and cleanup.

- Unit tests (layer 1): config validation of `runDataStore` and `urlEnv`, default path resolution, and `redactUrl`.
- **One store contract suite**, run against each implementation. It covers every interface method, with the cases already in the store tests from 1900–3400: round-trip, newest-first listing, test case filter, merge by name, overwrite of aggregation results, and so on. It also covers an empty store, the duplicate tag error, refusing a newer schema, and two concurrent `recordMeasures` calls on one run that both survive.
  - `sqliteStore` runs it against a per-test temp file, in `bun test`.
  - `postgresStore` runs it against a throwaway `postgres` container on a random `localhost` port, labelled and removed by the test, in `test:docker`. `test:prepare` pulls the image.
- CLI tests follow [the delivery testing strategy](../testing-strategy.md). Invoke the real CLI against unchanged scenarios whose checked-in config selects the store, using an external `--data-dir` for writable local data. Check in SQLite history snapshots or source records needed for historical cases; copy or load them unchanged into isolated stores without editing records in setup. Assert stdout, stderr, exit code and stored data. Cover an unset `urlEnv` failing before any Docker command and credentials absent from output.
- Layer 3 tests live beside their command as `*.docker.test.ts`, with real Postgres and registry services and fake agents. Two CLI invocations against unchanged scenarios select the same isolated database through environment configuration: `run` records there, then `executions`, `show` and `remeasure` see it. Do not copy or patch project declarations. Use a unique database/schema and image prefix, and remove all test-owned services, records, images and directories.

- `bun test`
- `bun run test:prepare && bun run test:docker`
- `bun run typecheck`

## Human interventions

- 👷‍♂️ Provision a Postgres database and a user for Thunderjar, reachable from CI and from developers' machines.
- 👷‍♂️ Add `THUNDERJAR_DB_URL` as a CI secret, and export it locally.
- 👷‍♂️ Run `fake-is-prime` from CI (or a second machine), then check that `executions` and `show` on your own machine list it.
