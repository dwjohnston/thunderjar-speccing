# Experiment Parameters

Parameter hashing and identity, what every declaration has in common, and an
example of each parameter's declaration. Each parameter's detail is on its own page,
061 to 066. Also covers measuring instruments. Builds on the five
[experiment parameters](030-terminology.md#experiment-parameters) already named
in the glossary.

## Parameter hashing and identity

- Base image, code state and prompt set folders hash their full content — `index.ts`
  plus any bundled scripts, templates or fixtures — to a **parameter hash**. Initial
  prompts are hashed individually; harness/model pairs use the boundary below.
  Measurements are hashed the same way, to a *content hash*, even though they aren't
  experiment parameters: hashing them catches silent drift when a named definition's content changes underneath it.
- A permutation's **permutation hash** combines the hashes of its five resolved
  parameters: base image, code state, prompt set, harness/model pair and initial prompt.
  Two container runs with the same hash have the same declared execution inputs.
- A [harness/model pair's hash](064-harness.md#hashing) includes shared execution
  content, the resolved version with its execution overrides, and the resolved model ID.
  The family maps and token-cost collector are excluded by location from shared content.
- A declaration can add to, or replace, what its parameter hash is derived from — see
  [Controlling the parameter hash](#controlling-the-parameter-hash).
- Parameter hash is derived from content, not name — renaming a folder doesn't
  break comparability, but editing `index.ts` does. Any report comparing "the
  same" named parameter over time should treat a hash change as a break, not
  silently merge pre/post-edit runs together.

## Controlling the parameter hash

For base image, code state, prompt set and initial prompt declarations, the default
hash comes from declaration content. A declaration can change that with one of two optional functions. Each returns a shell command.
Thunderjar runs the command on the host at the start of each experiment execution, and
uses its output.

```ts
additionalHash?: () => string; // a command; its output is hashed with the folder's content
determineHash?: () => string;  // a command; its output is hashed instead of the folder's content
```

| Function | Parameter hash is derived from |
|---|---|
| Neither | The folder's content. |
| `additionalHash` | The folder's content, plus the command's output. |
| `determineHash` | The command's output only. The folder's content is ignored. |
| Both | As `determineHash`. |

If a declaration provides both, `determineHash` takes precedence and `additionalHash`
is ignored.

Harness families use the [pair hash boundary](064-harness.md#hashing). A version
entry's `determineHash` resolves its version; it does not replace the whole pair hash.

```ts
// experiment-parameters/codeStates/main/index.ts
export default declareCodeState({
  determineHash: () => `git rev-parse origin/main`,
  commit: (ctx) => ctx.resolvedHash,
  applyParameter: () => `RUN npm ci`,
});
```

```ts
// experiment-parameters/baseImages/node20/index.ts
export default declareBaseImage({
  additionalHash: () => `docker image inspect --format '{{.Id}}' node:20-bookworm`,
  applyParameter: () => `FROM node:20-bookworm`,
});
```

### `ctx.resolvedHash`

The command's output is passed to the declaration's functions as `ctx.resolvedHash`.
For the code state above, on an execution where `origin/main` is at `a1b2c3`:

```
git rev-parse origin/main  → a1b2c3
ctx.resolvedHash           = "a1b2c3"
commit returns             "a1b2c3"
```

Use it rather than the moving name. A checkout of `main` has the same text on every
execution, so Docker would reuse the layer it built from an earlier commit. With the
resolved value, the image is built from exactly what was hashed.

### Parameters that follow a moving target

The code state above means "whatever `origin/main` is when the experiment executes". Each
execution resolves it again. When it has moved, the parameter hash is different, so
the permutation hash is different, and the execution is recorded as a different
permutation of the same named parameters.

This is sometimes called a *floating parameter*. It is not a separate kind of parameter
and uses `determineHash`. Examples include a prompt set following a branch and a
harness version entry following a locally recorded release. Pair version resolution
is defined in [064-harness.md](064-harness.md#versions-and-overrides); it preserves the family
execution content and model ID in the pair hash.

## Declarations and `applyParameter`

Each parameter is set by its [declaration](030-terminology.md#declaration) —
its file, or its family and selected map entries for a harness/model pair. Each
default export is wrapped in that kind's
`declareX()` function (`declareHarness`, `declareBaseImage`, …) per
[022-coding-conventions.md](022-coding-conventions.md#declarex-functions-not-bare-exports).
Each resolved parameter exposes the same function:

```ts
applyParameter: (ctx) => string; // a Dockerfile fragment
```

`ctx` carries `resolvedHash` — see
[Controlling the parameter hash](#ctxresolvedhash). A declaration that doesn't need it
leaves the argument off.

Building a permutation's prerun image is then a fold: concatenate each
parameter's fragment, in the order below, and build the result. Code state and prompt
set also declare a commit, which Thunderjar applies itself, ahead of their fragments —
see [062-code-state.md](062-code-state.md#how-the-code-gets-into-the-image).

```dockerfile
FROM node:20-bookworm                                    # base image
COPY code.bundle /tmp/code.bundle                        # Thunderjar: code state's commit
RUN git clone /tmp/code.bundle /workspace \
  && git -C /workspace checkout --detach a1b2c3 \
  && git -C /workspace remote remove origin \
  && rm /tmp/code.bundle
WORKDIR /workspace
RUN npm ci                                               # code state
COPY prompt-set/CLAUDE.md /workspace/CLAUDE.md           # Thunderjar: prompt set's files
COPY --from=thunderjar/harness-claude-code:2.1.283 \
  /opt/claude /opt/claude                                # harness/model pair
```

Fragments are Dockerfile source rather than bare shell commands, because the
prerun build *is* a Dockerfile — so layer caching stays explicit and the base
image needs no special case. It is simply the fragment carrying the `FROM`.
The order matches the build sequence in
[080-docker-execution.md](080-docker-execution.md#process).

### Build-time and run-time parameters

Four of the five parameters contribute to the image. The initial prompt is consumed
when the harness is invoked; its `applyParameter` returns an empty string:

| Parameter | Build time | Run time |
|---|---|---|
| Base image | seed of the build | — |
| Code state | commit, then dependencies / fixture generation | — |
| Prompt set | prompt files | — |
| Harness/model pair | installs the selected harness version | invoked via `cli` with the resolved version and model ID |
| Initial prompt | — | `ctx.initialPrompt` |

This split is the same one the flowchart in
[080-docker-execution.md](080-docker-execution.md#process) draws as its
per-permutation and per-iteration stages. All five keep the function even so:
the fold needs no special cases, and a kind that is a no-op today can gain
build-time setup later without changing the system's shape.

## Base image

The image a permutation's prerun image is built `FROM`. Detail:
[061-base-image.md](061-base-image.md).

```ts
// experiment-parameters/baseImages/node20/index.ts
export default declareBaseImage({
  applyParameter: () => `FROM node:20-bookworm`,
});
```

## Code state

The codebase applied on top of the base image: a git commit, plus any setup it needs.
Detail: [062-code-state.md](062-code-state.md).

```ts
// experiment-parameters/codeStates/baseline/index.ts
export default declareCodeState({
  commit: "a1b2c3",
  applyParameter: () => `RUN npm ci`,
});
```

## Prompt set

A named, reusable action that overlays prompt files (`CLAUDE.md`, skills, rules) into
the worktree before the harness runs. Detail: [063-prompt-set.md](063-prompt-set.md).

```ts
// experiment-parameters/promptSets/snerk/index.ts
export default declarePromptSet({
  commit: "e4f5a6",
  files: { "prompts/snerk.md": "CLAUDE.md" },
  applyParameter: () => ``,
});
```

## Harness/model pair

A family, version and model selected together. The family provides installation and
invocation logic; the selected entries supply the resolved version and model ID.
Declaration and hashing detail: [064-harness.md](064-harness.md); model mapping:
[065-model.md](065-model.md).

```ts
// experiment-parameters/harnessModels/claude-code/index.ts
export default declareHarness({
  applyParameter: (ctx) =>
    `RUN npm install -g @anthropic-ai/claude-code@${ctx.version}`,
  cli: (ctx) =>
    `claude -p "${ctx.initialPrompt}" --model ${ctx.modelId} ` +
    `--output-format json > ${ctx.resultPath}`,
  requiredEnv: ["ANTHROPIC_API_KEY"],
});
```

The family's `models.ts`, `versions.ts` and `collectTokenCosts.ts` are declared
separately, as shown in [064-harness.md](064-harness.md#family-declaration).

## Initial prompt

The first prompt given to the harness — what the agent is asked to do. It is one wording
of a task, and the task's measurements live in a `measurements/` folder beside its
initial prompts, excluded from every parameter hash. Detail: [066-task.md](066-task.md).

```ts
// experiment-parameters/tasks/is-prime/initial-prompts/plain.ts
export default declareInitialPrompt({
  prompt: "Create a file isPrime.ts exporting a function that tests for primality.",
  applyParameter: () => ``,
});
```

## Measuring instruments & measurements

- **Measuring instrument** — single-purpose, reusable evaluation logic (built-in
  or user-defined), parameterized by a config type and a value type. Examples:
  `grep`, `fileCreated`, `templateTest`.
- **Measurement** — an instrument plus a specific config, declared on a task.
  Copied per task, never shared by reference, so changing one task's
  measurement config can't silently change another task's meaning or history.
- **Measure** — the value one measurement produces for one iteration.
- **Result** — the set of measures for an iteration. Can grow after the fact:
  new measurements can be backfilled against a preserved artifact (the
  committed container image) without re-running the agent.

```ts
type MeasurementResult<T> =
  | { outcome: "measured"; data: T }
  | { outcome: "skipped" } // e.g. no output existed to check
  | { outcome: "erroredWhileMeasuring"; error: Error }; // the instrument itself threw
```

### Measurement context

An instrument's logic runs on the host; the work it commands runs inside a
[measurement container](030-terminology.md#measurement-container). The context
is that seam:

```ts
interface MeasurementContext {
  exec(command: string): Promise<{ stdout: string; stderr: string; exitCode: number }>;
  readFile(path: string): Promise<string>;
  writeFile(path: string, contents: string): Promise<void>;
  glob(pattern: string): Promise<string[]>;
  harnessResult: string; // raw contents of the file `cli` wrote
  workdir: string;
}

evaluate: (config, context) => Promise<MeasurementResult<T>>;
```

Keeping instrument logic host-side means it stays unit-testable against a fake
context — layer 1 of [120-test-boundaries.md](120-test-boundaries.md) — without
requiring Thunderjar's own runtime inside every base image.

### `templateTest`

The instrument that shows why `writeFile` is on the context. A test against
agent output can't be written in advance, because the thing it tests doesn't
exist yet and won't have a predictable name. So the file supplied is a
*template*, populated at measure time from whatever the agent actually
produced:

```ts
// declared on the task
{
  instrument: "templateTest",
  config: {
    subject: "output/**/*.ts",             // resolved in the measurement container
    template: "./prime.test.template.ts",  // host-side, part of the measurement's content hash
  },
}
```

```ts
// prime.test.template.ts — not runnable as-is
import { {{defaultExport}} } from "{{subjectPath}}";
test("17 is prime", () => expect({{defaultExport}}(17)).toBe(true));
```

Rendered into the measurement container and run there, so it gets the real
pinned runtime and installed dependencies. Its value type is a count rather
than a boolean — a measurement, not a verdict. The glob matching nothing gives
`skipped`; a template that can't bind gives `erroredWhileMeasuring`.

## Open questions

- Hash algorithm, and exactly what gets hashed (file contents only, or also
  file paths/structure?).
- What happens when an `additionalHash` or `determineHash` command exits non-zero.
- Whether the command's output is stored alongside the hash, so a report can show the
  commit an execution resolved to rather than only its hash.
- What else `applyParameter`'s `ctx` carries, beyond `resolvedHash` and the
  harness/model pair's resolved `version` and `modelId`.
- Imports from outside a declaration folder are not hashed. A change to such a helper
  can change execution without changing the parameter hash.
- Nothing stops a declaration returning a fragment that isn't reproducible
  (`RUN apt-get install foo`). The prerun image being built once and reused
  bounds the damage within a permutation's lifetime, but the hash can't detect
  it.
- Whether "artifact" should become the umbrella term for every hashed,
  reusable definition (harness, prompt set, measuring instrument, code state)
  — flagged in `030-terminology.md`, unresolved.
