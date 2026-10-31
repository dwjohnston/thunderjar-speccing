# Advice for story makers

Notes left by previous loop iterations. Add to this as you go.

## Where things are

- The ordered backlog is [0100_agile-delivery-stories.md](0100_agile-delivery-stories.md). Work through it in order.
- `delivery/delivered/` holds finished stories; `delivery/*.md` (top level) holds stories ready or in progress; `delivery/proposed/` is where new stories go. Accepted stories move from `proposed/` to the top level, so check all three places before picking the next bullet.
- Numbering: backlog story N becomes roughly `N × 100 + 800` (story 9 → 1700, story 10 → 1800). Leave gaps (e.g. 1125) for stories inserted later.

## Story shape (copy the delivered ones)

Headings: one-line summary paragraph, `Areas:` (letters from [0000_high-level-groupings.md](0000_high-level-groupings.md)), `## Spec` (links with an em-dash reason), `## Artifacts`, `## How to test`, `## Human interventions`.

- Keep it short. The first paragraph is a user-visible outcome, usually a CLI command and what it prints.
- A sample CLI output block is the most useful single thing in a story.
- Build on earlier stories by linking them (`building on [1500](1500_permutations.md)`) rather than repeating them.
- Write links as if the story sits in `delivery/` (where it moves once accepted): `../spec/060-….md` for spec, `1500_permutations.md` for other stories. The existing stories do the same.

## Decisions taken so far

