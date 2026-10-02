
# Terminology

Glossary of project-specific terms, used consistently across all other spec pages.

## Core concepts

### Experiments

An **experiment** consists of a matrix of **experiment parameters** — the values that determine what happened and from what state, and whose combinations produce permutations. One of those parameters is the **initial prompt**: the first prompt given to the harness, i.e. what the agent is asked to do. An experiment is about one **task**: the goal its initial prompts ask for, together with the measurements that judge it.

🙋‍♂️ Really an experiment is the 6 parameters + and then task measurements occur afterwards. 

Associated with each task are its **task measurements**, which judge the outcome of a container run after the fact. They are not an experiment parameter: they don't inform what runs or how many permutations there are, and they aren't part of the permutation hash. They live alongside the task because they're only meaningful for it, and every initial prompt of the task is judged by the same ones — see [051-configuration-folder-structure.md](051-configuration-folder-structure.md).

The experiment parameters are: **base image**, **code state**, **prompt set**, **harness/model pair**, and **initial prompt**. The task itself is named once per experiment and is not varied.

### Experiment parameters

Each of these five values is defined deterministically — if the content does not change, neither should its effect on the experiment run. Do not make API calls or other non-deterministic operations in parameter definitions.

Base image, code state and prompt set values each have a named folder with an
`index.ts` and optional bundled files. Initial prompts are individual files within a
task. A harness/model pair selects values from a family folder's version and model maps;
one folder yields many pairs. See
[051-configuration-folder-structure.md](051-configuration-folder-structure.md).

```
experiment-parameters/
  baseImages/node20/index.ts
  codeStates/baseline/index.ts
  promptSets/snerk/index.ts
  harnessModels/claude-code/
    index.ts
    models.ts
    versions.ts
    collectTokenCosts.ts
  tasks/add-function/
    initial-prompts/plain.ts
    measurements/
```

