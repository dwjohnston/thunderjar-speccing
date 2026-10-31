# 3600: Purge

`thunderjar purge` frees disk space on the machine it runs on. It removes local copies of prerun and postrun images that are safe in the image store, Thunderjar's stopped leftover containers, and the kept directories under `$TMPDIR/thunderjar/`. Nothing is lost: run records and registry images are never touched, and `remeasure` and `restore` pull a purged image back ([3400](3400_registry.md)). `purge --dry-run` lists what would go. This is backlog story 28.

Areas: C, F

## Spec

- [020-goals-non-goals.md](../../spec/020-goals-non-goals.md#non-goals-v1) — no retention policy, and everything is kept indefinitely. This story keeps to that by only removing copies that exist somewhere else.
- [090-restore-purge.md](../../spec/090-restore-purge.md#purge) and [100-cli-reference.md](../../spec/100-cli-reference.md#out-of-scope-for-the-first-pass) — both put `purge` out of scope. See the spec gaps below.
- [070-data-architecture.md](../../spec/070-data-architecture.md#the-two-stores) — the image store tells prerun and postrun images apart by tag prefix, which is how purge finds Thunderjar's images

## Artifacts

- `thunderjar purge [<test case | execution>] [--dry-run]`. With no argument it covers every Thunderjar image in the configured repository. With an argument it resolves the way `remeasure` does ([2400](../2400_remeasure.md)), and covers only that execution's postrun images and its kept directory. Prerun images are only purged when there's no argument, because other test cases may share them.
- The Docker adapter gains about `listImages(repository, { tagPrefixes })`, `removeImage(ref)` (never forced), `listContainers({ label, status })` and `removeContainer` (which already exists). The recording adapter prints them.
- Pure `planPurge({ localImages, inImageStore, containers, runDirs, inProgress }): PurgePlan` → `{ removeImages, keepImages: { ref, reason }[], removeContainers, removeRunDirs }`. `purge` and `--dry-run` print the same plan, and only `purge` carries it out.
- **What is removed:**
  - a local `prerun-`/`postrun-` image in the configured repository, only when `remoteImageExists` says it is in the image store. A postrun image whose push failed (3400) is kept and listed, along with the reason.
  - stopped containers that carry Thunderjar's labels (`thunderjar.execution-id`, `thunderjar.measurement`, `thunderjar.restore`), such as the one a failed commit leaves in place ([2900](../2900_postrun-image.md)). Running containers are left alone.
  - kept directories `$TMPDIR/thunderjar/<execution ID>/`, except for an execution that is still running. `run` writes a pid file in its directory and removes it at the end. Purge skips a directory whose pid is still alive.
- **What is never removed:** run records (`show`, `compare` and `executions` keep working), images in the registry, `doctor-probe` and any tag without a `prerun-`/`postrun-` prefix (as 3400 asked), and images in other repositories.
- **Without `imageStore`**, local images are the only copy, so all of them are kept, and purge removes only containers and directories. It says so on its first line.
- If the image store can't be reached, purge stops before it removes any image, since it can't check what is safe to remove. If one removal fails (for example, an image that a running container uses), purge reports it, carries on, and exits non-zero at the end.

```
$ thunderjar purge --dry-run
Image store ghcr.io/acme/thunderjar-images
Would remove 3 local images (in the image store):
  prerun-h4f9a21c8
  postrun-e01k4xm6t9b3zq5-h4f9a21c8-i1
  postrun-e01k4xm6t9b3zq5-h4f9a21c8-i2
Would keep 1 local image:
  postrun-e01k4xp1c5h8ke7-h4f9a21c8-i1   not in the image store (push failed?)
Would remove 1 stopped container:
  3f2a91c0d4e7   thunderjar.execution-id=01k4xp1c5h8ke7
Would remove 2 run directories in /tmp/thunderjar:
  01k4xm6t9b3zq5  01k4xp1c5h8ke7
Run records are not touched.

$ thunderjar purge
…
Removed 3 images, 1 container and 2 run directories. Kept 1 image.

$ thunderjar restore postrun-e01k4xm6t9b3zq5-h4f9a21c8-i1
Pulled ghcr.io/acme/thunderjar-images:postrun-e01k4xm6t9b3zq5-h4f9a21c8-i1 (2.4s)
…

$ thunderjar purge                        # no imageStore
No image store configured: local images are the only copy and are kept.
Removed 0 containers and 2 run directories.
```

Out of scope (story numbers are backlog positions): any retention policy (TTLs, keeping only the latest N, pass/fail-based retention), deleting from the registry, deleting run records, purging the local `thunderjar` repository after `imageStore` is set, sizes and reclaimed space in the output, and `--json` (story 29).

**Spec gaps.**

- 020, 090 and 100 all put purge out of scope, and 120 says "Testing purge is out of scope". This story keeps to the non-goal's intent (no policy, everything kept in the image store and the run data store), but adds a command. 090's Purge section and 100's out-of-scope list should describe this local-only `purge`, and 120 should drop that line.
- No page says that the kept `$TMPDIR/thunderjar/` directories (1800, 2800) grow without bound, or who removes them.

## How to test

Follow [the delivery testing strategy](../testing-strategy.md) for fixtures, test placement, adapters and cleanup.

- Unit tests (layer 1 of [120](../../spec/120-test-boundaries.md#1-pure-units)) for `planPurge`: in-store versus not-in-store images, the `doctor-probe` tag and other tags, running versus stopped containers, an in-progress directory, scoping to an execution (no prerun images), and no `imageStore`.
- CLI tests follow [the delivery testing strategy](../testing-strategy.md). Invoke the real CLI against unchanged scenarios with recording Docker state and a disposable `TMPDIR` containing copies of checked-in run-directory artifacts. `show` reads the scenario's history unchanged. Keep expected removal plans in the tests, and assert stdout, stderr, exit codes, adapter commands and produced filesystem changes:
  - `--dry-run` issues only list and `remoteImageExists` commands, and changes nothing on disk
  - `purge` issues `rmi` only for in-store images, and never with `-f`
  - an unreachable image store stops purge before any `rmi`, and one failed `rmi` gives a non-zero exit after the rest
  - without `imageStore`, no image commands are issued
  - `show` on a purged execution prints the same output as before
- Docker image tests (layer 3) live beside `purge` as `purge.docker.test.ts`. Use unchanged fake-harness scenarios, external writable data, a throwaway image repository and 3400's disposable registry. Invoke the real CLI to run, purge, remeasure and restore into an isolated Git target. Assert images disappear locally but remain in the registry and can be pulled again; fixture images and unrelated resources survive. Remove test-owned services, containers, images, stores and targets.

- `bun test`
- `bun run test:prepare && bun run test:docker`
- `bun run typecheck`

## Human interventions

- 👷‍♂️ In a scratch project with `imageStore` set, run `purge --dry-run`, then `purge`, and check with `docker images` that only Thunderjar's local copies went, and in the registry's web UI that nothing was removed there.
