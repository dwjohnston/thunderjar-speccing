# 2900: Postrun image

After each iteration's container exits, `thunderjar run` commits it into a postrun image and tags it locally, so every container run leaves a durable image of the agent's end state. `docker run` on the image shows exactly what the agent left in `/workspace`, plus the wrapper's `run.json` and the harness result file in `/thunderjar`. This is backlog story 21.

Areas: C, E

## Spec

- [080-docker-execution.md](../spec/080-docker-execution.md#process) — steps `M`–`N`: commit the container, then tag it, before measurement
- [080-docker-execution.md](../spec/080-docker-execution.md#why-commit-happens-before-measurement) — the image is exactly the agent's end state, and the result file and `run.json` are preserved in it
- [080-docker-execution.md](../spec/080-docker-execution.md#when-the-agent-fails) — a failed or timed-out run is still committed
- [030-terminology.md](../spec/030-terminology.md#postrun-image) — always new, never reused
- [081-docker-tagging.md](../spec/081-docker-tagging.md#tag-formats) — `postrun-e<execution ID>-h<permutation hash>-i<iteration>`
- [085-test-case-results.md](../spec/085-test-case-results.md#what-gets-written-to-the-run-data-store) — `postrunImage` is the tag, so the record reaches the artifact
- [120-test-boundaries.md](../spec/120-test-boundaries.md#32-generating-the-post-run-image) — layer 3.2, starting from a fixture prerun image
- [150-repository-layout.md](../spec/150-repository-layout.md#fixture-images) — the `prerun-basic` fixture image

## Artifacts

- The Docker adapter from [2800](2800_prerun-image.md) gains `commit(container, ref, { labels, changes })`. The recording adapter prints it like the other commands.
- `createDockerRunner` commits each iteration's container after the wrapper exits, then removes it. The wrapper's `run.json` is read through stdout; measurement reads the postrun image through the shared opener. Tests assert this existing lifecycle with the added labels and failure behavior, without introducing a kept host workspace or an extra execution-time copy-out.
- Non-zero and timed-out runs are committed too. If the commit itself fails, the execution stops with an error, and the container is left in place (not removed) and named in the message.
- The commit doesn't leak the run into the image's config:
  - `changes` resets `CMD` (and `WORKDIR`) to the prerun image's, so starting the postrun image doesn't rerun the agent.
  - The image's `Env` equals the prerun image's. Nothing is passed with `-e` yet. Story 25 must keep it that way when it passes `requiredEnv`, because `docker commit` saves run-time env, and so it would save API keys into an image that story 26 pushes.
- `postrunLabels(record): Record<string, string>`. This pure function returns the labels for the commit: `thunderjar.execution-id`, `thunderjar.permutation-hash` (full, untruncated), `thunderjar.iteration` and `thunderjar.test-case`. A future `purge` or a registry listing can then find runs without the data store.
- `ContainerRunRecord.postrunImage` stays the tag alone. The image ref is `<repository>:<tag>`, using the injectable local repository from 2800.
- A checked-in Git scenario's fake harness commits its change with a fixed author and date, so the postrun image's history has a stable SHA. Preserve the copied-file scenarios, whose workspaces need no repository.
- Fixture image `thunderjar-test-fixtures:prerun-basic`: the base image, a tagged scenario 4 repository state and its fake harness, built by `test:prepare` from checked-in scenario artifacts. Layer 3.2 starts from it rather than depending on a previous test's output. Its definition lives beside its scenario.

```
$ thunderjar run fake-is-prime
Execution 01k4x9j2e8mqz3 (1 permutation × 2 iterations)
Output in /tmp/thunderjar/01k4x9j2e8mqz3

Permutation 1/1  node20 | baseline | snerk | fake-harness-alpha@1.0.0/fake-model-small | plain
  prerun image   thunderjar:prerun-h4f9a21c8  reused
  iteration 1/2  postrun-e01k4x9j2e8mqz3-h4f9a21c8-i1  exit 0  0.31s  $0.004
    …
  iteration 2/2  postrun-e01k4x9j2e8mqz3-h4f9a21c8-i2  exit 0  0.29s  $0.004
    …

Committed 2 postrun images to thunderjar.

$ docker image ls thunderjar
REPOSITORY   TAG                                     IMAGE ID       CREATED
thunderjar   postrun-e01k4x9j2e8mqz3-h4f9a21c8-i2    5b07c1e9a2d4   4 seconds ago
thunderjar   postrun-e01k4x9j2e8mqz3-h4f9a21c8-i1    e83f2a61c0b7   5 seconds ago
thunderjar   prerun-h4f9a21c8                        9c41d2f08e35   2 minutes ago

$ docker run --rm thunderjar:postrun-e01k4x9j2e8mqz3-h4f9a21c8-i1 git -C /workspace log --oneline
3e7a9c2 Add isPrime
a1b2c3d Baseline
```

Out of scope (story numbers are backlog positions): measuring in a container from the postrun image, and dropping the copy-out (story 22); naming outcomes and skipping measurement of failed runs (story 23); `show`'s `Restore with:` line and `restore` (story 24); pushing to a registry (story 26); removing images (story 28).

**Spec gaps.**

- [120](../spec/120-test-boundaries.md#32-generating-the-post-run-image) asserts that "the labels are correct", but no page says which labels a postrun image carries. This story proposes the four above.
- The spec doesn't say what the committed image's `CMD` and `Env` should be. Left as `docker commit` defaults, starting the image reruns the agent, and secrets passed at run time end up in the image.
- 081 zero-pads a 0-based iteration index (`i00`). The stories have used `i1`, 1-based and unpadded, since [1700](delivered/1700_dry-run.md). The tag now names a real image, so this is the last cheap moment to pick one and align the spec or the stories.
- A base image that declares `VOLUME /workspace` would leave the agent's work out of the commit. Nothing checks for it.

## How to test

Follow [the delivery testing strategy](testing-strategy.md) for fixtures, test placement, adapters and cleanup.

- Unit tests (layer 1 of [120](../spec/120-test-boundaries.md#1-pure-units)) for `postrunLabels`.
- CLI tests follow [the delivery testing strategy](testing-strategy.md). Invoke the real CLI against unchanged scenarios with recording Docker lifecycle state and an external `--data-dir`. Assert stdout, stderr, exit code, records and the exact commands:
  - each iteration issues `run`, `commit` (with the tag and labels) and `rm`, in that order, before measurement opens the postrun image
  - an iteration that exits non-zero is still committed
  - a failing `commit` stops the execution, issues no `rm` for that container, and exits non-zero
- Docker image tests (layer 3.2) live beside `run` as `run.docker.test.ts` and run only under `test:docker`, using the real CLI, real Docker, unchanged Git scenario declarations, an external `--data-dir` and a throwaway `--image-prefix`. `test:prepare` supplies the independent `prerun-basic` starting image; remove all test-owned images, containers and writable data afterwards. Assert that:
  - the image has the expected tag and labels
  - `/workspace` holds the fake agent's files, and `git log` is the scenario's pinned history plus the fake agent's commit
  - `/thunderjar/run.json` and the result file exist
  - the image's `Cmd` and `Env` match the prerun image's
- The end-to-end `run` test from 2800 also checks that each postrun image exists.

- `bun test`
- `bun run test:prepare && bun run test:docker`
- `bun run typecheck`

## Human interventions

None.
