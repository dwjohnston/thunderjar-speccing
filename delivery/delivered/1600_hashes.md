# 1600: Hashes

`thunderjar plan <test case>` also prints each parameter's hash and each permutation's permutation hash. Renaming a parameter's folder keeps its hash; editing its content changes it.

Areas: B, A

## Spec

- [060-test-case-parameters.md](../spec/060-test-case-parameters.md#parameter-hashing-and-identity) — what is hashed, and how it combines
- [064-harness.md](../spec/064-harness.md#hashing) — the harness/model pair boundary
- [081-docker-tagging.md](../spec/081-docker-tagging.md) — the abbreviated hash used in tags

## Artifacts

- `hashBaseImage(path)`
- `hashCodeState(path)`
- `hashPromptSet(path)`
- `hashInitialPrompt(path)`
- `hashHarnessModelPair(family, version, model)`
- `hashPermutation(hashes)` — combines the five parameter hashes
- `thunderjar plan <test case>` output, building on [1300](1300_declarations-and-types.md) and [1500](1500_permutations.md): each parameter name is followed by its 8-character hash, and each permutation is followed by the name of its prerun image, which carries the 8-character abbreviated permutation hash (see [081-docker-tagging.md](../spec/081-docker-tagging.md#tag-formats)):

```
$ thunderjar plan is-prime-baseline
baseImage:     node20 (a91c03e7)
codeState:     baseline (5be2d814)
promptSet:     snerk (3f2a91c0), glurk (b71e44d2)
harnessModel:  claude-code@2.1.283/haiku-4-5 (0d6f7a3b), codex@0.9.0/gpt-luna (c48e1f92)
task:          is-prime
initialPrompt: plain (e2907b55), terse (7a13c6d8)

Matrix shape: 1/1/2/2/2 (8 permutations × 5 iterations = 40 container runs)

 1  node20 | baseline | snerk | claude-code@2.1.283/haiku-4-5 | plain
    prerun-h4f9a21c8

 2  node20 | baseline | snerk | claude-code@2.1.283/haiku-4-5 | terse
    prerun-h9c2e07ab

 3  node20 | baseline | snerk | codex@0.9.0/gpt-luna          | plain
    prerun-h27d5e63f

 4  node20 | baseline | snerk | codex@0.9.0/gpt-luna          | terse
    prerun-h6b81a0d4

 5  node20 | baseline | glurk | claude-code@2.1.283/haiku-4-5 | plain
    prerun-hd30f84c1

 6  node20 | baseline | glurk | claude-code@2.1.283/haiku-4-5 | terse
    prerun-h18ae7b92

 7  node20 | baseline | glurk | codex@0.9.0/gpt-luna          | plain
    prerun-hf5c460e8

 8  node20 | baseline | glurk | codex@0.9.0/gpt-luna          | terse
    prerun-h82e19d3a
```

## How to test

Pure unit tests, no CLI needed, over fixture folders:

- the same content gives the same hash, and key ordering does not matter
- editing `index.ts` changes the hash; renaming the folder does not
- adding a model to a family does not change existing pairs; changing one model's ID changes only that model's pairs
- editing `collectTokenCosts.ts` changes nothing

One CLI test runs `plan` against a deterministic fixture test case and asserts that stdout exactly matches the example above. A changed hash is a change to execution identity, so a failure here is a tripwire, not noise.

- `bun test`

## Human interventions

None.
