# 1300: Declarations load, with generated types

`thunderjar plan <test case>` loads the configuration and lists the parameters the named test case selects. A misspelled parameter name in a test case is a TypeScript error.

Areas: A

## Spec

- [055-declaring-test-cases.md](../spec/055-declaring-test-cases.md) — `declareTestCase` and typed names
- [060-test-case-parameters.md](../spec/060-test-case-parameters.md#declarations-and-applyparameter) — the `declareX` functions
- [100-cli-reference.md](../spec/100-cli-reference.md#generate) — `generate` and `plan` usage

## Artifacts

- `declareBaseImage`, `declareCodeState`, `declarePromptSet`, `declareHarness` (with models and versions), `declareInitialPrompt` and `declareTestCase` functions
- Config loader that walks up to find `.thunderjar/`
- `thunderjar generate` command, which writes `_generated/parameter-names.d.ts`
- `thunderjar plan <test case>` command, which lists the parameters the test case names

```
$ thunderjar plan is-prime-baseline
baseImage:     node20
codeState:     baseline
promptSet:     snerk, glurk
harnessModel:  claude-code@2.1.283/haiku-4-5, codex@0.9.0/gpt-luna
task:          is-prime
initialPrompt: plain, terse
```

## How to test

Regular tests load a fixture `.thunderjar/` folder and assert on `plan <test case>` stdout. A type test asserts that a test case naming an unknown prompt set, or a model absent from its family, fails to compile.

- `bun test`
- `bun run typecheck`

## Human interventions

None.
