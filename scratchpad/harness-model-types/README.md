# Harness/model pair types

A small type-checking demo of the pair union described in
[Declaring Test Cases](../../spec/055-declaring-test-cases.md#typed-pairs).
It accepts mixed families, versions and models in one test case and rejects unknown
families, versions, models, incomplete pairs and separate harness/model arrays.

```sh
bun install
bunx --bun tsc --noEmit
```

Each `@ts-expect-error` verifies a rejected declaration. Removing a required type error
makes the type check fail.
