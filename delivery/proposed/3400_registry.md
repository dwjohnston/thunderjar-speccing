# 3400: Registry

With `imageStore: { repository }` set in `thunderjar.config.ts`, `run` pushes every prerun and postrun image to that registry repository. Postrun images are pushed before they are measured. A prerun image that another machine already pushed is pulled rather than rebuilt. `remeasure` and `restore` pull a postrun image that isn't on this machine, so CI's runs can be backfilled or restored locally. `doctor`'s image store check becomes real. Thunderjar holds no registry credentials: Docker uses the user's `docker login`. This is backlog story 26.

Areas: C, E, F

## Spec

- [050-setup-and-configure.md](../../spec/050-setup-and-configure.md#thunderjarconfigts) — `imageStore.repository` in `thunderjar.config.ts`
- [050-setup-and-configure.md](../../spec/050-setup-and-configure.md#authentication) — the image store authenticates through the user's `docker login`, and Thunderjar holds no registry credentials
- [070-data-architecture.md](../../spec/070-data-architecture.md#the-two-stores) — one repository for prerun and postrun images, told apart by tag prefix
- [080-docker-execution.md](../../spec/080-docker-execution.md#process) — pull an existing prerun image, or build and push one. Push each postrun image before measuring it ([why](../../spec/080-docker-execution.md#why-commit-happens-before-measurement)).
- [062-code-state.md](../../spec/062-code-state.md#where-the-commit-comes-from) — a prerun image in the image store is pulled, and its commit isn't read
- [100-cli-reference.md](../../spec/100-cli-reference.md#doctor) — `doctor` checks that the registry accepts a push
- [090-restore-purge.md](../../spec/090-restore-purge.md#errors) — "no postrun image found" now means neither local nor in the image store

## Artifacts

- `thunderjar.config.ts` accepts `imageStore: { repository: string }`, which is validated as a Docker repository reference ([1400](../delivered/1400_validation.md)). It is **optional**. Without it, images stay in the local `thunderjar` repository from [2800](../2800_prerun-image.md), and nothing is pushed or pulled, so `init`'s example and Thunderjar's own layer 2 tests still work offline. `init` scaffolds it as a commented-out line.
- With it set, the configured repository replaces `thunderjar` in every image ref, for example `ghcr.io/acme/thunderjar-images:prerun-h4f9a21c8`. Images are tagged under that name locally too, so there is no separate local name.
- The Docker adapter gains about `push(ref)`, `pull(ref): "pulled" | "notFound"` and `remoteImageExists(ref)` (for example `docker manifest inspect`). The recording adapter prints them like the other commands. Only an image that doesn't exist yields `notFound`. Auth and network failures are errors, and the message suggests `docker login <registry>` where it fits.
- `resolvePrerunImage(docker, ref): "local" | "remote" | "missing"`. `preparePrerunBuilds` (2800) then reuses a local image, pulls a remote one, or builds and pushes a missing one. `checkCommits` runs only for `missing` images. `plan` and `run --dry-run` print `(exists, reused)`, `(in image store, will pull)` or `(will build)`, and the iteration line's prerun status gains `pulled (6.8s)` and `built (14.2s), pushed (3.1s)`.
- Each iteration becomes `run` → `commit` → `push` → `rm` (the wrapper result comes through stdout), then measurement as in [3000](../3000_measurement-container.md). Failed and timed-out runs are pushed too ([3100](../3100_failure-handling.md)). If a push fails, the run is still recorded, the image is kept locally and named in the message, and the execution stops with a non-zero exit. Retrying is a manual `docker push`.
- `ContainerRunRecord` gains `imageRepository` (a spec addition). `remeasure` and `show`'s `Restore with:` hint use the recorded repository, not the current config, so changing `imageStore` doesn't make older runs point at the wrong place. Records without the field read as `thunderjar`.
- `remeasure` (from [2400](../2400_remeasure.md), with 3000's `imageExists` check) pulls a postrun image that isn't local. Only an image missing from both places is reported as `not found, skipped`.
- `restore` ([3200](../3200_restore.md)) takes a tag, and it doesn't read the run data store. It looks for `<configured repository>:<tag>` locally, then pulls it. A developer can therefore restore a CI run from the tag in CI's log, before story 27 shares the run records.
- Pulled images stay local afterwards. Removing them is story 28.
- `doctor`'s image store check (left `skipped` by [3300](3300_real-harness.md)) pushes a tiny probe image as `<repository>:doctor-probe` and reports pass or fail with Docker's reason. The probe is built from an empty context and overwrites the same tag each time. Without `imageStore`, the check stays `skipped`.

```
$ thunderjar plan fake-is-prime
…
 1  node20 | baseline | snerk | fake-harness-alpha@1.0.0/fake-model-small | plain
    prerun-h4f9a21c8 (in image store, will pull)

$ thunderjar run fake-is-prime
Execution 01k4xm6t9b3zq5 (1 permutation × 2 iterations)
Output in /tmp/thunderjar/01k4xm6t9b3zq5

Permutation 1/1  node20 | baseline | snerk | fake-harness-alpha@1.0.0/fake-model-small | plain
  prerun image   ghcr.io/acme/thunderjar-images:prerun-h4f9a21c8  pulled (6.8s)
  iteration 1/2  postrun-e01k4xm6t9b3zq5-h4f9a21c8-i1  completed  0.31s  $0.004
    …
  iteration 2/2  postrun-e01k4xm6t9b3zq5-h4f9a21c8-i2  completed  0.29s  $0.004
    …

2 container runs: 2 completed   total cost $0.008
Committed and pushed 2 postrun images to ghcr.io/acme/thunderjar-images.

$ thunderjar restore postrun-e01k4xm6t9b3zq5-h4f9a21c8-i1     # on another machine
Pulled ghcr.io/acme/thunderjar-images:postrun-e01k4xm6t9b3zq5-h4f9a21c8-i1 (2.4s)
Fetched 1 commit from postrun-e01k4xm6t9b3zq5-h4f9a21c8-i1
Created branch thunderjar/postrun-e01k4xm6t9b3zq5-h4f9a21c8-i1
…

$ thunderjar doctor
…
✗ image store      push to ghcr.io/acme/thunderjar-images denied (unauthorized)
                   run `docker login ghcr.io`
```

Out of scope (story numbers are backlog positions): sharing run records (story 27); removing images, locally or in the registry (story 28); exit codes and `--json` (story 29); a `push` command to retry failed pushes; parallel pushes.

**Spec gaps.**

- 050 lists a registry as a prerequisite, but the config example and `init`'s runnable example imply it is needed from the first `run`. This story makes `imageStore` optional, with a local fallback. The spec should say so.
- 100's `doctor` checks that "the registry accepts a push", but no page says what to push. This story pushes a `doctor-probe` tag, so `doctor` writes to the registry, a small exception to "runs nothing".
- The images contain the user's code, the agent's output and the harness result file. No page says the repository should be private.
- Tags are mutable, and records keep tags, not digests. Two runners that build the same missing prerun hash at once both push it, and the last push wins. The two images are meant to be equivalent, but they aren't byte-identical (a pinned `npm install` still floats, see 020). Recording the pushed digest would make this visible. It is left open here.
- 080 doesn't say what happens when a push fails. This story records the run and stops.

## How to test

Follow [the delivery testing strategy](../testing-strategy.md) for fixtures, test placement, adapters and cleanup.

- Unit tests (layer 1 of [120](../../spec/120-test-boundaries.md#1-pure-units)) for config validation of `imageStore`, ref construction with and without it, and the three outcomes of `resolvePrerunImage`.
- CLI tests follow [the delivery testing strategy](../testing-strategy.md). Use the real CLI against an unchanged checked-in scenario whose config sets `imageStore`; configure local, remote, missing, denied and failed-push states in the recording Docker adapter. `run` and `remeasure` use external writable stores, and `restore` uses an isolated Git target. Assert stdout, stderr, exit codes, stored records and adapter commands:
  - prerun `local`, `remote` and `missing` each issue the expected commands (no build or commit check when pulling, and `build` → `push` when missing), and `plan` prints the matching status
  - an iteration issues `commit` → `push` before any measurement `start`. A failed push records the run, issues no measurement, and exits non-zero.
  - `remeasure` and `restore` pull a missing image, and report `notFound` with 3000's and 110's messages
  - `doctor`'s image store check passes, fails and is `skipped` without `imageStore`
  - without `imageStore`, the existing expected output is unchanged
- Docker image tests (layer 3) live beside their commands as `*.docker.test.ts`. Use unchanged scenarios, external writable stores, a throwaway `--image-prefix` consistent with the scenario's configured registry repository, and a real `registry:2` container on a random localhost port. Supply the port through a declared environment variable read by the checked-in config; do not rewrite config files. Label and remove all test-owned registry containers, images and directories. `test:prepare` supplies required base images and pulls `registry:2`:
  - after `run fake-is-prime`, the registry's tag list holds the prerun tag and both postrun tags
  - after the local copies are removed, `remeasure` pulls and measures, `restore` into a throwaway repository gives the same branch as 3.4, and a second `run` pulls the prerun image instead of building it
  - the pulled postrun image's `Config.Env` still has no `FAKE_AGENT_TOKEN` ([3300](3300_real-harness.md))

- `bun test`
- `bun run test:prepare && bun run test:docker`
- `bun run typecheck`

## Human interventions

- 👷‍♂️ Create a **private** registry repository (for example on GHCR), and run `docker login` for it.
- 👷‍♂️ Set `imageStore` in a scratch project, run `fake-is-prime` once, and check in the registry's web UI that the tags appear and the repository isn't public.
- 👷‍♂️ Optionally, on a second machine with no images, run `restore` on one of those tags and check that it pulls.
