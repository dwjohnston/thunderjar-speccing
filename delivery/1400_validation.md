# 1400: Validation

`thunderjar plan <test case>` and `thunderjar generate` report bad configuration as a clear error naming the file and the problem, and exit non-zero, instead of a stack trace.

Areas: A

## Spec

- [055-declaring-test-cases.md](../spec/055-declaring-test-cases.md#declaration) — what a test case may name
- [051-configuration-folder-structure.md](../spec/051-configuration-folder-structure.md) — where each named thing must live
- [100-cli-reference.md](../spec/100-cli-reference.md#conventions) — exit codes

## Artifacts

- Hand-written checks in the config loader, run by `plan` and `generate`, for:
  - a name in a test case that has no matching folder or file (including when `_generated/` is stale)
  - an initial prompt that belongs to a different task
  - a declaration file with no default export, or one not wrapped in its `declareX`
  - a harness/model pair naming a model or version absent from its family
  - an empty array, or `iterations` that is not a positive integer
- Errors name the file, the field and the offending value
- Non-zero exit code on any configuration error

## How to test

Regular tests load a set of broken fixture `thunderjar/` folders, one per error above, and assert on stderr and the exit code.

- `bun test`

## Human interventions

None.
