# Keeping Secrets Secret

How a harness's credentials reach the container without reaching the postrun image.
The credentials themselves are declared on the harness as
[`requiredEnv`](064-harness.md#requiredenv-credentials); the user supplies them as
described in [050-setup-and-configure.md](050-setup-and-configure.md#credentials).

## The constraint

`docker commit` preserves a container's configuration as well as its filesystem. That
configuration includes every environment variable `docker run` was given. A key passed
with `docker run -e` would be part of the postrun image's config, and the postrun image is
pushed to the image store. A mount is not part of a commit, in config or in filesystem.
So secrets reach the container through a mount, never through `-e`.

## How values reach the harness

1. **Thunderjar writes a temporary file on the host**, mode `0600`, holding the names and
   values of this harness's `requiredEnv` and nothing else.
2. **`docker run` bind-mounts the file read-only** at `/run/thunderjar/env`. No `-e`
   flags are passed.
3. **The execution wrapper sources the file** before invoking the harness's `cli`. The
   variables are exported inside the wrapper's shell, so they exist in the harness
   process's environment and nowhere else.
4. **The temporary file is deleted when the container exits**, however it exits.

```
# /run/thunderjar/env, as mounted
ANTHROPIC_API_KEY=sk-ant-…
```

```
docker run --mount type=bind,src=/tmp/thunderjar-env-01k4x9,dst=/run/thunderjar/env,readonly …
```

```sh
set -a; . /run/thunderjar/env; set +a
start=$(date +%s%3N)
<command returned by the harness's cli>
…
```

The full wrapper is in
[080-docker-execution.md](080-docker-execution.md#the-execution-wrapper).
_(Referenced by: [050-setup-and-configure.md](050-setup-and-configure.md),
[064-harness.md](064-harness.md), [080-docker-execution.md](080-docker-execution.md),
[120-test-boundaries.md](120-test-boundaries.md).)_

## What stays clean

| Where | Why no value is there |
|---|---|
| Postrun image config | `docker run` was given no `-e`, so the committed `Config.Env` is the prerun image's. |
| Postrun image layers | A mount is not in the filesystem diff that `docker commit` captures. |
| Declarations, hashes, run data store | Only names are declared and hashed. See [064-harness.md](064-harness.md#requiredenv-credentials). |

## The harness must not persist credentials

A run's session transcript stays in the postrun image deliberately (see
[085-experiment-results.md](085-experiment-results.md#traces-and-transcripts)), so
Thunderjar does not scrub the home directory before commit. Instead, the rule is on the
harness declaration: `cli` must invoke the tool so that it reads its credentials from the
environment and does not write them to disk. Claude Code with `ANTHROPIC_API_KEY` set
does this. A tool that can only authenticate from a stored credential file is not
supported in v1 (see [020-goals-non-goals.md](020-goals-non-goals.md#non-goals-v1)).

## Checks

- **Before push.** After `docker commit`, Thunderjar inspects the new image's `Config.Env`.
  If any name from the harness's `requiredEnv` appears, the image is not pushed and the
  container run fails as an infrastructure error, naming the variable.
- **In Thunderjar's own tests.** The postrun image test asserts that no fixture secret
  value appears in the image config or in any file `docker diff` reports as changed. See
  [120-test-boundaries.md](120-test-boundaries.md#32-generating-the-post-run-image).

## Open questions

- **Remote Docker daemons.** A bind mount needs the file on the daemon's host. Whether a
  remote daemon (common in CI) is supported at all is undecided; if it is, the file would
  have to be copied into the container with `docker cp` and deleted by the wrapper
  immediately after sourcing.
- Whether the before-push check should also scan changed files for the secret values, or
  whether the test-suite assertion is enough.
