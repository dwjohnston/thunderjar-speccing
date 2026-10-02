# Configuration Folder Structure

Where Thunderjar configuration lives inside a user's project. What goes in each file is
elsewhere: experiments in [055-declaring-experiments.md](055-declaring-experiments.md),
parameters in [060-experiment-parameters.md](060-experiment-parameters.md).

## Example project

```
my-app/
├── src/                                   # the user's codebase — what code states check out
├── prompts/
│   ├── snerk.md                           # prompt files — what prompt sets check out
│   └── glurk.md
└── thunderjar/
    ├── package.json                       # only for non-JS projects; created by `init`
    ├── .gitignore                         # created by `init`: _generated/, .data/ (+ node_modules/ if nested)
    ├── thunderjar.config.ts               # global config: stores, registry, test runner
    ├── experiments/
    │   └── is-prime-baseline.ts           # declareExperiment(...)
    ├── experiment-parameters/
    │   ├── baseImages/
    │   │   └── node20/
    │   │       └── index.ts               # declareBaseImage(...)
    │   ├── codeStates/
    │   │   ├── baseline/
    │   │   │   └── index.ts               # declareCodeState(...)
    │   │   └── with-fixture/
    │   │       ├── index.ts
    │   │       └── seed-fixture-data.sh   # bundled — part of the parameter hash
    │   ├── promptSets/
    │   │   ├── snerk/
    │   │   │   └── index.ts               # declarePromptSet(...)
    │   │   └── glurk/
    │   │       └── index.ts
    │   ├── harnessModels/
    │   │   └── claude-code/               # family; yields multiple pairs
    │   │       ├── index.ts               # declareHarness(...): shared execution
    │   │       ├── models.ts              # declareHarnessModels(...): name → ID
    │   │       ├── versions.ts            # declareHarnessVersions(...): version + overrides
    │   │       └── collectTokenCosts.ts   # declareTokenCostCollector(...): interpretation
    │   └── tasks/
    │       └── is-prime/
    │           ├── initial-prompts/
    │           │   ├── plain.ts           # declareInitialPrompt(...). Hashed.
    │           │   └── terse.ts
    │           └── measurements/          # NOT hashed
    │               ├── isPrimeTsExists.ts
    │               ├── isPrimeTestExists.ts
    │               ├── isPrimeTemplateTest.ts
    │               └── isPrime.test.template.ts
    └── _generated/
        └── parameter-names.d.ts           # generated from names and family maps above; git-ignored
```

## What lives where

- **The user's own files stay where they are.** Code and prompt files live in the normal
  project tree. Code state and prompt set declarations point at them by pinned commit
  rather than copying them into `thunderjar/`.
- **One folder per base image, code state or prompt set**, under its kind folder. Its
  name selects it; its content — `index.ts` plus bundled files — determines its hash.
- **One folder per harness family**, under `experiment-parameters/harnessModels/`.
  Version and model maps yield values addressed as `family@version/model`, such as
  `claude-code@2.1.283/haiku-4-5`. The [family declaration](064-harness.md#family-declaration)
  defines these files; [pair hashing](064-harness.md#hashing) uses shared execution
  content and only the selected map entries.
  _(Referenced by: [030-terminology.md](030-terminology.md),
  [004-addressing-harness-model-pair.md](004-addressing-harness-model-pair.md).)_
- **A task folder holds the task's initial prompts and its measurements.** The folder
  name is the task. `initial-prompts/` has one file per wording, and each is an
  experiment parameter value, hashed on its own. `measurements/` holds the task
  measurements, shared by every initial prompt of the task. They live together because
  measurements are meaningless apart from their task, but `measurements/` is **excluded
  from every parameter hash**: measurements don't affect the prerun or postrun image, so
  changing them must not change the permutation hash.
- **One file per measurement, named by its file.** `isPrimeTsExists.ts` is the
  measurement `isPrimeTsExists`. Supporting files, like a `templateTest` template, sit
  alongside.
- **Experiments live outside `experiment-parameters/`.** An experiment isn't a parameter;
  it's a matrix over them.
- **Generated types live in `_generated/`.** They are built from the folder names above
  and git-ignored — see
  [055-declaring-experiments.md](055-declaring-experiments.md#typed-names).

## Open questions

- What else `thunderjar.config.ts` holds beyond the stores and test runner.

`thunderjar/` is a fixed location, found by walking up from the current directory. See
[050-setup-and-configure.md](050-setup-and-configure.md#install-and-init).
