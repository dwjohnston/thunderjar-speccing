# Code State

The codebase applied on top of the base image, usually a git commit from the user's
repository, plus any setup the codebase needs before the agent starts.

One of the five test case parameters. Hashing and `applyParameter` are common to all of
them — see [060-test-case-parameters.md](060-test-case-parameters.md).

## Declaration

Lives at `test-case-parameters/codeStates/<name>/index.ts`.

```ts
// test-case-parameters/codeStates/baseline/index.ts
import { checkoutCommit, declareCodeState } from "thunderjar";

export default declareCodeState({
  config: { commit: "a1b2c3" },
  applyParameter: (config, ctx) => `${checkoutCommit(ctx, config.commit)}\nRUN npm ci`,
});
```

| Field | What it is |
|---|---|
| `config` | Optional. Whatever the fragment needs, typically the commit the agent starts from. |
| `applyParameter` | Returns a Dockerfile fragment, run with `/workspace` as the working directory, that puts the codebase there and sets it up: installing dependencies, seeding fixtures. |

Thunderjar doesn't put any code in `/workspace` itself. Getting the codebase there is
the code state's fragment's job, so a new commit on the developer's branch never changes
an image unless a code state asks for that commit.

```ts
// test-case-parameters/codeStates/with-fixture/index.ts
export default declareCodeState({
  config: { commit: "a1b2c3" },
  applyParameter: (config, ctx) =>
    `${checkoutCommit(ctx, config.commit)}\nRUN npm ci && ./scripts/seed-fixture-data.sh`,
});
```

A code state doesn't have to use git. One that copies files kept beside its declaration
needs no repository, and editing those files changes its parameter hash:

```ts
// test-case-parameters/codeStates/tiny/index.ts — with tiny/files/package.json beside it
export default declareCodeState({
  applyParameter: (_config, ctx) => `COPY ${ctx.dir}/files/ /workspace/\nRUN npm ci`,
});
```

## How the code gets into the image

`checkoutCommit(ctx, commit)`, exported from `thunderjar`, is the usual way:

1. `ctx.git.bundle(commit)` packs the commit and its ancestors into a bundle in the build
   context, read from the repository Thunderjar is run in.
2. The fragment it returns clones that bundle to `/workspace`, checks out the commit
   detached, removes the remote and the bundle's branch, and sets a git identity so the
   agent can commit.

```dockerfile
WORKDIR /workspace                                 # Thunderjar
COPY git/a1b2c3.bundle /tmp/code.bundle            # checkoutCommit
RUN git clone --quiet /tmp/code.bundle /workspace \
  && git -C /workspace checkout --quiet --detach a1b2c3 \
  && git -C /workspace branch --quiet --delete --force code-state \
  && git -C /workspace remote remove origin \
  && git -C /workspace config user.name "Thunderjar agent" \
  && git -C /workspace config user.email agent@thunderjar.invalid \
  && rm /tmp/code.bundle
RUN npm ci                                         # the rest of the code state's fragment
```

_(Referenced by: [060-test-case-parameters.md](060-test-case-parameters.md#declarations-and-applyparameter),
[063-prompt-set.md](063-prompt-set.md), [090-restore-purge.md](090-restore-purge.md),
[061-base-image.md](061-base-image.md).)_

- **Only history up to the commit.** The bundle holds the commit and its ancestors, never
  other branches or later commits. Otherwise the agent could find the commit that solves
  its task with `git log --all`.
- **No credentials.** The code comes from the local repository, so a private repository
  needs nothing in the image build.
- **A real repository.** The agent can use git, and [restore](090-restore-purge.md) can
  fetch the agent's commits back on top of a commit the developer already has.

## Where the commit comes from

**Thunderjar assumes the environment it runs in has enough git history for every
parameter it applies.** It reads commits from the repository it is run in, found from the
`.thunderjar/` folder, and never fetches. Keeping that repository up to date is the
environment's job: a developer pulls, and a CI pipeline checks out with enough history
(e.g. `fetch-depth: 0`).

_(Referenced by: [050-setup-and-configure.md](050-setup-and-configure.md#prerequisites),
[063-prompt-set.md](063-prompt-set.md).)_

- **Only commits a fragment asks for are read.** Rendering the prerun Dockerfile records
  every `ctx.git` request, so the commits are known before anything is built. A project
  whose fragments read no commits needs no repository.
- **A missing commit fails before anything is built**, naming the commit and the
  parameter that needs it:
  ```
  error: commit a1b2c3 (code state "baseline") is not in this repository.
  Fetch it, or check that it has been pushed.
  ```
- **A missing commit can't produce a different run.** A SHA means the same content on
  every machine, so a commit is either there and correct, or the run stops.
- **A commit is only needed to build.** If the permutation's prerun image is already in
  the image store, it is pulled, and the commit isn't read.
- **A pinned commit must be pushed** for anyone else, CI included, to build from it.

## Following a moving target

A code state can follow a moving target, such as the tip of `main`, by declaring
`determineHash` and checking out `ctx.resolvedHash` (see
[060-test-case-parameters.md](060-test-case-parameters.md#parameters-that-follow-a-moving-target)).
This can be called a *floating parameter*.

```ts
// test-case-parameters/codeStates/main/index.ts
export default declareCodeState({
  determineHash: () => `git rev-parse origin/main`,
  applyParameter: (_config, ctx) => `${checkoutCommit(ctx, ctx.resolvedHash)}\nRUN npm ci`,
});
```

Resolve against the remote-tracking branch (`origin/main`), not a local one. Every
machine's local `main` can be at a different commit, so "latest `main`" would mean
something different on each. Even `origin/main` is only as fresh as the environment's
last fetch.

## When it applies

Build time only. The code state's fragment runs after the base image's and the harness's,
with `/workspace` as the working directory, and before the prompt set's.

## Future

- Test cases kept in a different repository from the code they run against, and
  Thunderjar fetching a missing commit itself. See
  [020-goals-non-goals.md](020-goals-non-goals.md#non-goals-v1).

