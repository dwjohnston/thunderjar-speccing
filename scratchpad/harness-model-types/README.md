# Harness/model pair types

A small type-checking demo of the pair union described in
[Declaring Experiments](../../spec/055-declaring-experiments.md#typed-pairs).
It accepts mixed families, versions and models in one experiment and rejects unknown
families, versions, models, incomplete pairs and separate harness/model arrays.

```sh
bun install
bunx --bun tsc --noEmit
```

Each `@ts-expect-error` verifies a rejected declaration. Removing a required type error
makes the type check fail.
