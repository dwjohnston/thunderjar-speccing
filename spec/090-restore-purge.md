# Restore / Purge

Lifecycle management: restoring a container run from its preserved postrun image, purging old ones.

## Restore

Restore brings the end state of one container run into the developer's own repository as a branch, so they can inspect it, reproduce a problem, or iterate from it (see [Regression triage](040-user-experience.md#regression-triage)).

```
thunderjar restore <container run>
```

### What it does

Restore is run from inside a git repository and acts on that repository. It does not create a new directory or a second clone.

Given a developer in `/Users/my-name/git-workspace/my-project`, on branch `main`:

```
thunderjar restore container-run-123
```

1. The commits the agent made on top of the code state's commit are fetched into the developer's repository. The developer's repository already has that commit (see [062-code-state.md](062-code-state.md#how-the-code-gets-into-the-image)).
2. A branch `thunderjar/container-run-123` is created, pointing at the run's end state.
3. The developer is left on `main`. Their working tree and index are not touched.

Because restore never touches the working tree, it is safe to run with uncommitted work in progress. The developer checks the branch out when they are ready.

### Uncommitted changes: the Thunderjar commit

A branch only carries commits, but an agent can finish with changes it never committed. If the postrun image's working tree has uncommitted changes, restore adds one extra commit on top of the agent's last commit, the **Thunderjar commit**, holding those changes. The branch points at it.

- The Thunderjar commit is clearly marked as made by Thunderjar, not by the agent, so the agent's own history stays distinguishable from it.
- If the working tree is clean, no Thunderjar commit is added and the branch points at the agent's last commit.
- The commit is created during restore. The postrun image itself is never modified, so it stays exactly the agent's end state.

### Errors

Restore fails with a clear message, and changes nothing, when:

- the branch `thunderjar/<container run>` already exists. It is never overwritten.
- the current directory is not inside a git repository.
- no postrun image exists for the given container run.

## Purge

Out of scope. There is no retention or purge policy (see [020-goals-non-goals.md](020-goals-non-goals.md)).

