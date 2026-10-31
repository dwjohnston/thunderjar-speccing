# 3200: Restore

`thunderjar restore <container run>` brings one run's end state into the developer's own repository as the branch `thunderjar/<container run>`. The branch holds the agent's commits, plus a Thunderjar commit for anything the agent left uncommitted. The developer stays on their branch, and their working tree and index are untouched. `show <container run>` ends with the command to do it. This is backlog story 24.

Areas: C, F

## Spec

- [090-restore-purge.md](../spec/090-restore-purge.md#restore) — what restore does, the Thunderjar commit and the three errors
- [062-code-state.md](../spec/062-code-state.md#how-the-code-gets-into-the-image) — the image's history starts at a commit the developer already has, so only the agent's commits need fetching
- [100-cli-reference.md](../spec/100-cli-reference.md#restore) and [110-cli-report-visualization.md](../spec/110-cli-report-visualization.md#restore) — usage and output
- [110-cli-report-visualization.md](../spec/110-cli-report-visualization.md#a-container-run) — the `Restore with:` line
- [120-test-boundaries.md](../spec/120-test-boundaries.md#34-restoring-from-a-post-run-image) — layer 3.4, run from a throwaway repository
- [150-repository-layout.md](../spec/150-repository-layout.md#fixture-images) — the `postrun-committed` and `postrun-uncommitted` fixture images

## Artifacts

- `thunderjar restore <container run>`, in `src/commands/restore/restore.ts`. The argument is a postrun tag. Restore acts on the git repository that contains the current directory. It reads the image, not the run data store, so it works for any postrun image that exists locally. Story 26 adds pulling one from a registry.
- `postrunLabels` from [2900](2900_postrun-image.md) gains `thunderjar.code-state-commit`, the full SHA the prerun image checked out (the resolved one, for a floating code state). This is where the agent's commits start. The image carries it, so restore doesn't depend on the record or on a declaration that may have changed since. Images committed before this story don't have the label, and restore refuses them with a clear message.
- The Docker adapter gains `imageLabels(ref)`. Restore otherwise reuses `start`, `exec`, `copyOut` and `removeContainer` from [3000](3000_measurement-container.md).
- `restoreContainerRun(docker, repoDir, tag)`. It does the checks first and changes nothing if any fails, then:
  1. starts a throwaway container from the postrun image, labelled `thunderjar.restore` plus `postrunLabels`
  2. if `git status --porcelain` in `/workspace` isn't empty, makes the **Thunderjar commit** there with `git add -A`, with the author and committer `Thunderjar`, a message that names the container run, and the run's end time from `/thunderjar/run.json` as its date. Restoring the same run twice then gives the same SHA.
  3. bundles `<code state commit>..HEAD`, copies the bundle out to a temp directory, and always removes the container
  4. in the developer's repository, fetches the bundle and creates `thunderjar/<tag>` at its head without checking it out. Only the new branch and its objects change.

  The commit happens in the throwaway container, so the postrun image itself is never modified.
- Errors, each checked before anything changes, with the messages from 110: not inside a git repository, branch already exists, no postrun image found. This story adds two more: the image has no `thunderjar.code-state-commit` label, and the code state commit isn't in this repository (062's wording: pull it first).
- An agent that made no commits and left a clean tree still gets a branch, which points at the code state commit (`Fetched 0 commits`).
- `show <container run>` from [2200](delivered/2200_show.md) ends with `Restore with: thunderjar restore <tag>`. That includes failed and timed-out runs ([3100](3100_failure-handling.md)), which are the ones most worth inspecting.
- Fixtures:
  - `thunderjar-test-fixtures:postrun-uncommitted` is prepared from the checked-in Git scenario's `prerun-basic`, with a checked-in fake-harness declaration that leaves its change uncommitted. Keep its image definition beside the scenario and register it in `test:prepare`.
  - Both postrun fixture images carry the Git scenario's pinned full commit in `thunderjar.code-state-commit`, so restore treats them like real runs.
  - Restore targets are disposable Git clones of the same tagged history used by the checked-in Git scenario. Dirty worktrees and existing-branch cases come from checked-in artifact states copied into the disposable target. Do not generate a Thunderjar project, use `seed-repo.sh`, or modify the workspace repository.

```
$ thunderjar restore postrun-e01k4x9j2e8mqz3-h4f9a21c8-i1
Fetched 1 commit from postrun-e01k4x9j2e8mqz3-h4f9a21c8-i1
Created branch thunderjar/postrun-e01k4x9j2e8mqz3-h4f9a21c8-i1

You are still on main. Your working tree was not touched.
Check it out with:
  git checkout thunderjar/postrun-e01k4x9j2e8mqz3-h4f9a21c8-i1

$ git log --oneline thunderjar/postrun-e01k4x9j2e8mqz3-h4f9a21c8-i1
3e7a9c2 Add isPrime
a1b2c3d Baseline

$ thunderjar restore postrun-e01k4x9j2e8mqz3-h4f9a21c8-i1
error: branch thunderjar/postrun-e01k4x9j2e8mqz3-h4f9a21c8-i1 already exists
Nothing was changed.
```

With `postrun-uncommitted`, the output adds 110's line, `Working tree had uncommitted changes at the end of the run: added a Thunderjar commit.`, and the branch ends in that commit.

Out of scope (story numbers are backlog positions): pulling a missing image from a registry (story 26); restoring from the interactive report (story 30); a `--force` that overwrites an existing branch.

**Spec gaps.**

- 090 doesn't say how restore knows where the agent's commits start. This story proposes the `thunderjar.code-state-commit` label. It also adds the error for a code state commit that isn't in the developer's repository. A run from CI can name a commit that the developer hasn't pulled yet.
- 090 says the Thunderjar commit is "clearly marked" but not how. This story uses the author, the message and a fixed date. It also doesn't say whether untracked files belong in it. `git add -A` takes untracked files and leaves ignored ones (e.g. `node_modules`) out.
- 110's sample tags are uppercase, but git branch names are case-sensitive. The stories have used lowercase IDs since 1700, so the branch is lowercase too.

## How to test

Follow [the delivery testing strategy](testing-strategy.md) for fixtures, test placement, adapters and cleanup.

- Unit tests (layer 1 of [120](../spec/120-test-boundaries.md#1-pure-units)) for the new label in `postrunLabels`.
- CLI tests follow [the delivery testing strategy](testing-strategy.md), live beside `restore`, and invoke the real CLI from a disposable Git target cloned from checked-in history. Recording Docker reads unchanged scenario artifacts and supplies image labels and failures. Assert stdout, stderr, exit code, refs, index and worktree, with expected results in the tests:
  - each error case prints its message, issues no `start`, leaves the repository's refs, `HEAD`, index and working tree as they were, and exits non-zero
  - the happy path issues `imageLabels`, `start`, `exec` …, `copyOut` and `rm` in order, and `rm` is still issued when an `exec` fails
  - `show <container run>` prints the `Restore with:` line
- Docker image tests (layer 3.4) live beside `restore` as `restore.docker.test.ts`. Use real Docker, independently prepared scenario images and disposable Git targets cloned from the same tagged history. Apply checked-in work-in-progress artifacts to those targets, then invoke the real CLI. Remove all test-owned containers, images and target directories:
  - `postrun-committed`: the branch's history is `a1b2c3d` plus the fake agent's commit, `isPrime.ts` has the fake agent's content, there is no Thunderjar commit, and the repository is still on `main` with its work in progress unchanged
  - `postrun-uncommitted`: the branch ends in a Thunderjar commit holding the change, and restoring into a second throwaway repository gives the same SHA
  - afterwards the fixture image's ID is unchanged, and no container with the test's label remains
  - restoring again errors and leaves the branch where it was

- `bun test`
- `bun run test:prepare && bun run test:docker`
- `bun run typecheck`

## Human interventions

None.
