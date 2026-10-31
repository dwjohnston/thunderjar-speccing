# Tooling

The tools Thunderjar is built with, and the one custom script that keeps its folder
structure honest. The structure itself is in
[150-repository-layout.md](150-repository-layout.md).

Everything below is a proposal. No code exists yet.

| Concern | Tool |
|---|---|
| Runtime, package manager, test runner | Bun (`bun test`) |
| Language | TypeScript |
| Build | `bun build`, with `tsc` for type declarations |
| Docker and git | Their command-line tools, run with `Bun.spawn` |
| Run data store driver | `bun:sqlite` |
| Hashing | `Bun.CryptoHasher` |
| CLI argument parsing | Commander |
| Linting | oxlint |
| Folder-structure enforcement | `scripts/sync-oxlint-layout.ts`, which writes rules into the oxlint config |
| Versioning and release notes | Changesets (`.changeset/`) |
| CI | GitHub Actions |
| Dependency updates | Dependabot |
| Documentation | VitePress, hosted on GitHub Pages |

- **Bun** runs the CLI, the scripts and the tests, with no build step in development. It is
  also what Thunderjar ships on; see [141-runnable-artifact.md](141-runnable-artifact.md).
  Tests are `*.test.ts` files run by `bun test`, laid out as in
  [150-repository-layout.md](150-repository-layout.md).
- **TypeScript** throughout, type-checked with `tsc --noEmit`. Bun runs the code but does not
  check it.
- **Build.** `bun build` bundles the CLI and library into `dist/`. It does not emit type
  declarations, so `tsc --emitDeclarationOnly` produces the `.d.ts` files for the
  `declareX()` functions that [141-runnable-artifact.md](141-runnable-artifact.md) ships.
- **Docker and git** are driven by running the `docker` and `git` command-line tools with
  `Bun.spawn`, not through an API library. This is what lets the recording adapters in
  [120-test-boundaries.md](120-test-boundaries.md) print the commands they would have run,
  and it uses the user's existing `docker login`.
- **`bun:sqlite`** is the driver behind `sqliteStore`
  ([050-setup-and-configure.md](050-setup-and-configure.md#thunderjarconfigts)). It is
  built into Bun, so there is no dependency to install.
- **`Bun.CryptoHasher`** computes the SHA-256 behind parameter hashes
  ([060-test-case-parameters.md](060-test-case-parameters.md)). Bun has no canonical-JSON
  function, so key-order independence is Thunderjar's own code.
- **Commander** defines the commands in [100-cli-reference.md](100-cli-reference.md). Each
  command is one file under `src/commands/`, registered by the entry point in `src/cli/`.
- **oxlint** lints the code, configured by `.oxlintrc.json`. It does not format; formatting is
  an open question below.
- **Changesets** versions and publishes the `thunderjar` package described in
  [141-runnable-artifact.md](141-runnable-artifact.md). A change that affects users adds a
  file under `.changeset/` saying which bump it needs and what to put in the changelog.
  Releasing consumes those files, bumps the version and writes `CHANGELOG.md`. The
  `package.json` scripts `changeset`, `version` and `release` wrap the Changesets CLI.
- **Dependabot** opens pull requests for outdated npm packages and GitHub Actions versions.
- **GitHub Actions** runs three workflows:
  - **CI** (`ci.yml`). On a pull request to `main`: install with Bun, `bun run lint` (which
    includes the layout sync check below), `bun run typecheck` and `bun test`. On a push to
    `main`: `bun run build`.
  - **Release** (`release.yml`). On a push to `main`, `changesets/action` either opens a
    "Version Packages" pull request, when changesets are waiting, or publishes to npm, when
    that pull request has just been merged. It runs after Bun installs and builds, with Node
    set up as well because the action shells out to `npm`.
  - **Docs** (`docs.yml`). Described below.
- **VitePress** builds the documentation site, with `docs:dev`, `docs:build` and
  `docs:preview` scripts.
- **GitHub Pages** hosts it. The docs workflow builds the site and deploys it using
  `actions/upload-pages-artifact` and `actions/deploy-pages`, so no `gh-pages` branch is
  kept. It runs only when a pull request merged into `main` carries the `update-docs`
  label, or when triggered by hand. The release workflow adds that label to every
  "Version Packages" pull request, so docs are deployed per release, and a docs-only fix is
  deployed by labelling its pull request.

## Enforcing folder structure

oxlint's built-in rules cover naming and imports, not where a file may live. What it offers
instead is scoping: `overrides` apply a rule's options to a set of globs. The script turns a
description of the layout into that scoping.

### How it works

1. The layout is written once, as data, in `scripts/layout.ts`: each folder under `src/` and
   `test/`, what it may contain, and what it may import from. An entry covers the files
   directly inside its folder, so no two entries match the same file.
2. `scripts/sync-oxlint-layout.ts` reads that file and rewrites the generated section of
   `.oxlintrc.json`.
3. `bun run lint` runs the script, then `oxlint`. CI additionally fails if running the
   script changes `.oxlintrc.json`, so the committed config can't drift from the layout.

```ts
// scripts/layout.ts
export const layout = {
  "src/cli": { allowedFiles: ["*.ts"], mayImport: ["src/commands"] },
  "src/commands": { allowedFiles: ["*.ts"], mayImport: ["src/adapters", "src/hashing"] },
  "src/adapters/docker": { allowedFiles: ["real.ts", "recording.ts", "index.ts"] },
};
```

The script owns one marked region of `.oxlintrc.json` and leaves the rest alone, so
hand-written settings are untouched:

```jsonc
{
  "rules": { "eqeqeq": "error" },                 // hand-written

  // sync-oxlint-layout: begin — generated, do not edit
  "overrides": [
    {
      "files": ["src/cli/*.ts"],
      "rules": {
        "no-restricted-imports": ["error", {
          "patterns": [{ "group": ["**/adapters/**"], "message": "src/cli may not import adapters" }]
        }]
      }
    }
  ]
  // sync-oxlint-layout: end
}
```

`.oxlintrc.json` permits comments, which is what lets the markers sit inside the file. Whether
the script edits the file textually between markers, or parses and re-serialises it, is open
below.

### What it enforces

- **Import direction between folders.** Generated as per-folder `no-restricted-imports`
  overrides, with a `patterns` entry for every folder the layout does not list in `mayImport`.
- **File names within a folder.** Generated as per-folder `unicorn/filename-case` overrides.
  This covers the casing of names only, not which names are allowed.
- **Files in the wrong place.** oxlint has no rule for this, so `sync-oxlint-layout.ts
  --check` reports any file under `src/` or `test/` that matches no entry's `allowedFiles`,
  with a message naming [150-repository-layout.md](150-repository-layout.md). `bun run lint`
  runs it.

## Open questions

- **Formatting.** oxlint does not format. Options: *oxfmt* (the Oxc project's formatter, from
  the same toolchain), *prettier*, or *none*.
- **Editing the config.** *textual-markers* (replace the text between the markers) or
  *reserialise* (parse the file and write it back, losing hand-written comments).
- **Wrong-place check.** *script-checked* (as above) or *js-plugin* (an oxlint JS plugin that
  reports on the program node of files in uncovered folders, so the error appears in the
  editor). The JS plugin API is in alpha.
- **Override merging.** How oxlint combines options when more than one override matches a
  file is undocumented; the layout avoids it by giving each file one entry. Verify by test
  before relying on it.
