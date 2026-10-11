# 1500: Permutations

`thunderjar plan <test case>` also prints the matrix shape, each permutation with the names of its five parameters, and the total number of container runs.

Areas: A

## Spec

- [060-test-case-parameters.md](../spec/060-test-case-parameters.md) — the five parameters
- [055-declaring-test-cases.md](../spec/055-declaring-test-cases.md#a-test-case-is-a-matrix) — the matrix is a cross product
- [030-terminology.md](../spec/030-terminology.md#matrix-shape) — matrix shape notation
- [100-cli-reference.md](../spec/100-cli-reference.md#plan) — `plan` usage

## Artifacts

- `thunderjar plan <test case>` takes a test case name
- Permutation expansion: the cross product of the five arrays, in a stable order
- `plan` output, after the parameter lists from [1300](1300_declarations-and-types.md): matrix shape (e.g. `1/1/2/2/2`), one line per permutation, and the container run count (permutations × iterations)

```
$ thunderjar plan is-prime-baseline
baseImage:     node20
codeState:     baseline
promptSet:     snerk, glurk
harnessModel:  claude-code@2.1.283/haiku-4-5, codex@0.9.0/gpt-luna
task:          is-prime
initialPrompt: plain, terse

Matrix shape: 1/1/2/2/2 (8 permutations × 5 iterations = 40 container runs)

 1  node20 | baseline | snerk | claude-code@2.1.283/haiku-4-5 | plain
 2  node20 | baseline | snerk | claude-code@2.1.283/haiku-4-5 | terse
 3  node20 | baseline | snerk | codex@0.9.0/gpt-luna          | plain
 4  node20 | baseline | snerk | codex@0.9.0/gpt-luna          | terse
 5  node20 | baseline | glurk | claude-code@2.1.283/haiku-4-5 | plain
 6  node20 | baseline | glurk | claude-code@2.1.283/haiku-4-5 | terse
 7  node20 | baseline | glurk | codex@0.9.0/gpt-luna          | plain
 8  node20 | baseline | glurk | codex@0.9.0/gpt-luna          | terse
```

## How to test

Regular unit tests run `plan` against fixture test cases and assert on stdout: a `1/1/1/1/1` case gives one permutation, and the example above gives eight.

- `bun test`

## Human interventions

None.
