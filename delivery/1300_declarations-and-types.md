# 1300: Declarations load, with generated types

`thunderjar plan` loads the configuration and lists the parameters, tasks and experiments it found. A misspelled parameter name in an experiment is a TypeScript error.

Areas: A

## Artifacts

- `declareBaseImage`, `declareCodeState`, `declarePromptSet`, `declareHarness` (with models and versions), `declareInitialPrompt` and `declareExperiment` functions
- Config loader that walks up to find `thunderjar/`
- `thunderjar generate` command, which writes `_generated/parameter-names.d.ts`
- `thunderjar plan` command, which lists what was found

## How to test

Regular tests load a fixture `thunderjar/` folder and assert on `plan` stdout. A type test asserts that an experiment naming an unknown prompt set, or a model absent from its family, fails to compile.

- `bun test`
- `bun run typecheck`

## Human interventions

None.
