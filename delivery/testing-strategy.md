# Testing delivery stories

Every open and proposed delivery story follows the implementation repository's
[AGENTS.md](../../thunderjar/AGENTS.md),
[source layout](../../thunderjar/src/AGENTS.md), and
[fixture rules](../../thunderjar/fixtureTests/AGENTS.md).
Use those rules for test placement, fixtures and adapters; the older layouts in
spec/120 and spec/150 are not implementation instructions.

## Command tests

- Invoke the real CLI with `scenario()` and `thunderjar()` from `src/testing/cli.ts`.
  Tests live beside their command, such as `src/commands/remeasure/remeasure.test.ts`.
  Use the production path with the recording Docker binary; don't inject a host runner
  or add a test-only command mode.
- Run against a checked-in `fixtureTests/scenario_<n>_<project>/fixtures/`, unchanged.
  Reuse an existing scenario or check in a new project state. Never generate declarations
  or edit a scenario during a test. Scenarios hold starting state, not expected output.
  Update `fixtureTests/AGENTS.md` when adding a scenario or changing its behavior.
- `plan`, `show`, `executions`, `compare`, `doctor` and dry runs read scenarios in place.
  `init` works on `copyOfFixtures()`. A real `run` uses an external `--data-dir` and a
  scenario without historical records. `remeasure` uses an external `--data-dir` seeded
  with an exact, unmodified copy of the scenario's checked-in store. After 3500, use an
  equivalent unchanged SQLite snapshot or load the checked-in records into an isolated
  store. Never rewrite historical records in test setup to manufacture a case.
  `generate` runs in place and writes only gitignored generated types, removed after
  the test.
- Historical comparisons, changed collectors, stale measurements and moved parameters
  belong in checked-in records alongside today's declarations and saved artifacts.
  Test a new execution against that history without editing the project between commands.
- Configure adapter state for image availability, saved files and failures. Keep saved
  artifacts unchanged; an unavailable image is an omitted adapter mapping. Extend the
  recording adapter when needed, rather than inventing a separate execution path.
- Assert stdout, stderr, exit code and produced files, records or images. Expected
  values live in tests. Normalize only variable execution IDs, temporary paths, random
  container names and timings; keep recorded IDs and content hashes exact.
  Story output samples illustrate the report shape; use the chosen scenario's real
  hashes, full recorded IDs and current zero-based `i00`, `i01` tags in assertions.
- Remove writable stores and adapter state, and verify checked-in stores and artifacts
  are unchanged. Commands that create repository refs, such as `restore`, use a disposable
  Git target cloned from checked-in history; they never change the workspace repository.

For example, this runs against scenario 8's unchanged project. The external data
directory must already contain an unchanged copy of its `runs.json`; real use needs
the postrun images, while a CLI test supplies the recording adapter's saved files.

```sh
bun run fixture 8 remeasure fails --data-dir /tmp/thunderjar-history
```

## Units, Docker and real agents

- Keep pure-function and context-contract tests beside their modules. Inject failures
  that the CLI cannot trigger there; command acceptance criteria still use the CLI.
- Deterministic fixtures and unit tests use `fake-harness-alpha`, `fake-harness-beta`,
  `fake-model-small` and `fake-model-large`, with fake model IDs. Canned usage payloads
  may exercise realistic formats but contain no real harness or model identities.
  `init` and its command tests may name the real agent they scaffold.
- Real Docker tests use fake agents, live beside the command as `*.docker.test.ts`, and
  run only under `bun run test:docker`. Work from unchanged scenarios, use external
  writable stores and throwaway image prefixes, and clean up all test-owned containers,
  images and temporary directories. Build required fixture images through `test:prepare`
  from checked-in scenario artifacts; never depend on another test's output.
- A real-agent smoke test is separate from both `bun test` and `test:docker`. It uses
  a disposable project created by the real `init` command, requires explicit credentials,
  checks result shape rather than fixed measurements, and cleans up its artifacts.

Implementation deliveries finish with `bun run typecheck`, `bun run lint` and
`bun test`. Docker behavior also requires `bun run test:prepare && bun run test:docker`.