| Term | Definition | Example |
|---|---|---|
| **Base image** | The image a permutation's prerun image is built `FROM`, before code state is applied — base OS/runtime plus any extra services a task needs (a database, a message broker) that code state, prompt set, or harness don't provision. Most experiments just use one plain, minimal base image. | `baseImages/node20` → `FROM node:20-bookworm` |
| **Code state** | The codebase the container starts from, applied on top of the base image — a git commit from the user's repository, plus any setup it needs (installing dependencies, seeding fixtures). See [062-code-state.md](062-code-state.md). | `codeStates/baseline` → commit `a1b2c3`, then `npm ci` |
| **Prompt set** | The prompt files overlaid into the worktree (`CLAUDE.md`, skills, rules), read from a pinned commit. | `promptSets/snerk` → `prompts/snerk.md` at `e4f5a6`, as `CLAUDE.md` |
| **Harness/model pair** | One parameter selecting a harness family, resolved version and root model. See [064-harness.md](064-harness.md#addressing-a-pair). | `claude-code@2.1.283/haiku-4-5` |
| **Harness family** | Shared installation, invocation and collection logic with version and model maps; not itself a parameter value. | `harnessModels/claude-code/` |
| **Model** | The root LLM selected within the pair, with a harness-specific ID. Sub-agent models are outcomes. | `haiku-4-5` → `claude-haiku-4-5-20251001` |
| **Task** | The goal an experiment is about, with its initial prompts and the task measurements that judge it. An experiment names exactly one, so every result in it is judged by the same measurements. Not a varied parameter. | `tasks/add-function` |
| **Initial prompt** | The first prompt given to the harness — what the agent is asked to do. One of several wordings a task can have. Distinct from prompt set, which shapes the environment. Called *task instruction* in earlier drafts and in the source conversation. | `tasks/add-function/initial-prompts/plain.ts` → "Write a TypeScript function called `add`…" |

### Declaration

A **declaration** defines an experiment parameter. Base image, code state and prompt
set declarations are `index.ts` plus bundled files; an initial prompt has its own file.
For a harness/model pair, the declaration is the family's shared execution definition
plus its selected version and model entries — see
[064-harness.md](064-harness.md#family-declaration).

Each resolved parameter exposes `applyParameter()`, which returns its contribution to
the prerun Dockerfile. A harness family also defines how to invoke the tool. See
[060-experiment-parameters.md](060-experiment-parameters.md#declarations-and-applyparameter).

### Parameter hash

Each experiment parameter has its own **parameter hash**:

1. **Usually it is taken from the content of the parameter's declaration folder** —
   `index.ts` plus anything bundled alongside it.
2. **Some exclusions apply.** Task measurements do not affect execution identity.
   A [pair hash](064-harness.md#hashing) combines shared execution content, the selected
   version's execution overrides with its resolved version, and the selected model ID.
   Other map entries and the token-cost collector do not contribute.
3. **Other parameter declarations can set the value themselves**, with `additionalHash`
   or `determineHash` — see [Floating parameter](#floating-parameter).

### Permutation hash

A permutation's **permutation hash** combines the parameter hashes of its five parameters
(base image, code state, prompt set, harness/model pair, initial prompt). This hash tags
the permutation's prerun and postrun images and proves two container runs are comparable:
if any parameter hash changes, the permutation hash changes, so two runs are only directly comparable if they
share the same hash. See
[060-experiment-parameters.md](060-experiment-parameters.md#parameter-hashing-and-identity).

### Floating parameter

A **floating parameter** is an experiment parameter that follows a moving target, such as
the tip of `main`, instead of a pinned value. It is not a separate kind of parameter: it
is a declaration that uses `determineHash`, a command Thunderjar runs at the start of
each experiment execution, whose output replaces the folder's content as the source of
its parameter hash. When the target has moved, the parameter hash changes, so the
permutation hash changes too.

For a harness/model pair, version resolution replaces only the version value; shared
execution content, version overrides and model ID remain hashed. See
[064-harness.md](064-harness.md#versions-and-overrides).

A floating parameter is still deterministic. The value may differ from one execution to
the next, but any one resolved value must always mean the same thing: the same commit
SHA is always the same codebase. The command should not make API calls or read anything
else that could give two answers for the same state. See
[060-experiment-parameters.md](060-experiment-parameters.md#parameters-that-follow-a-moving-target).

### Permutation

A **permutation** is one specific combination of experiment parameter values. An experiment with matrix shape `1/1/2/1/1` (2 prompt sets, everything else fixed) produces 2 permutations.

### Matrix shape

Shorthand for the size of an experiment's parameter matrix, written
`<base images>/<code states>/<prompt sets>/<harness-model pairs>/<initial prompts>`.

```
1/1/2/1/1
```

One count per parameter, in the order above. Their product is the number of permutations:
the example has 1 base image, 1 code state, 2 prompt sets, 1 harness/model pair and
1 initial prompt — 2 permutations.

A matrix shape of `1/1/1/1/1` — every axis fixed to a single value — is a
**single-permutation experiment**: exactly one permutation, so repeated container runs
come only from iteration, not from the matrix.

### Experiment execution

An **experiment execution** is one occasion of running the experiment: it resolves the matrix and runs each permutation, potentially multiple times (for statistics). Identified by an **execution ID** — a ULID, which scopes the postrun image tags produced during that execution. _(Referenced by: [081-docker-tagging.md](081-docker-tagging.md).)_

## Container run lifecycle

### Prerun image

The starting-point image for a permutation: built `FROM` its base image, code state
applied, prompt set overlaid, harness installed and pinned — everything from
**Initial setup** below, before the harness is invoked. Tagged `prerun-h<permutation hash>`
— see [081-docker-tagging.md](081-docker-tagging.md) for the full tag scheme.

One permutation always maps to one prerun image, even when pairs differ only by model and
therefore share the same filesystem — simpler than special-casing which parameters
affect the image. Content-addressed, so it's built once and reused as the starting point
for every iteration of that permutation, and reused again if the same permutation (same
permutation hash) runs again later, e.g. a pinned experiment's weekly rerun, rather than
rebuilt from scratch. Pushed to the **image store** so any iteration or runner can pull
it without rebuilding, and so the exact runtime environment stays reproducible.

### Postrun image

The end-state image for one container run: the final filesystem after the harness has
run, captured with `docker commit` *before* any measurement is applied, so it holds the
agent's end state and nothing else. Tagged
`postrun-e<execution ID>-h<permutation hash>-i<iteration index>` — the same permutation hash used in
the prerun image's tag, so which prerun image a postrun image was built from is visible
directly in its own tag, no separate lookup needed. Always new — never reused or shared
across iterations or executions, unlike the prerun image.

### Measurement container

A short-lived container started from a **postrun image** in order to apply that container
run's measurements. In effect a continuation of the run container — same filesystem, same
pinned runtime and installed dependencies — picked up again after the agent has finished.
Files can be written into it (a rendered test file, a fixture) and arbitrary commands run
against it, but it is **never committed**: it is discarded once its measures are recorded,
so the postrun image stays exactly the agent's end state.

Because it is reconstructed from the postrun image rather than being the original
container, one can be started again at any point in the future. That is what makes
backfilling new measurements onto historical runs possible without re-running the agent —
see [085-experiment-results.md](085-experiment-results.md).

### Container run

A **container run** is the concrete execution of one permutation:

1. **Initial setup:**
   - If a prerun image already exists for this permutation's permutation hash, pull and
     reuse it.
   - Otherwise, build one: starting `FROM` the permutation's base image, the code state's
     commit is cloned to `/workspace` and its setup run, prompt set files are overlaid, harness is installed and pinned to its
     version — then tag and push it as the prerun image.

2. **Execution:**
   - The harness is invoked headlessly with the initial prompt and model

3. **Preservation:**
   - The final container state is committed to a new image
   - The image is tagged as the postrun image
   - The image is pushed to the **image store** (e.g., a Docker registry)

4. **Measurement:**
   - A **measurement container** is started from the postrun image
   - The task's measurements are applied to it, then it is discarded

5. **Recording:**
   - Container run metadata and its measures are stored in the **run data store**

Preservation precedes measurement deliberately — see
[080-docker-execution.md](080-docker-execution.md#why-commit-happens-before-measurement).

### Iteration

An **iteration** is one repeat of a container run for the same permutation, used to gather pass-rate statistics. Each iteration gets its own container and a separate ID within the permutation.

### Aggregation result

An **aggregation result** combines the Results of every iteration of one permutation within one experiment execution, even when there is only one iteration. It is the unit that gets compared: the result of experiment executions with different permutation hashes, but the same shapped aggregation result can be compared. See [085-experiment-results.md](085-experiment-results.md#aggregation-results).

## Storage

| Term | Definition |
|---|---|
| **Run data store** | Where container run metadata is persisted: date, the permutation's experiment parameters and permutation hash, measurements, cost, tokens, duration. Enables querying and trending over time. See [085-experiment-results.md](085-experiment-results.md). |
| **Image store** | Registry (e.g., Docker Hub, ECR) where prerun and postrun images are stored, tagged as above, enabling restore and inspection later. A run's OTel trace and session transcript live in its postrun image. |

**Future:** a separate **trace store** for OTel traces and session transcripts, so
viewing one doesn't need a full image pull. See
[020-goals-non-goals.md](020-goals-non-goals.md#non-goals-v1).

## Open questions and notes, things not to forget

- **Container run metadata vs. measurements:** What should we call the aggregate of measurements produced by one container run? Candidate: "container run result" or "container run snapshot".
- **Run data store clarity:** Should this have a more specific name? (e.g., "metadata store", "result store")
- Still need to include the concept of measurements 
- The concept that we can later reapply new measurements against previous runs, without having to actually rerun them. 
- The concept of comparing runs over time. It's fine if the the parameters and the measurments are the same, but sometimes we might still want to compare against changing parameters, or with new measurements. 