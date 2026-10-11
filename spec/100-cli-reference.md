# CLI Reference

The actual CLI commands.

The first pass is scriptable only: one-shot commands, machine-readable output, exit-code
driven. Interactive mode is out of scope (see
[020-goals-non-goals.md](020-goals-non-goals.md#non-goals-v1)), so everything a person
would do in one is done with the commands below. Command names are provisional.

## Commands

| Command | Purpose |
|---|---|
| [`init`](#init) | Scaffold the configuration folder. |
| [`doctor`](#doctor) | Check that the environment is ready to run. |
| [`generate`](#generate) | Emit the typed parameter names. |
| [`plan`](#plan) | Dry run: show what a test case would do. |
| [`run`](#run) | Run a test case: one test case execution. |
| [`executions`](#executions) | List past test case executions. |
| [`show`](#show) | Show recorded results for an execution or a container run. |
| [`compare`](#compare) | Compare two executions. |
| [`remeasure`](#remeasure) | Apply the current measurements to past runs. |
| [`restore`](#restore) | Bring a container run's end state into the current repository. |

### `init`

```
thunderjar init
```

Scaffolds the `thunderjar/` configuration folder, laid out as in
[051-configuration-folder-structure.md](051-configuration-folder-structure.md). What it
creates, and whether it includes an example test case, depends on
[050-setup-and-configure.md](050-setup-and-configure.md).

### `doctor`

```
thunderjar doctor
```

A preflight for the setup described in
[050-setup-and-configure.md](050-setup-and-configure.md). It runs no test case and costs
nothing. It checks that:

- the Docker daemon is reachable;
- the registry accepts a push to the image store repository;
- every environment variable required by declared harness versions is set, and any variable
  the run data store names (e.g. `urlEnv`) is set;
- the run data store can be opened;
- the configuration loads.

Each check reports pass or fail, with the reason on failure. Exits non-zero if any fails.

### `generate`

```
thunderjar generate
```

Reads parameter names and harness family version/model maps under
`test-case-parameters/` and writes
`_generated/parameter-names.d.ts`, so a misspelled or deleted parameter is a type error in
a test case file. See [055-declaring-test-cases.md](055-declaring-test-cases.md#typed-names).

### `plan`

```
thunderjar plan <test case>
```

Example:

```
thunderjar plan is-prime-baseline
```

Shows what `run` would do, without running anything and without cost:

- the matrix shape and the permutations it produces,
- each permutation's permutation hash, with floating parameters resolved,
- which prerun images already exist and would be reused, and which would be built,
- how many container runs there would be (permutations × iterations).

### `run`

```
thunderjar run <test case>
```

Example:

```
thunderjar run is-prime-baseline
```

Runs one test case execution: resolves the matrix, then for each permutation runs each
iteration as a container run, as described in
[080-docker-execution.md](080-docker-execution.md). Prints the execution ID, which is
what the other commands take.

- **Human output:** progress per permutation and iteration, then a summary.
- **Scripted output:** `--json` prints a JSON summary. See
  [CI workflows](040-user-experience.md#ci-workflows).

Options to narrow a run (for example to a single permutation) are not settled.

### `executions`

```
thunderjar executions [<test case>]
```

Example:

```
thunderjar executions is-prime-baseline
```

Lists past test case executions, newest first: execution ID, test case, date. Exists so
there are IDs to give to `show`, `compare`, `remeasure` and `restore`.

### `show`

```
thunderjar show <execution | container run>
```

Example:

```
thunderjar show 01K4X9J2E8MQZ3V7R5T0WABCDE
thunderjar show postrun-e01K4X9J2E8MQZ3V7R5T0WABCDE-h4f9a21c8-i00
```

Displays recorded results from the run data store. What it shows depends on the ID it is
given:

- **An execution** shows one [aggregation result](030-terminology.md#aggregation-result)
  per permutation: the combined measures across its iterations.
- **A container run** shows that one iteration: its parameters, measures, cost, tokens
  and duration.

A test case name can stand in for an execution ID, meaning its latest execution.
Supports `--json`.

### `compare`

```
thunderjar compare <execution-a> <execution-b>
```

Example:

```
thunderjar compare 01K4X9J2E8MQZ3V7R5T0WABCDE 01K5A2B7C9D4F6G8H0JKMNPQRS
```

Compares two executions' aggregation results. It reports differences and makes no
judgement about them: Thunderjar has no notion of a regression (see
[020-goals-non-goals.md](020-goals-non-goals.md#non-goals-v1)). Example output is in
[110-cli-report-visualization.md](110-cli-report-visualization.md#compare). Supports
`--json`.

### `remeasure`

```
thunderjar remeasure <test case | execution>
```

Example:

```
thunderjar remeasure is-prime-baseline
thunderjar remeasure 01K4X9J2E8MQZ3V7R5T0WABCDE
```

Applies the measurements that currently exist on the filesystem to past container runs,
without rerunning the agent. Each run is measured in a new
[measurement container](030-terminology.md#measurement-container) started from its
postrun image, and the new measures are added to its recorded
[result](085-test-case-results.md#the-result-record). This is the same path as the
original measurement, not a separate one.

- **An execution** remeasures exactly the container runs in it.
- **A test case** remeasures every past execution of it.

### `restore`

```
thunderjar restore <container run>
```

Example:

```
thunderjar restore postrun-e01K4X9J2E8MQZ3V7R5T0WABCDE-h4f9a21c8-i00
```

Run from inside a git repository. Fetches the run's end state and creates the branch
`thunderjar/<container run>`, leaving the working tree untouched. Specified in full in
[090-restore-purge.md](090-restore-purge.md#restore).

## Conventions

- `--json` on every command that reports, for scripting.
- Exit codes: success, and infrastructure error are
  distinct.
- Executions are addressed by execution ID and container runs by their ID.

## Out of scope for the first pass

- **Interactive mode / TUI.** See
  [020-goals-non-goals.md](020-goals-non-goals.md#non-goals-v1).
- **`build`**, building and pushing prerun images without running the harness. Likely to
  become useful for testing Thunderjar itself.
- **`list`** for declared test cases, parameters and tasks. These are files in the
  configuration folder.
- **`purge`.** See [090-restore-purge.md](090-restore-purge.md#purge).

