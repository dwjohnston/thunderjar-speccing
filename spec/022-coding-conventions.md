# Coding Conventions

Conventions for the TypeScript a Thunderjar user writes — parameter declarations,
task declarations, experiment declarations — and so for every example of that code in
this spec.

## `declareX()` functions, not bare exports

A Thunderjar configuration file's default export is always wrapped in the `declareX()`
function for its kind. Never a bare object, and never typed with `satisfies`, a type
assertion (`as`), or a type annotation (`const harness: Harness = …`).

```ts
// experiment-parameters/harnesses/claude-code/index.ts
export default declareHarness({
  version: "2.1.283",
  applyParameter: () => `RUN npm install -g @anthropic-ai/claude-code@2.1.283`,
  cli: (ctx) => `claude -p "${ctx.initialPrompt}" > ${ctx.resultPath}`,
  collectTokenCosts: (raw) => { /* … */ },
});
```

Not any of these:

```ts
export default { version: "2.1.283", /* … */ };                        // untyped
export default { version: "2.1.283", /* … */ } satisfies Harness;     // satisfies
export default { version: "2.1.283", /* … */ } as Harness;            // assertion
const harness: Harness = { version: "2.1.283", /* … */ };             // annotation
export default harness;
```

Why a function:

- **The types come for free.** `ctx` and `raw` above are typed by the function's
  parameter, with nothing written at the call site. A bare object gets none of that.
- **It's the only form that can't be got subtly wrong.** `as` silences errors instead of
  reporting them; `satisfies` and annotations are easy to forget, and forgetting them
  compiles fine.
- **One obvious way to write it.** Every declaration in a project reads the same, which
  matters when declarations are the main thing a user writes.

A helper defined above the call — `const version = "2.1.283";` — is fine. The rule is
about how the export is typed, not about avoiding `const`.

One function per kind:

| Kind | Function |
|---|---|
| Base image | `declareBaseImage` |
| Code state | `declareCodeState` |
| Prompt set | `declarePromptSet` |
| Harness | `declareHarness` |
| Model | `declareModel` |
| Initial prompt | `declareInitialPrompt` |
| Measurement | `declareMeasurement` |
| Experiment | `declareExperiment` |

Measurement and experiment aren't experiment parameters — a measurement is associated
with a task, and an experiment is a matrix *over* parameters, not one of them — but
their files are Thunderjar configuration all the same, so the same rule applies.

## Generated files go in `_generated/`, and are git-ignored

Anything Thunderjar generates — such as the parameter-name types described in
[055-declaring-experiments.md](055-declaring-experiments.md#typed-names)
— is written to a `_generated/` folder, never edited by hand, and never committed.

```
thunderjar/
└── _generated/
    └── parameter-names.d.ts
```

```gitignore
# .gitignore
thunderjar/_generated/
```

- **Underscore, not a dot.** A dot-folder is hidden from most file listings and editors;
  generated types are something a user should be able to find and read when a name
  doesn't type-check. The underscore still marks the folder as not-yours.
- **Git-ignored**, because it is derived entirely from the folder structure. Committing it
  invites a stale copy that disagrees with the folders it was generated from.


## Verification

Demo: [`scratchpad/verification/022-declare-functions/`](../scratchpad/verification/022-declare-functions/test.sh)
(output in `output.txt`; run with `tsc` 6.0.2 `--strict` and git).

- **Verified by demo:** `ctx`/`raw` are inferred through a `declareX(h: X)` function and a bare object gets
  implicit `any`; `as` compiles with a required field missing; `satisfies` reports a wrong field type;
  a bare object with no annotation compiles with the wrong shape; `declareX` reports the same wrong type;
  `thunderjar/_generated/` in `.gitignore` ignores the generated file.
- **Docs (not fetched; the sandbox proxy blocked typescriptlang.org and git-scm.com):**
  [`satisfies`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-9.html),
  [type assertions](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#type-assertions),
  [gitignore patterns](https://git-scm.com/docs/gitignore).
- **Nuance:** `as` is not always silent. TypeScript rejects assertions between types that don't
  sufficiently overlap (TS2352), so it only hides errors such as a missing required field.
- **Not verified:** the `@anthropic-ai/claude-code` package name and the `claude -p` flag are taken from the
  example and belong to [064-harness.md](064-harness.md); `2.1.283` is an illustrative version.
