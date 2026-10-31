# 1700: Dry run

`thunderjar run <test case> --dry-run` creates an execution ID, then walks every permutation and iteration in order and prints the container run it would do, including the harness command, without running anything.

Areas: F, C

## Spec

- [100-cli-reference.md](../spec/100-cli-reference.md#run) — `run` usage and output
- [030-terminology.md](../spec/030-terminology.md) — execution ID (a ULID) and postrun tag format
- [064-harness.md](../spec/064-harness.md#cli-running-the-agent) — the `cli` command and its context
- [080-docker-execution.md](../spec/080-docker-execution.md#process) — the per-permutation, per-iteration loop

## Artifacts

- `thunderjar run <test case>` command, with `--dry-run` as its only mode for now
- The run loop: permutations in the stable order from [1500](1500_permutations.md), iterations inside each
- A new execution ID (ULID) per invocation
- For each container run: its postrun image name and the harness `cli` command rendered with the resolved pair and initial prompt

```
$ thunderjar run is-prime-baseline --dry-run
Execution 01k4x9j2e8mqz3 (dry run, 8 permutations × 5 iterations)

Permutation 1/8  node20 | baseline | snerk | claude-code@2.1.283/haiku-4-5 | plain
  prerun-h4f9a21c8
  iteration 1/5  postrun-e01k4x9j2e8mqz3-h4f9a21c8-i1
    claude -p "Write an isPrime function…" --model claude-haiku-4-5-20251001 … > /result/result.json
  iteration 2/5  …
```

## How to test

Regular tests run `run --dry-run` against a fixture test case and assert on stdout, with the ULID generator stubbed so output is deterministic. Nothing is written to disk.

- `bun test`

## Human interventions

None.
