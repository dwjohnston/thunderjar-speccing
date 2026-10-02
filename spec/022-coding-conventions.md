# Coding Conventions

Conventions for the TypeScript a Thunderjar user writes — parameter declarations,
task declarations, experiment declarations — and so for every example of that code in
this spec.

## `declareX()` functions, not bare exports

A Thunderjar configuration file's default export is always wrapped in the `declareX()`
function for its kind. Never a bare object, and never typed with `satisfies`, a type
assertion (`as`), or a type annotation (`const harness: Harness = …`).

```ts
// experiment-parameters/harnessModels/claude-code/index.ts
export default declareHarness({
  applyParameter: (ctx) => `RUN npm install -g @anthropic-ai/claude-code@${ctx.version}`,
  cli: (ctx) => `claude -p "${ctx.initialPrompt}" > ${ctx.resultPath}`,
});
```

Not any of these:

```ts
export default { cli: (ctx) => "claude", /* … */ };                        // untyped
export default { cli: (ctx) => "claude", /* … */ } satisfies Harness;     // satisfies
export default { cli: (ctx) => "claude", /* … */ } as Harness;            // assertion
const harness: Harness = { cli: (ctx) => "claude", /* … */ };             // annotation
export default harness;
```

Why a function:

- **The types come for free.** `ctx` above is typed by the function's
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
| Harness family | `declareHarness` |
| Family model map | `declareHarnessModels` |
| Family version map | `declareHarnessVersions` |
| Token-cost collector | `declareTokenCostCollector` |
| Initial prompt | `declareInitialPrompt` |
| Measurement | `declareMeasurement` |
| Experiment | `declareExperiment` |

The family, maps and collector form a [family declaration](064-harness.md#family-declaration);
the selected pair is the parameter value.

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
- **Git-ignored**, because it is derived from declaration names and family maps. Committing it
  invites a stale copy that disagrees with the folders it was generated from.

