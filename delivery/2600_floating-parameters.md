# 2600: Floating parameters

A declaration's `determineHash` or `additionalHash` command runs once at the start of each execution, and its output feeds the parameter hash and `ctx.resolvedHash`. A harness version entry's `determineHash` gives the version. `plan`, `run` and `show` print what each floating parameter resolved to. When a floating parameter has moved since the test case's previous execution, `show` says so, and says the two executions aren't directly comparable.

Areas: B, A, E, F

## Spec

- [060-test-case-parameters.md](../spec/060-test-case-parameters.md#controlling-the-parameter-hash) — `additionalHash` / `determineHash`, precedence, and `ctx.resolvedHash`
- [060-test-case-parameters.md](../spec/060-test-case-parameters.md#parameters-that-follow-a-moving-target) — a moved target gives a different permutation hash
- [064-harness.md](../spec/064-harness.md#versions-and-overrides) — a floating version entry resolves only the version, once per entry per execution
- [030-terminology.md](../spec/030-terminology.md#floating-parameter) — a resolved value must always mean the same thing
- [110-cli-report-visualization.md](../spec/110-cli-report-visualization.md#plan) — the `main @ 3c1d9e2 (floating, resolved now)` line

## Artifacts

- `additionalHash?` and `determineHash?` on `declareBaseImage`, `declareCodeState`, `declarePromptSet` and `declareInitialPrompt`, and `determineHash?` as the alternative to `version` on a `declareHarnessVersions` entry. `ctx.resolvedHash` reaches `applyParameter` and `commit`. Nothing on the host uses those yet, because story 20 builds from them.
- `resolveHashCommands(selected, runCommand): Promise<ResolvedCommands>`. It runs each distinct command once, before the first permutation, and trims the output. The `runCommand` seam is stubbed in most tests. A command that exits non-zero or prints nothing stops the execution before anything runs, names the declaration and exits non-zero.
- The hash functions from [1600](delivered/1600_hashes.md) take the resolved output. `hashCodeState(path, resolved?)` and the other three hash the folder plus the output for `additionalHash`, or only the output for `determineHash`. `hashHarnessModelPair` uses the resolved version.
- `ContainerRunRecord.parameters[kind]` gains `resolved?: string` for any parameter with a command. `harnessModel.version` already holds the resolved version, and the parameter name keeps the entry name (`fake-harness-alpha@latest/fake-model-small`).
- `plan` resolves now, and so does `run --dry-run` from [1700](delivered/1700_dry-run.md), so the rendered `cli` shows the resolved `ctx.version`.
- `show <container run>` prints `main @ 3c1d9e2 (floating)` in its parameter list. `show <execution>` adds a `Moved since` block when a floating parameter resolved differently in the previous execution of the same test case, by `listExecutions` order. Story 19 (`compare`) does the side-by-side comparison.
- Fixtures: a checked-in project with a code state `main` whose `determineHash` reads `fixture-heads/main.txt`, and a `fake-harness-alpha` version entry `latest` that reads its checked-in version file. Its stored executions record both older resolved values and an unchanged value. Today's files are fixed; tests never edit them between commands. Additional checked-in declarations cover commands that fail or print nothing.

```
$ thunderjar plan fake-is-prime-main
baseImage:     node20 (a91c03e7)
codeState:     main @ 3c1d9e2 (8e41b07a, floating, resolved now)
promptSet:     snerk (3f2a91c0)
harnessModel:  fake-harness-alpha@latest/fake-model-small @ 1.0.0 (0b7c2e19, floating, resolved now)
…

$ thunderjar show fake-is-prime-main
Execution  01k4xc5w7r1ta6  (latest of fake-is-prime-main)
Test case  fake-is-prime-main
Task       is-prime
Date       2026-09-30 09:10

Moved since 01k4x9j2e8mqz3 (2026-09-29)
  codeState  main  3c1d9e2 -> 7a0f4b1
  Permutation hashes differ, so these results are not directly comparable.

Permutation b41d06f2  (2 iterations)
  node20 | main @ 7a0f4b1 | snerk | fake-harness-alpha@latest/fake-model-small @ 1.0.0 | plain
…
```

Out of scope (story numbers are backlog positions): building from `ctx.resolvedHash` and checking out the resolved commit (story 20); `compare` (story 19); resolving in CI, where `origin/main` is only as fresh as the last fetch (story 29).

**Spec gaps.**

- The spec doesn't say which directory the command runs in. 064's `cat ./harness-versions/…` and 062's `git rev-parse origin/main` both suggest the project root (the parent of `.thunderjar/`). This story uses the project root.
- The spec doesn't say what happens when the command fails or prints nothing. This story stops the execution before any run, since an empty hash would make unrelated states look identical.
- `ContainerRunRecord.parameters` keeps only the name and the hash, so a stored run can't say which commit `main` was. This story adds `resolved`.
- "The report flags comparisons across a moving target" (backlog) has no spec counterpart before `compare`. The `Moved since` block is a light addition, and story 19 may replace it.

## How to test

Follow [the delivery testing strategy](testing-strategy.md) for fixtures, test placement, adapters and cleanup.

- Unit tests (layer 1 of [120](../spec/120-test-boundaries.md#1-pure-units)), with `runCommand` stubbed:
  - `determineHash` ignores folder edits
  - `additionalHash` changes the hash when either the folder or the output changes
  - with both, `determineHash` wins
  - a floating version entry changes the pair hash only through its version
  - a command shared by several permutations runs once
  - a failing or empty command gives a clear error
- CLI tests follow [the delivery testing strategy](testing-strategy.md), using unchanged scenarios and the real shell. `plan` and `run --dry-run` resolve today's checked-in values. `show` reads checked-in execution history containing differing resolved values and prints `Moved since`; another history case with equal values prints no block and keeps the same permutation hash. A fresh `run`, when needed, writes to an external `--data-dir` and is compared with checked-in historical values. Assert stdout, stderr, exit code and stored resolutions; do not stub the CLI's clock or ULID generator or edit target files.

- `bun test`
- `bun run typecheck`

## Human interventions

None.
