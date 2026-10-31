# Declaring Test Cases

How a test case is declared: which parameters it runs, and how its names are
type-checked. Where the file lives is in
[051-configuration-folder-structure.md](051-configuration-folder-structure.md); what each
parameter is, in [060-test-case-parameters.md](060-test-case-parameters.md).

## Declaration

Lives at `.thunderjar/test-cases/<name>.ts`.

```ts
// .thunderjar/test-cases/is-prime-baseline.ts
export default declareTestCase({
  baseImage: ["node20"],
  codeState: ["baseline"],
  promptSet: ["snerk", "glurk"],
  harnessModel: ["claude-code@2.1.283/haiku-4-5", "codex@0.9.0/gpt-luna"],
  task: "is-prime",
  initialPrompt: ["plain", "terse"],
  iterations: 5,
});
```

| Field | What it is |
|---|---|
| `baseImage` | [Base images](061-base-image.md) to run. |
| `codeState` | [Code states](062-code-state.md) to run. |
| `promptSet` | [Prompt sets](063-prompt-set.md) to run. |
| `harnessModel` | [Harness/model pairs](064-harness.md#addressing-a-pair) to run. |
| `task` | The [task](066-task.md) the test case is about. One name, not an array. |
| `initialPrompt` | The task's [initial prompts](066-task.md#initial-prompts) to run. |
| `iterations` | How many times each permutation runs. |

Each parameter field is an array of names. Base image, code state and prompt set names select
folders under `test-case-parameters/`. A harness/model name selects a family, version
and model as [defined on the family](064-harness.md#family-declaration). Initial prompt
names select files under the chosen task's `initial-prompts/` folder.

## A test case is a matrix

The five arrays form a cross product, and each combination is one permutation. The
example above has eight: two prompt sets × two harness/model pairs × two initial prompts,
with base image and code state held fixed.

Permutations are listed in a stable order: the arrays are walked in the field order of the
declaration, with the last varying fastest. This is the order `plan` prints them in. It
does not guarantee the order they execute in.
_(Referenced by: [004-addressing-harness-model-pair.md](004-addressing-harness-model-pair.md),
[100-cli-reference.md](100-cli-reference.md#plan).)_

## One task, not measurements

The test case names one task, not measurements. Measurements come with the task (see
[066-task.md](066-task.md#task-measurements)), so a second test case using `is-prime`
gets the same measurements without copying them.

Naming one task means every permutation is judged by the same measurements, so every
result in the test case can be compared with every other. Results for different tasks
can't be, so running a harness across several tasks is several test cases.

## Typed names

The strings in `declareTestCase` are not free text. A generation step reads
parameter names and harness family maps under `test-case-parameters/`, emitting
their union types into
`_generated/parameter-names.d.ts`, so a misspelled or deleted parameter is a type error
in the test case file. The folder is git-ignored — see
[022-coding-conventions.md](022-coding-conventions.md#generated-files-go-in-_generated-and-are-git-ignored).

```ts
// _generated/parameter-names.d.ts — generated, not edited
type PromptSetName = "snerk" | "glurk";
type TaskName = "is-prime";
type InitialPromptNames = { "is-prime": "plain" | "terse" };
// …one union per parameter kind
```

`declareTestCase` is generic over the task name, and `initialPrompt` is restricted to
the prompts of the task named in `task`. A prompt that belongs to another task is a type
error.

## Typed pairs

The generator reads each family's `versions.ts` and `models.ts` from the
[family declaration](064-harness.md#family-declaration). It emits the valid pair strings
as template-literal types: each family's versions × its models, united across families.

```ts
// _generated/parameter-names.d.ts
type HarnessModelName =
  | `claude-code@${"2.1.283" | "2.2.0"}/${"haiku-4-5" | "sonnet-5-5"}`
  | `codex@${"0.9.0"}/${"gpt-luna"}`;
```

Every pair is checked on its own. Mixed families and models can share one test case.
A pair naming a model or version absent from its family is a type error.

```ts
export default declareTestCase({
  harnessModel: [
    "claude-code@2.1.283/haiku-4-5",
    "codex@0.9.0/gpt-luna",
    "claude-code@2.1.283/gpt-luna", // type error: model absent from this family
  ],
  // …
});
```

_(Referenced by: [064-harness.md](064-harness.md#versions-and-overrides),
[004-addressing-harness-model-pair.md](004-addressing-harness-model-pair.md),
[110-cli-report-visualization.md](110-cli-report-visualization.md).)_