- **1700 Dry run** uses `run --dry-run` rather than a dry-only `run`, so the flag survives once 1800 makes `run` execute. The spec does not define `--dry-run`; it overlaps with `plan`, but adds the per-iteration walk, the execution ID and the rendered harness command.
- Stub the ULID generator (and, from 1800, the clock) in tests so CLI output is deterministic.
- **1800 Fake agent** introduces a `ContainerRunner` seam (`createHostRunner(rootDir)`); Docker (story 20) swaps in a Docker runner behind it. Each container run gets a kept host directory `$TMPDIR/thunderjar/<execution ID>/<postrun tag>/` with `workspace/` (the `cli`'s cwd, the stand-in for the postrun image's `/workspace`) and `thunderjar/result.json` + `thunderjar/run.json`. Stories 11–16 should measure and record against that directory.
- 1800 records only `exitCode`. Naming outcomes (`completed`/`failed`/`timedOut`) and skipping measurement on failure are left to story 23. `applyParameter` (base image, code state, prompt set) is ignored on the host, so the workspace starts empty; `requiredEnv` filtering waits for story 25.
- The fake harness is an ordinary family, `fake-agent@1.0.0/fake`, in the test fixtures ([120](../../spec/120-test-boundaries.md)). Reuse it in later stories.
- **1900 Local run records** adds `RunDataStore` (`recordContainerRun`, `listExecutions`) with one implementation, `jsonFileStore(path)`, at `.thunderjar/.data/runs.json`. 3500 replaces it with `sqliteStore`/`postgresStore`. Later stories add store methods as they need them (fetch a run's results, add measures).
- 1900 writes one record per container run, straight after the run. `result` is `{}`, and `tokenCosts` and `execution.outcome` are absent: stories 12, 17 and 23 fill them. Story 12 should add measures to the existing record rather than hold back the write.
- 1900 adds `testCase` to `ContainerRunRecord` (spec gap: `executions` filters by test case, but the record has no such field). It also adds the spec's `thunderjar executions [<test case>]`.
- **2000 First measurement** adds `declareMeasurement` (with `aggregate` required but unused until story 15), `hashMeasurement` (instrument + config only), and the `fileCreated` instrument (`{ glob }` → `boolean`). Its second seam, `openMeasurementContext(postrunTag)`, has a host version over the kept run directory, and 3000 adds the Docker version. It also adds `measureContainerRun(measurements, ctx): Result` and the store method `recordMeasures(postrunImage, measures)`, which merges by name and overwrites. Story 16 (backfill) should reuse all of these rather than add a parallel path. `run` prints the measures indented under each iteration line.
- 2000 still measures runs that exit non-zero. 3100 adds the skip. `erroredWhileMeasuring` is stored as `{ message }`, because `Error` doesn't survive JSON.
- **2100 More instruments** decisions:
  - `grep` is `{ glob, pattern }` → `number`. `pattern` is a JS regex, the value is a line count, and it is `skipped` when the glob matches nothing.
  - `templateTest` is `{ subject, template }` → `{ passed, failed }`. It runs `bun test` through `ctx.exec` and sums counts over multiple subject matches. The test runner is not configurable yet.
  - Bundled files: each instrument names its file-valued config keys, and `hashMeasurement` hashes those files (paths relative to the measurement file). Unreferenced sibling files aren't hashed.
  - Each measurement gets its **own throwaway context**. The host version uses a scratch copy of `workspace/`, so rendered tests never pollute the kept run directory or a later `grep`. 3000 keeps that isolation with one container per measurement.
- Fixture state after 2100: the fake agent writes a buggy `isPrime.ts` containing one `@ts-ignore`. The `fake-is-prime` task has four measurements: `isPrimeTemplateTest` ({4,1}), `isPrimeTsExists` (true), `readmeExists` (false) and `tsIgnoreCount` (1). Reuse these in sample output for report and aggregation.
- `run` prints measures sorted by name, with values like `true`, `1`, `{passed: 4, failed: 1}` (the format [110](../../spec/110-cli-report-visualization.md) uses). Stories 14/15 should stay consistent with it.
- **2200 Show** decisions:
  - The backlog's "report" is the spec's `show`; there is no `report` command. Read "report" in backlog stories 15, 17, 18 and 19 as `show` (or `compare` for 19).
  - `show <test case | execution | container run>` resolves the argument as postrun tag, then execution ID, then test case (latest execution).
  - The container run view prints values as `skipped`, `error` or `—` (not measured). 2200's per-iteration execution table was replaced by 2300.
  - Store read methods: `getExecution(executionId)` (permutation, then iteration order) and `getContainerRun(postrunImage)`.
  - Deferred: cost/tokens to 17, `--json` to 29.
  - The fixture's `fake-is-prime` test case uses the task `is-prime`.

- **2300 Aggregation** decisions:
  - Pure `aggregateMeasure(values, methods)` and `aggregatePermutation(records, measurements): AggregationResult` → `{ executionId, permutationHash, iterations, measures, duration: { mean, max } }`, each measure `{ measured, ...methods }`. Story 17 adds cost/tokens to it, and 2700 adds a per-measure `contentHash`.
  - Missing values (`skipped`, errored, absent) are excluded, and `measured` counts what was combined. Nothing measured gives `{ measured: 0 }`. Only currently declared measurements are aggregated. Stale measures still count (2400 only marks them).
  - Stored via `recordAggregationResult` (overwrites by execution + permutation) and `getAggregationResults(executionId)`, in the same JSON file. `run` recomputes after each `recordMeasures`.
  - `show <execution>` prints `MEASURE / MEASURED / AGGREGATE`, then `exit  2/2 exited 0` and `duration  mean …, max …`. Per-iteration values are only in `show <container run>`.
  - Fixture `aggregate`s: `isPrimeTemplateTest ["sum"]`, `isPrimeTsExists ["rate"]`, `readmeExists ["rate"]`, `tsIgnoreCount ["mean","max"]`. Over 2 iterations they give `sum {passed: 8, failed: 2}`, `rate 1.00`, `rate 0.00`, `mean 1.0, max 1`.

- **2400 Remeasure** decisions:
  - Backlog story 16's `measure` is the spec's `remeasure <test case | execution>`. It resolves the argument like `show` does: execution ID first, then test case, which means all of that test case's executions.
  - Pure `measureStatus(recorded, measurement)` returns `missing | stale | current`, and `planRemeasure(records, measurements)` lists the work. Measuring reuses `openMeasurementContext` → `measureContainerRun` (with a subset of measurements) → `recordMeasures`. No new store methods.
  - `erroredWhileMeasuring` counts as missing, so it is retried. `skipped` counts as current. There is no force flag.
  - `remeasure` recomputes every aggregation result of its executions, even when nothing needed measuring, so an edited `aggregate` or a deleted measurement is picked up.
  - A missing kept run directory is reported and skipped, and the command exits non-zero. 3000 turns this into a missing postrun image.
  - `show` marks stale measures: ``stale, run `remeasure` `` in the execution view and `(stale)` in the container run view.
  - Fixture scenario: edit the `isPrimeTemplateTest` template (new hash `5e3c8b12`, value `{passed: 4, failed: 2}`) and delete `readmeExists.ts`. The second execution ID is `01k4xc5w7r1ta6`.

- **2500 Token costs** decisions:
  - `declareTokenCostCollector` is added, and `collectTokenCosts.ts` is required in each family (a missing file fails validation). The wrapper `collectTokenCosts(collector, raw | undefined, ctx)` maps no file to `absent`, and a throw or malformed return to `unparseable`.
  - Collection happens in the measuring step. It reads the raw file from the `MeasurementContext` (`harnessResult` may be `undefined`) and `{ version, modelId }` from the record's `harnessModel`. It is stored via `recordTokenCosts(postrunImage, …)` as `{ ...TokenCosts, collectorHash, collectedAt }`.
  - `collectorHash` (a spec addition) is what makes the costs stale. `remeasure` re-collects when the costs are missing or the hash differs, and never retries when the hash matches.
  - `AggregationResult.tokenCosts` = `{ collected, inputTokens, outputTokens, cacheCreationTokens, cacheReadTokens, byModel, costUsd?: { total, perIteration } }`. Unavailable runs are excluded. A run has a cost only if every model reported `costUsd`. 2700 reads `costUsd.perIteration`.
  - Display: `run` adds `$0.004` to each iteration line and `total cost` to the summary. `show <execution>` prints `cost` and `tokens` lines before `exit`/`duration`, plus `(n/m collected)` when some are missing. `show <container run>` prints `Cost`, and `Tokens in/out/cache write, read` per model. `in` is plain `inputTokens`.
  - Fixtures: a test-only `claude-code` family whose collector is tested against canned Claude Code files. The fake agent copies a Claude-Code-shaped file and reuses that parser through a helper outside the family folders. Per iteration that is `fake-model`, in 1,200, out 340, `$0.0042`. Two iterations give `$0.008 total, $0.004 / iteration` and `in 2,400 out 680`.
  - 3100 settled whether failed runs' token costs are collected (they are), and 3300 settled whether Thunderjar ships a `claude-code` collector (`init` scaffolds it).

- **2600 Floating parameters** decisions:
  - It covers `additionalHash` as well as `determineHash`, since both resolve the same way. `resolveHashCommands(selected, runCommand)` runs each distinct command once per execution (and on `plan` / `--dry-run`), from the **project root** (the parent of `.thunderjar/`). A non-zero exit or empty output stops the execution before anything runs.
  - `ContainerRunRecord.parameters[kind].resolved?` (a spec addition) stores the resolved value. A floating harness keeps its entry name (`fake-agent@latest/fake`), and `harnessModel.version` holds the resolved version.
  - Display: `main @ 3c1d9e2 (…, floating, resolved now)` in `plan`, and `main @ 7a0f4b1` in `show`. `show <execution>` prints a `Moved since <previous execution>` block when a floating value differs from the test case's previous execution. 2700 keeps the block and uses `resolved` in `compare`.
  - `ctx.resolvedHash` reaches `applyParameter` and `commit` but is unused until story 20, which must check out the resolved commit.
  - Fixtures: code state `main` (`cat fixture-heads/main.txt`), version entry `fake-agent@latest` (`harness-versions/fake-agent.txt` → `1.0.0`), and test case `fake-is-prime-main`. Sample values: `3c1d9e2` → `7a0f4b1`, permutation `b41d06f2`.

- **2700 Compare** decisions:
  - `compare <a> <b>` resolves each argument like `show` does. It always exits 0 when it compares (no regression notion). It errors on an unknown ID, or when A and B ran different tasks.
  - The CHANGE column is a signed difference only, with no `better`/`worse` (spec 110 conflicts with 020). There is one difference per method and per record key, `=` when all are zero, and values use `show`'s format.
  - Each `AggregationResult` measure gains `contentHash`: the hash of its stored values, or `"mixed"`. A measure is comparable only when name and hash match on both sides. `measurementSetHash` is derived from it.
  - Pure `diffParameters`, `pairPermutations` (by hash, then by the unchanged kinds, with ambiguous ones left unpaired) and `compareMeasures`. Story 29's `--json` should serialise these.
  - 2600's `Moved since` block stays, plus a `Compare with:` hint.
  - Sample IDs: the earlier `fake-is-prime-main` permutation is `6c2e90d4`, and `main @ 7a0f4b1` hashes `c5d93a10`. The same-hash sample uses `fake-is-prime` executions `01k4xf8n3d0vb2` / `01k4xg2p6s9wc4`, with the old template hash `d91f6a07`.

- **2800 Prerun image** decisions (first Docker story):
  - Pure `renderPrerunDockerfile(permutation, resolved)` and `assembleBuildContext(…)`. The build context is kept at `$TMPDIR/thunderjar/<execution ID>/prerun-h<hash>/`. `checkCommits` runs before any build, and only for images that don't exist yet.
  - A Docker adapter (`src/adapters/docker/`) has a real implementation and a recording one: `imageExists`, `build`, `run`, `copyOut`, `removeContainer`. Later Docker stories should add methods (`commit`, `tag`, `push`) to it rather than create new seams.
  - `ContainerRunner` gains `preparePermutation` (a no-op on the host). `createDockerRunner` runs the spec's shell wrapper in a container, then **copies `/workspace` and `/thunderjar` out into the kept run directory** and removes the container. 2900 adds the commit, and 3000 drops the copy-out except for `run.json`.
  - `run` uses the Docker runner. The host runner stays as the seam injected by the measurement-focused CLI tests.
  - Images go in a local repository, `thunderjar:prerun-h…`, which is injectable for tests. Story 26 swaps in `imageStore.repository` and adds push/pull.
  - `plan` and `run --dry-run` print `prerun-h… (exists, reused)` / `(will build)`. `run` prints `prerun image   thunderjar:prerun-h4f9a21c8  built (14.2s)` or `reused` above the iterations.
  - Fixtures: the fixture project is a throwaway repository seeded by `seed-repo.sh` (spec 150), so commits are real and stable. The fake agent's script is at `test/fixtures/harnesses/fake-agent.js`, shipped in the fixture image `thunderjar-test-fixtures:harness-fake-agent` and installed with `COPY --from`. `bun run test:prepare` builds the fixture images, and `bun run test:docker` runs layer 3.
  - Spec gaps raised: what a base image must provide (git, GNU `date`/`timeout`), and how a harness family gets files into the build context.

- **2900 Postrun image** decisions:
  - The adapter gains `commit(container, ref, { labels, changes })`. Each iteration runs `run` → `commit` → `cp` → `rm`. 3000 drops the copy-out. A failed commit stops the execution and leaves the container in place.
  - Failed and timed-out runs are committed too (spec 080).
  - The commit resets `CMD`/`WORKDIR` to the prerun image's, and the image `Env` must equal the prerun image's. **Story 25 must not pass `requiredEnv` in a way that `docker commit` saves** (for example, `-e`), or API keys end up in images that story 26 pushes.
  - Pure `postrunLabels(record)`: `thunderjar.execution-id`, `thunderjar.permutation-hash` (full), `thunderjar.iteration`, `thunderjar.test-case`. This is a spec addition, since 120 asserts labels that no page defines.
  - `postrunImage` in the record stays the bare tag. The ref is `<repository>:<tag>`.
  - The fake agent now commits its change when `/workspace` is a git repo (fixed author and date, sample `3e7a9c2 Add isPrime` on top of `a1b2c3d Baseline`). Restore (3200) relies on that history.
  - Adds the fixture image `thunderjar-test-fixtures:prerun-basic` (spec 150), which layer 3.2 starts from.
  - `run` ends with `Committed 2 postrun images to thunderjar.`

- **3000 Measurement container** decisions:
  - `createDockerMeasurementContext(docker, ref)` implements `openMeasurementContext` with a container from the postrun image, plus `close()`, which always removes it. `workdir` is `/workspace`. `readFile`/`writeFile` go through `exec`, and `glob` lists files in the container and matches them on the host. The adapter gains `start(ref, { labels })` and `exec(container, command, { cwd, stdin? })`.
  - **One measurement container per measurement** (2100's isolation). Token costs are collected through a context in the same step. Containers carry a `thunderjar.measurement` label plus `postrunLabels`. No env is passed, and story 25 should keep API keys out of them.
  - Iteration commands are now `run` → `commit` → `cp /thunderjar/run.json` → `rm`, then `start`/`exec`/`rm` per measurement. The Docker runner no longer writes `workspace/` to the kept run directory. The host runner and host context stay for the measurement-focused CLI tests, and a shared contract suite checks that the two contexts agree.
  - If a measurement container won't start, the run keeps an empty Result and `run` exits non-zero at the end. `remeasure` checks `imageExists` for each run. A missing image prints `postrun image … not found, skipped` and the command exits non-zero. Story 26 adds pulling.
  - The fixture's `node20` base image installs a pinned Bun, for `templateTest` in the container. Samples keep `4f9a21c8`.
  - Adds the fixture `thunderjar-test-fixtures:postrun-committed`, built from `prerun-basic` by running the fake agent. Layers 3.3 and 3.4 (restore, 3200) use it.

- **3100 Failure handling** decisions:
  - Pure `outcomeOf(exitCode)`, stored as `execution.outcome`. Older records without it are derived on read, so no migration is needed.
  - Runs that aren't `completed` get no measurement containers and keep Result `{}`. **Their token costs are still collected**, through one context opened only for that. This settles 2500's open question and conflicts with 080's "no measurement container is started", which is raised as a spec gap.
  - A failed agent is not an error, so `run` exits 0. Infrastructure failures keep stopping the run with a non-zero exit. Their spec-style output and exit codes are left to story 29.
  - `AggregationResult.outcomes = { completed, failed, timedOut }`. Measures combine completed runs only, while cost and duration cover all runs. Whether a failed run counts as `false` in a `rate` is still open (020).
  - Display: the iteration line shows `completed` / `failed (exit 3)` / `timedOut` in place of `exit 0`, with `not measured` under it. The summary is `4 container runs: 2 failed, 2 timedOut`. In `show <execution>`, an `outcome  0/2 completed, 2 timedOut` line replaces `exit`. `show <container run>` prints `Duration  1.00s   timedOut (exit code 124)`, and `compare` adds a `completed` row.
  - `planRemeasure` skips measuring non-completed runs but still re-collects their stale costs.
  - Fixtures: the `is-prime` initial prompts gain `fails` (the agent writes its result file, then exits 3) and `hangs` (it sleeps past `timeoutSeconds: 1`, with no result file). Test case `fake-is-prime-failures`, execution `01k4xh7q2m5tr8`, permutations `8d3e5b70` (fails) and `2a6f14c9` (hangs).

- **3200 Restore** decisions:
  - Restore reads the **image, not the run data store**. `postrunLabels` gains `thunderjar.code-state-commit` (the full resolved SHA), which marks where the agent's commits start. Images without the label are refused. Story 26 only needs to pull the image before restoring.
  - The adapter gains `imageLabels(ref)`. `restoreContainerRun(docker, repoDir, tag)` starts a throwaway container (label `thunderjar.restore`), makes the Thunderjar commit there if the tree is dirty, bundles `<base>..HEAD`, copies it out, and always removes the container. Then it fetches the bundle into the developer's repository as `thunderjar/<tag>` without checking it out.
  - Thunderjar commit: `git add -A` (ignored files excluded), author and committer `Thunderjar`, the message names the run, and the date is the run's end time from `run.json`, so the SHA is stable.
  - Two errors beyond 090's three: the label is missing, and the base commit isn't in the repository. All checks run before anything changes.
  - `show <container run>` ends with `Restore with: thunderjar restore <tag>`, failed runs included.
  - Adds the fixture `postrun-uncommitted`. Both postrun fixtures carry the label (`a1b2c3d`).

- **3300 Real harness** decisions:
  - `requiredEnvFor(pair)` and `checkRequiredEnv(permutations, env)`. `plan`, `run` and `--dry-run` fail before anything else, and only the selected pairs count.
  - Credentials are passed **by name only** (`-e NAME`) to the iteration container, in a way `docker commit` doesn't save (for example, `docker exec -e` into an idle container). Layer 3.2 asserts that the postrun image's `Config.Env` and history don't contain them. No env goes to builds, measurement containers or restore. The host runner passes `requiredEnv` plus `PATH`/`HOME`.
  - `doctor`: config, Docker (`ping()`), env for every declared version, and the run data store. Registry is `skipped` until story 26, which should turn it into a real push check.
  - The `claude-code` family (with 2500's collector) is **scaffolded by `init`** as user-owned files, not shipped in the package. `init`'s example selects `claude-code@<pinned>/haiku-4-5`. `shellQuote` is exported for `cli` fragments.
  - Fixtures: `fake-agent@1.1.0` requires `FAKE_AGENT_TOKEN` (test case `fake-is-prime-token`), and the existing fake hashes are unchanged. `claude-is-prime` (permutation `e3b7c051`, execution `01k4xk3r8v6pq2`) is smoke-only.
  - `bun run test:smoke` needs `ANTHROPIC_API_KEY`, skips without it, and asserts shape, not values. Running it in CI is left to story 29.

- **3400 Registry** decisions:
  - `imageStore: { repository }` is **optional**. Without it, images stay in the local `thunderjar` repository, and nothing is pushed or pulled (layer 2 tests and `init`'s example stay offline). With it, the repository replaces `thunderjar` in every ref, locally too.
  - The adapter gains `push`, `pull` (`pulled | notFound`, and auth or network failures are errors) and `remoteImageExists`. `resolvePrerunImage` returns `local | remote | missing`, and `checkCommits` runs only for `missing`.
  - An iteration is `run` → `commit` → `push` → `cp run.json` → `rm`, then measurement. A failed push records the run, keeps the image locally and stops the execution with a non-zero exit.
  - `ContainerRunRecord.imageRepository` (a spec addition) is used by `remeasure` and the `Restore with:` hint. Records without it read as `thunderjar`. `restore` uses the configured repository: local first, then pull.
  - `doctor` pushes a probe tag, `<repository>:doctor-probe`. **Story 28 (purge) must leave it alone**, along with anything that isn't `prerun-`/`postrun-`. Pulled images stay local until story 28.
  - Layer 3 uses a throwaway `registry:2` container on a random `localhost` port, and `test:prepare` pulls it. Sample execution `01k4xm6t9b3zq5`, repository `ghcr.io/acme/thunderjar-images`.
  - Open: records keep tags, not digests, so concurrent prerun pushes overwrite each other.

- **3500 Shared data store** decisions:
  - Settles 071 by **shipping `postgresStore({ urlEnv })` in v1** (via `Bun.sql`), alongside `sqliteStore({ path })`, which replaces `jsonFileStore`. `runDataStore` is optional in the config, and the default is `sqliteStore` at `.thunderjar/.data/runs.sqlite` (relative to the project root). `runs.json` isn't migrated.
  - Both stores share one schema: indexed columns plus the record as JSON, an aggregation results table and `schema_version` (1). `postrunImage` is unique. Merges and aggregation recomputes run in transactions.
  - The URL is read when the store opens, never at config load, and is shown only through `redactUrl` (`postgres://thunderjar:***@db.acme.internal/thunderjar`). `run` opens the store before building. `doctor` warns when the store is shared but `imageStore` isn't set.
  - One store contract suite runs against sqlite in `bun test` and against a throwaway `postgres` container in `test:docker`. **Any later store method must be added to both stores and to the contract suite.**
  - Open: records don't say whether CI or a developer made them (`ranBy`).

- **3600 Purge** decisions:
  - The spec puts purge out of scope (020's no-retention non-goal, 090, 100, and 120's "testing purge is out of scope"). The story keeps to the non-goal by being **local-only cleanup**: it removes only local image copies that `remoteImageExists` confirms, stopped Thunderjar-labelled containers and the kept `$TMPDIR/thunderjar/<execution ID>/` directories. It never deletes run records, registry images, `doctor-probe` or non-`prerun-`/`postrun-` tags. No store methods were added.
  - `purge [<test case | execution>] [--dry-run]` resolves like `remeasure`. Prerun images are only purged when there's no argument. Without `imageStore`, no images are removed.
  - Pure `planPurge(…)`. The adapter gains `listImages`, `removeImage` (never forced) and `listContainers`. `run` writes a pid file in its execution directory so purge skips in-progress executions.
  - An unreachable image store stops purge before any `rmi`. Single removal failures continue, then exit non-zero.
  - Sample: execution `01k4xp1c5h8ke7` is a run whose push failed, so its image is kept.

- **3700 CI** decisions:
  - Exit codes, used by all commands: 0 success (failed agents and `compare` differences included), 1 unexpected, 2 usage (bad args, unknown ID), 3 configuration (`.thunderjar/`), 4 infrastructure (everything environmental, including unset `requiredEnv`/`urlEnv`, failed `determineHash` commands and partial failures). Typed errors are mapped by the pure `exitCodeFor`. Adding codes 1 and 2 beyond 100's three is raised as a spec gap.
  - `--json` on `plan`, `run`, `executions`, `show`, `compare`, `remeasure`, `restore`, `doctor` and `purge`. stdout carries exactly one document (`schemaVersion: 1`, `command`, stored values rather than display strings, and an `errors` array for partial failures). Progress goes to stderr. Errors are `{ error: { kind, message } }`. One `to…Json` serialiser per command, built on the existing pure functions, with exported TS types.
  - Example workflow `examples/github-actions/thunderjar.yml` plus a "Running in CI" docs page. Thunderjar's own `smoke.yml` runs `test:smoke` weekly and is non-blocking. Changes reach people through the job summary (`show` + `compare`), never through an exit code.

## Pitfalls

- Backlog story 30 (interactive report) is an explicit v1 non-goal (020, 040, 100). Apply the non-goal rule below: write the smallest version that keeps its intent, or note that it shouldn't be a v1 story.

- Iteration tags: the stories have used `-i1` (1-based, unpadded) since 1700, but 081 says zero-padded (`i00`). 2900 raises this as a spec gap. Keep `i1` in samples unless it is resolved.

- When a backlog bullet hits a spec non-goal (as purge did), write the smallest version that keeps the non-goal's intent, and raise the conflict as a spec gap.
- When referring to other backlog items in a story, say "backlog story 20" in plain text. Don't link anchors into `0100`, and don't guess file numbers for stories that aren't written yet.
- Link delivered and proposed stories as siblings (`1600_hashes.md`, `3300_real-harness.md`), the way existing stories do, not `../delivered/…` or `proposed/…`.
- Spec gaps noted in 1800: the wrapper uses GNU `date`/`timeout`, which don't work on a macOS host, and the `cli`'s working directory is unstated.
