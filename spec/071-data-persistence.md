# Data Persistence

Open questions about how the run data store is kept and shared across machines. The stores
themselves are described in [070-data-architecture.md](070-data-architecture.md); the
store interface and `sqliteStore` in
[050-setup-and-configure.md](050-setup-and-configure.md#thunderjarconfigts).

## Open questions

- **Sharing the run data store between CI and a developer's machine.** With only
  `sqliteStore` in v1, regression triage needs a manual way to share the file. Triage
  ([040-user-experience.md](040-user-experience.md#regression-triage)) starts from a run
  CI recorded and ends with a developer restoring it locally, so the developer's machine
  has to see CI's runs. The image store is already shared through the registry, but it
  holds the images and not the run metadata that says which image is which.

  Options, none settled:
  - **Pass the file around.** CI uploads it as an artifact and a developer downloads it.
    Needs no new code, but it is manual, and two sides writing at once can't be merged.
  - **Commit the file.** Shared through git, but it is binary, so concurrent writes
    conflict.
  - **Sync to an object store** (e.g. S3) before and after a run. Automatable, still has
    the concurrent-write problem.
  - **Ship a remote store in v1** (e.g. `postgresStore({ urlEnv })`), which removes the
    problem. The cost is more v1 scope.

## Verification

- **Commit the file** (binary, concurrent writes conflict): confirmed. Git cannot merge
  binary files ([gitattributes: binary](https://git-scm.com/docs/gitattributes#_marking_files_as_binary));
  demo: [scratchpad/verification/071-sqlite-git-conflict/](../scratchpad/verification/071-sqlite-git-conflict/test.sh)
  ([output](../scratchpad/verification/071-sqlite-git-conflict/output.txt)) shows two branches
  writing to a SQLite file ending in `CONFLICT ... Cannot merge binary files`.
- Remaining claims (CI artifacts, S3 sync, registry sharing images) are design choices or
  generic; nothing further to verify.
