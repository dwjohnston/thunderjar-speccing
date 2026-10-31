# 1100: Base tooling

The repository has Bun, TypeScript and oxlint set up, with one script each to lint, type-check and test, and a CI pipeline that runs them.

Areas: outside the six (building Thunderjar itself)

## Spec

- [140-tooling.md](../spec/140-tooling.md) — Bun, TypeScript, linting
- [150-repository-layout.md](../spec/150-repository-layout.md) — `src/` and test placement

## Artifacts

- Base regular files `package.json`, `tsconfig.json` etc. 
- oxlint tooling
- typescript tooling 
- bun tooling
- `.github/workflows/ci.yml` — on pull requests to `main`, installs with Bun and runs `bun run lint`, `bun run typecheck` and `bun test`

## How to test

Regular scripts, run from a clean checkout after `bun install`. CI runs the same three scripts.

- `bun run lint`
- `bun run typecheck`
- `bun test`

## Human interventions

- 👷‍♂️ Open a pull request and expect the CI checks to pass.
- 👷‍♂️ Optionally, make the CI check required in the repository's branch protection settings.
