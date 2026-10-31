# 1125: Layout enforcement

`bun run lint` fails when a file is in the wrong place, is named wrongly for its folder, or imports from a folder it may not.

Areas: outside the six (building Thunderjar itself)

## Spec

- [140-tooling.md](../spec/140-tooling.md#enforcing-folder-structure) — the layout script and what it enforces
- [150-repository-layout.md](../spec/150-repository-layout.md) — the layout being enforced

## Artifacts

- `scripts/layout.ts` — the layout as data: per folder, `allowedFiles` and `mayImport`
- `scripts/sync-oxlint-layout.ts` — writes `no-restricted-imports` and `unicorn/filename-case` overrides into the marked region of `.oxlintrc.json`
- `scripts/sync-oxlint-layout.ts --check` — fails on any file under `src/` or `test/` that matches no entry's `allowedFiles`
- `lint` script runs the sync, the check, then `oxlint`
- CI step that fails if the sync changes `.oxlintrc.json`

## How to test

Regular unit tests run the script against fixture layouts and assert on the generated config and the check's output. Each rule has a case that must fail: a forbidden import, a misnamed file, a file in an uncovered folder.

- `bun test`
- `bun run lint`

## Human interventions

None.
