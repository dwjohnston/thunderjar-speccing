# 3300: Real harness

A test case can select a real Claude Code pair, such as `claude-code@2.1.283/haiku-4-5`. `run` installs Claude Code in the prerun image and runs it headlessly in the container with the family's `requiredEnv` passed through. The run is then measured and costed like the fake agent's runs. `plan` and `run` refuse to start when a required variable is unset, and `thunderjar doctor` checks the environment without running anything. The API key never ends up in an image, a record or the output. This is backlog story 25.

Areas: C, F

## Spec

- [064-harness.md](../../spec/064-harness.md#requiredenv-credentials) — `requiredEnv`, its per-version override, and failing before building
- [064-harness.md](../../spec/064-harness.md#family-declaration) — the `claude-code` family's four files, and `applyParameter` / `cli` from the examples
- [050-setup-and-configure.md](../../spec/050-setup-and-configure.md#credentials) — only the pair's variables reach its containers, and no secret goes in a config file, an image or the run data store
- [050-setup-and-configure.md](../../spec/050-setup-and-configure.md#install-and-init) — `init`'s example test case uses a cheap model
- [100-cli-reference.md](../../spec/100-cli-reference.md#doctor) — what `doctor` checks, and its exit code
- [087-collecting-token-costs.md](../../spec/087-collecting-token-costs.md#normalising-collecttokencosts) — the Claude Code collector, against real output this time
- [120-test-boundaries.md](../../spec/120-test-boundaries.md#real-harness-smoke-test) — the non-blocking smoke test

## Artifacts

- `requiredEnvFor(pair): string[]` gives the family's list, or the selected version's override. `checkRequiredEnv(permutations, env): Missing[]` names each unset variable and the pairs that need it. `plan`, `run` and `run --dry-run` call it before anything else and exit non-zero if anything is missing. Only the selected pairs count. Names only, never values.
- **Passing credentials without saving them.** The iteration container receives exactly its pair's `requiredEnv`, by name only (`-e NAME`, with the value taken from Thunderjar's own environment). That way the value never appears on a command line, in the recording adapter's output or in the kept build context. [2900](../2900_postrun-image.md) requires the postrun image's `Env` to equal the prerun image's, but `docker commit` saves variables passed to `docker run`. So the variables must reach the harness in a way the commit doesn't capture. For example, start the container idle, run the wrapper through `docker exec -e NAME`, then commit. The implementer chooses the method, and the layer 3.2 test below proves it. Measurement containers ([3000](../3000_measurement-container.md)), restore containers and image builds still get no env.
- The host runner from [1800](../delivered/1800_fake-agent.md) applies the same filter, plus `PATH` and `HOME` so commands still resolve.
- `thunderjar doctor`, in `src/commands/doctor/doctor.ts`. Each check is a function that returns pass, fail or skipped with a reason. The checks are:
  - the configuration loads (the [1400](../delivered/1400_validation.md) validation)
  - the Docker daemon is reachable (the adapter gains `ping()`)
  - every variable required by any declared harness version is set
  - the run data store opens
  - registry access is `skipped` until story 26 adds `imageStore`

  `doctor` exits non-zero if any check fails. It never builds or runs anything.
- **The `claude-code` family is scaffolded by `init`, not shipped in the package.** This settles the question 2500 left open. `init` writes `test-case-parameters/harnessModels/claude-code/` with 064's `index.ts` (`RUN npm install -g @anthropic-ai/claude-code@${ctx.version}`, `claude -p … --output-format json > ${ctx.resultPath}`, `requiredEnv: ["ANTHROPIC_API_KEY"]`). It pins one current version in `versions.ts`, maps `haiku-4-5` in `models.ts`, and includes a real collector implementing [2500](../2500_token-costs.md), checked through the init command tests rather than a real-agent fixture family. `init`'s example test case selects `claude-code@<pinned>/haiku-4-5` with one iteration. These files belong to the user, who can edit them. The package still ships nothing that runs in a container ([141](../../spec/141-runnable-artifact.md#what-the-package-contains)).
- `shellQuote(s)` is exported for `cli` fragments. The template uses it for `ctx.initialPrompt` instead of 064's bare `"${ctx.initialPrompt}"` (see the spec gaps).
- Fixtures:
  - A checked-in credential scenario gives `fake-harness-alpha` an unused version entry whose `requiredEnv` override is `["FAKE_AGENT_TOKEN"]`, used by `fake-is-prime-token`. The fake harness fails if the variable did not reach it. Preserve existing fake versions and hashes, including scenario 2's existing `1.1.0` CLI override.
  - Deterministic `fixtureTests/` scenarios contain only fake harnesses and models. The real-agent smoke test uses a disposable Git project and the configuration written there by the real `init` command; it does not add a real harness family to the checked-in fixture projects.

```
$ thunderjar run claude-is-prime
error: ANTHROPIC_API_KEY is not set (required by claude-code@2.1.283/haiku-4-5)
Nothing was built.

$ thunderjar doctor
✓ configuration    loads (4 test cases, 2 harness families)
✓ docker           daemon reachable (27.3.1)
– image store      skipped: not configured, images stay in the local repository "thunderjar"
✗ environment      ANTHROPIC_API_KEY is not set (claude-code@2.1.283)
                   FAKE_AGENT_TOKEN is set (fake-harness-alpha@1.1.0)
✓ run data store   .thunderjar/.data/runs.json opens
1 check failed.

$ export ANTHROPIC_API_KEY=…
$ thunderjar run claude-is-prime
Execution 01k4xk3r8v6pq2 (1 permutation × 1 iteration)
Output in /tmp/thunderjar/01k4xk3r8v6pq2

Permutation 1/1  node20 | baseline | snerk | claude-code@2.1.283/haiku-4-5 | plain
  prerun image   thunderjar:prerun-he3b7c051  built (41.7s)
  iteration 1/1  postrun-e01k4xk3r8v6pq2-he3b7c051-i1  completed  38.20s  $0.031
    isPrimeTemplateTest  {passed: 5, failed: 0}
    isPrimeTsExists      true
    tsIgnoreCount        0

1 container run: 1 completed   total cost $0.031
Committed 1 postrun image to thunderjar.
```

The measured values in this sample are illustrative. A real agent's are not deterministic.

Out of scope (story numbers are backlog positions): other harnesses (Codex, OpenCode); pre-built harness images (`COPY --from`), which are still open in 020; prompt-cache isolation between runs (020); the registry check and pushing images (story 26); running the smoke test in CI (story 29).

**Spec gaps.**

- 064 says `requiredEnv` is passed as `docker run -e NAME`, but `docker commit` saves those variables into the postrun image's config. Story 26 would then push the API key to a registry, which contradicts 050's "no secret is ever written to an image". 064 should say the variables reach the harness process without becoming part of the container's config.
- 064's `cli` example puts `${ctx.initialPrompt}` inside double quotes. A prompt containing `"`, `$` or a backtick breaks the command or runs code in it. The spec should give `cli` a quoted form, or the prompt as a file.
- 050 promises a runnable example with a cheap model. 141 says the package ships nothing that runs in a container, and no page says where the `claude-code` family comes from. This story has `init` scaffold it.
- `RUN npm install -g` needs Node and npm in the base image, so this harness isn't independent of the base image parameter. That is 020's harness images question. The fixture `node20` base image covers it for now.

## How to test

Follow [the delivery testing strategy](../testing-strategy.md) for fixtures, test placement, adapters and cleanup.

- Unit tests (layer 1 of [120](../../spec/120-test-boundaries.md#1-pure-units)):
  - `requiredEnvFor` with and without a version override
  - `checkRequiredEnv` over a permutation set with one variable missing, which names only the pairs that need it
  - `shellQuote` against quotes, `$`, backticks and newlines
- `init` command tests check the scaffolded real family and its collector against canned result files, including delegated usage, an all-zero crash, error text and an empty file. This is the existing exception allowing real-agent names in `init` and its tests; other unit and fixture tests stay fake.
- CLI tests follow [the delivery testing strategy](../testing-strategy.md), invoking the real CLI against unchanged fake-harness scenarios with recording Docker and external writable stores. Add a checked-in credential-requiring version and case to a suitable scenario, and set `FAKE_AGENT_TOKEN` to a sentinel value through the invocation environment:
  - with the variable unset, `plan` and `run fake-is-prime-token` print the error, issue no Docker command, and exit non-zero, while `fake-is-prime` still runs
  - with it set, the iteration's commands pass `FAKE_AGENT_TOKEN` by name, and no build, measurement or restore command passes any env
  - the sentinel value appears nowhere in stdout, the run data store or the kept run and build directories
  - `doctor` reports each check, with the Docker adapter reachable and unreachable and the variables set and unset, and its exit code follows
  - `init`, run on a copy of a checked-in uninitialised scenario, writes the real family; its command test checks the generated files and collector without invoking an agent. Existing fake-scenario hashes stay unchanged.
- Docker image tests (layer 3.2) live beside `run` as `run.docker.test.ts` and use the real CLI, unchanged credential-requiring fake-harness scenario, real Docker, an external `--data-dir` and a throwaway `--image-prefix`. With the sentinel set, the run completes, proving the variable arrived. Neither its name nor value appears in the postrun image's `Config.Env`, and its value is absent from `docker history`. Remove test-owned artifacts.
- The real-harness smoke test is `bun run test:smoke`, separate from `bun test` and `test:docker`. It requires `ANTHROPIC_API_KEY` and skips when unset. In a disposable Git project, run the real `init` command and its generated example against real Docker. Check result shape rather than fixed measurements: completion, collected non-zero cost, the configured model ID, and recorded measurement outcomes. Remove the project, store, containers and images afterwards. Do not share a real-agent configuration with deterministic fixture scenarios.

- `bun test`
- `bun run test:prepare && bun run test:docker`
- `bun run typecheck`
- 👷‍♂️ `ANTHROPIC_API_KEY=… bun run test:smoke`

## Human interventions

- 👷‍♂️ Provide an Anthropic API key for the smoke test, ideally from a workspace with a low spend limit. Each run costs a few cents.
- 👷‍♂️ Run the smoke test once, and check by eye that `show` on the resulting container run gives plausible tokens and cost, and that `restore` gives a branch with Claude Code's change.
