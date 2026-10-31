# 2800: Prerun image

`thunderjar run <test case>` now builds a prerun image for each permutation. It starts from the base image, clones the code state's commit to `/workspace`, overlays the prompt set's files and installs the harness, then runs every iteration in a container from that image. When an image with that permutation hash already exists locally, it is reused. `plan` says which images would be built. This is the first story that needs Docker.

Areas: C, B, F

## Spec

- [080-docker-execution.md](../spec/080-docker-execution.md#process) — the per-permutation build, reuse when the image exists, and the per-iteration container run
- [060-test-case-parameters.md](../spec/060-test-case-parameters.md#declarations-and-applyparameter) — the prerun Dockerfile is a fold over each parameter's `applyParameter`, in a fixed order
- [060-test-case-parameters.md](../spec/060-test-case-parameters.md#ctxresolvedhash) — a floating parameter builds from its resolved value
- [062-code-state.md](../spec/062-code-state.md#how-the-code-gets-into-the-image) — `git bundle`, a detached checkout with no remote, and only the history up to the commit
- [062-code-state.md](../spec/062-code-state.md#where-the-commit-comes-from) — a missing commit fails before anything is built
- [063-prompt-set.md](../spec/063-prompt-set.md#prompt-files-come-from-a-pinned-commit) — prompt files read with `git show` into the build context
- [064-harness.md](../spec/064-harness.md#applyparameter-installing-the-tool) — the harness fragment gets `ctx.version`
- [080-docker-execution.md](../spec/080-docker-execution.md#the-execution-wrapper) — the wrapper now runs inside the container, as the spec's shell snippet
- [081-docker-tagging.md](../spec/081-docker-tagging.md#tag-formats) — `prerun-h<permutation hash>`
- [100-cli-reference.md](../spec/100-cli-reference.md#plan) — `plan` shows each prerun image and whether it would be reused or built
- [120-test-boundaries.md](../spec/120-test-boundaries.md#31-generating-the-pre-run-image) — layer 3.1, and the fixture image prepare step

## Artifacts

- `renderPrerunDockerfile(permutation, resolved): string`. This pure fold takes the base image fragment, Thunderjar's clone of the code state's commit, the code state fragment, the prompt set's `COPY` lines and fragment, then the harness fragment (with `ctx.version`) and the initial prompt fragment. The commit comes from `commit(ctx)`, so a floating code state checks out the commit resolved in [2600](2600_floating-parameters.md).
- `assembleBuildContext(permutation, repoRoot, dir)`. It writes `Dockerfile`, `code.bundle` (`git bundle create`) and `prompt-set/<files>` (`git show <commit>:<path>`). The directory is kept beside the run directories from [1800](delivered/1800_fake-agent.md), at `$TMPDIR/thunderjar/<execution ID>/prerun-h4f9a21c8/`, so a failed build can be inspected.
- `checkCommits(permutations, repo)`. Before the first build, it checks every commit that a permutation needs, but only for permutations whose image isn't already there. A missing commit stops the execution with 062's message (`error: commit a1b2c3 (code state "baseline") is not in this repository. …`).
- A Docker adapter in `src/adapters/docker/` with a real implementation (the `docker` CLI) and a recording one, which prints the commands it would run ([120](../spec/120-test-boundaries.md#2-cli-with-recording-adapters)). It needs about this much: `imageExists(ref)`, `build(contextDir, ref)`, `run(ref, script, opts)`, `copyOut(container, path, dest)` and `removeContainer(container)`. If Docker can't be reached, `run` stops before anything is built and says so.
- Reuse the existing `preparePrerunBuilds` and `ContainerRunner.runContainer` seams. The Docker runner executes the wrapper in `/workspace` with `ctx.resultPath` = `/thunderjar/result.json`, reads its timing and exit code through stdout, and commits the stopped container into its postrun image before measurement. Measurements and `remeasure` open that image through the shared measurement opener. Keep command tests on this path; do not introduce kept host run directories or a second runner path for them. See [2900](2900_postrun-image.md) for the remaining postrun-image requirements.
- `run` uses the Docker runner. CLI tests invoke that production path through recording Docker, or use real Docker in the separate Docker suite. The host runner remains available for lower-layer unit tests.
- Images are tagged in a local repository, `thunderjar:prerun-h4f9a21c8`. Story 26 swaps it for `imageStore.repository` and adds push and pull. The repository name is injectable, so tests can use a throwaway one.
- `plan` and `run --dry-run` ([1700](delivered/1700_dry-run.md)) print each permutation's prerun image as `(exists, reused)` or `(will build)`.
- Fixtures:
  - Use the checked-in projects in `fixtureTests/`: scenarios 1 and 2 cover parameters that copy bundled files; scenario 4 covers real pinned commits, detached checkouts and prompt files read at their commits. Keep both forms. New Git states are committed and tagged as fixture history, not generated by `seed-repo.sh` during a test.
  - Fake harnesses remain part of those scenario declarations and must be runnable by hand. Use `fake-harness-alpha` / `fake-harness-beta`, fake model IDs and `FAKE_INSTRUCTIONS.md`. Do not create a second `test/fixtures/` project or introduce real-agent files.
  - `bun run test:prepare` (`scripts/prepare-tests.ts`) builds the fixture images and pulls `node:20-bookworm`.

```
$ thunderjar plan fake-is-prime
…
Matrix shape: 1/1/1/1/1 (1 permutation × 2 iterations = 2 container runs)

 1  node20 | baseline | snerk | fake-harness-alpha@1.0.0/fake-model-small | plain
    prerun-h4f9a21c8 (will build)

$ thunderjar run fake-is-prime
Execution 01k4x9j2e8mqz3 (1 permutation × 2 iterations)
Output in /tmp/thunderjar/01k4x9j2e8mqz3

Permutation 1/1  node20 | baseline | snerk | fake-harness-alpha@1.0.0/fake-model-small | plain
  prerun image   thunderjar:prerun-h4f9a21c8  built (14.2s)
  iteration 1/2  postrun-e01k4x9j2e8mqz3-h4f9a21c8-i1  exit 0  0.31s  $0.004
    …
  iteration 2/2  postrun-e01k4x9j2e8mqz3-h4f9a21c8-i2  exit 0  0.29s  $0.004
    …

$ thunderjar run fake-is-prime
…
  prerun image   thunderjar:prerun-h4f9a21c8  reused
```

Out of scope (story numbers are backlog positions): committing and tagging the postrun image (story 21); the measurement container (story 22); naming outcomes and skipping measurement of failed runs (story 23); `requiredEnv` and `doctor` (story 25); the registry, `imageStore` config, and pulling a prerun image built elsewhere (story 26); removing old images (story 28).

**Spec gaps.**

- The spec doesn't say what a base image must provide. Thunderjar's clone step needs `git`, and the wrapper needs GNU `date +%s%3N` and `timeout`. On an Alpine base, busybox `date` has no `%3N`. This story doesn't check for them. A missing tool shows up as Docker's build error or a wrapper failure.
- A harness family has no way to put its own files into the build context. It can only `COPY --from` an image or install over the network, and where harness images come from is open ([020](../spec/020-goals-non-goals.md#to-revisit)). The fake agent uses a fixture image.
- The spec only names a registry repository. Before story 26 there is no registry, so local images go in a fixed `thunderjar` repository.

## How to test

Follow [the delivery testing strategy](testing-strategy.md) for fixtures, test placement, adapters and cleanup.

- Unit tests (layer 1 of [120](../spec/120-test-boundaries.md#1-pure-units)) for `renderPrerunDockerfile`:
  - the fixture permutation renders 060's fragment order
  - an empty fragment adds no line
  - a floating code state checks out its resolved commit
  - a harness fragment sees `ctx.version`
- CLI tests follow [the delivery testing strategy](testing-strategy.md), invoking the real CLI against unchanged scenarios through `src/testing/cli.ts`:
  - `build --dry-run` prints every permutation's Dockerfile, writes nothing and issues no Docker commands
  - `run --dry-run` prints each iteration's image tags and harness command without running it
  - a missing commit stops a real build before any Docker `build`, with 062's message
  - `plan` prints `(will build)` and `(exists, reused)`
- Keep expected output and hashes in the tests. Do not inject a host runner into command tests or generate or patch a project.
- Docker image tests (layer 3.1) live beside `build`, with execution cases beside `run`, as `*.docker.test.ts`. Run unchanged scenarios against real Docker using fake agents, a throwaway `--image-prefix`, and an external `--data-dir` for `run`; remove all test-owned images, containers and writable data afterwards:
  - Scenarios 1 and 2 build copied-file code and prompt sets without needing Git.
  - Scenario 4 gives an image at its pinned commit, detached, with no remote and no later history. `HOUSE_STYLE.md` comes from the prompt set's pinned commit, and the required runtime and fake harness exist.
  - An end-to-end `run` leaves postrun images containing the fake agent's files and `run.json`, and records the expected measurements. A second `run` reports `reused`.

- `bun test`
- `bun run test:prepare && bun run test:docker`
- `bun run typecheck`

## Human interventions

- 👷‍♂️ Make sure CI can run Docker. GitHub's Ubuntu runners can. Add `test:prepare` and `test:docker` to the workflow from [1100](delivered/1100_base-tooling.md).
