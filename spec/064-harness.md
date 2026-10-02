# Harness/Model Pair

A **harness/model pair** selects an agent tool's family, version and root model. It is
one of the five [experiment parameters](030-terminology.md#experiment-parameters).
A family is declared once; its version and model maps yield the pair values an
[experiment](055-declaring-experiments.md#declaration) can select.

## Addressing a pair

```
<family>@<version>/<model>
```

```
claude-code@2.1.283/haiku-4-5
codex@0.9.0/gpt-luna
```

Names select values; hashes identify execution content. Renaming a family, version key
or model key preserves the hash when its resolved content is unchanged.
_(Referenced by: [030-terminology.md](030-terminology.md),
[051-configuration-folder-structure.md](051-configuration-folder-structure.md),
[055-declaring-experiments.md](055-declaring-experiments.md),
[060-experiment-parameters.md](060-experiment-parameters.md),
[004-addressing-harness-model-pair.md](004-addressing-harness-model-pair.md),
[110-cli-report-visualization.md](110-cli-report-visualization.md).)_

## Family declaration

```
experiment-parameters/harnessModels/
  claude-code/
    index.ts
    models.ts
    versions.ts
    collectTokenCosts.ts
```

Thunderjar loads these four files by convention. `index.ts` supplies shared execution
behaviour, `models.ts` maps model names to harness-specific IDs, `versions.ts` maps
version names to resolved versions and optional execution overrides, and
`collectTokenCosts.ts` interprets the preserved output. Supporting execution files can
sit beside them.
_(Referenced by: [051-configuration-folder-structure.md](051-configuration-folder-structure.md),
[055-declaring-experiments.md](055-declaring-experiments.md),
[065-model.md](065-model.md), [022-coding-conventions.md](022-coding-conventions.md),
[120-test-boundaries.md](120-test-boundaries.md).)_

```ts
// experiment-parameters/harnessModels/claude-code/index.ts
export default declareHarness({
  applyParameter: (ctx) =>
    `RUN npm install -g @anthropic-ai/claude-code@${ctx.version}`,
  cli: (ctx) =>
    `claude -p "${ctx.initialPrompt}" --model ${ctx.modelId} ` +
    `--allowedTools "Write,Edit,Read,Bash" --output-format json > ${ctx.resultPath}`,
  requiredEnv: ["ANTHROPIC_API_KEY"],
});
```

```ts
// experiment-parameters/harnessModels/claude-code/models.ts
export default declareHarnessModels({
  "haiku-4-5": "claude-haiku-4-5-20251001",
  "sonnet-5-5": "claude-sonnet-5-5",
});
```

```ts
// experiment-parameters/harnessModels/claude-code/versions.ts
export default declareHarnessVersions({
  "2.1.283": { version: "2.1.283" },
  "2.2.0": { version: "2.2.0" },
});
```

Models have explicit maps per family, as detailed in [065-model.md](065-model.md).

### Versions and overrides

Each version entry supplies a pinned `version`. It can override `applyParameter`, `cli`
or `requiredEnv`; each supplied field replaces the family's field for that version.
Every version uses the family's model map. The generated pair union contains every
version/model combination within each family — see
[055-declaring-experiments.md](055-declaring-experiments.md#typed-pairs).

```ts
export default declareHarnessVersions({
  "2.1.283": { version: "2.1.283" },
  "2.2.0": {
    version: "2.2.0",
    cli: (ctx) =>
      `claude -p "${ctx.initialPrompt}" --model ${ctx.modelId} ` +
      `--output-format json > ${ctx.resultPath}`,
  },
});
```

A floating entry uses `determineHash` instead of a pinned `version`, following
[060-experiment-parameters.md](060-experiment-parameters.md#parameters-that-follow-a-moving-target).
Its command output is the resolved version used in the pair hash and `ctx.version`.
The family's code, selected execution overrides and model ID remain in the hash;
resolution replaces only the version value. Resolve once per entry per experiment execution.

```ts
export default declareHarnessVersions({
  latest: { determineHash: () => "cat ./harness-versions/claude-code.txt" },
});
```

With `harness-versions/claude-code.txt` containing:

```text
2.2.0
```

Selecting `claude-code@latest/haiku-4-5` uses `2.2.0` for that execution.
_(Referenced by: [060-experiment-parameters.md](060-experiment-parameters.md),
[030-terminology.md](030-terminology.md).)_

## `applyParameter`: installing the tool

The resolved version is passed to `applyParameter` as `ctx.version`. The fragment may
install it or copy it from a pinned harness image. Where those images come from is
unresolved — see [020-goals-non-goals.md](020-goals-non-goals.md#to-revisit).

## `cli`: running the agent

| Context field | What it is |
|---|---|
| `ctx.version` | The selected entry's resolved harness version. |
| `ctx.modelId` | The selected model's ID from this family's map. |
| `ctx.initialPrompt` | The experiment's [initial prompt](066-task.md#initial-prompts). |
| `ctx.resultPath` | Where the command must write its result file. |

The resolved pair supplies the version and model ID together. `cli` must run the agent
and leave a file at `ctx.resultPath`; Thunderjar hands its bytes to the family's
collector. Thunderjar wraps the command to record timing and exit code — see
[080-docker-execution.md](080-docker-execution.md#the-execution-wrapper).
_(Referenced by: [060-experiment-parameters.md](060-experiment-parameters.md),
[065-model.md](065-model.md), [087-collecting-token-costs.md](087-collecting-token-costs.md).)_

## `collectTokenCosts`: reading back the cost

The family's collector lives in `collectTokenCosts.ts`. It receives the raw file and
the resolved pair's version and model ID, so it can handle output differences between
versions. Its result and failure behaviour are defined in
[087-collecting-token-costs.md](087-collecting-token-costs.md#normalising-collecttokencosts).

```ts
// experiment-parameters/harnessModels/claude-code/collectTokenCosts.ts
export default declareTokenCostCollector((raw, ctx) => {
  // Parse the format for ctx.version; ctx.modelId identifies the root model.
  return { outcome: "unavailable", reason: "notReported" };
});
```

## `requiredEnv`: credentials

The family declares environment variable names; the selected version may override the
list. Thunderjar passes exactly those variables as `docker run -e NAME`. Values come
from the user's shell or CI secret store, never from declarations or hashes.

- Each container receives only its resolved pair's required variables.
- `plan` and `run` fail before building if a required variable is unset.
- Names are hashed as execution content; values are never hashed or recorded.

For provider-specific credentials, declare one family per provider in v1.
_(Referenced by: [050-setup-and-configure.md](050-setup-and-configure.md#credentials),
[100-cli-reference.md](100-cli-reference.md#doctor).)_

## Hashing

The pair's parameter hash combines:

1. Shared execution content: `index.ts` and bundled execution files.
2. The resolved version and the selected version's execution overrides.
3. The selected model's resolved ID.

`models.ts`, `versions.ts` and `collectTokenCosts.ts` are excluded from the shared
content hash by location. Only the resolved version, its execution overrides and the
selected model ID contribute from the maps. Resolution commands and map keys are not
execution content. Execution definitions must not import these excluded files;
Thunderjar loads them separately. Collector-only helpers live outside the family folder, whose
bundled files count as execution content.

| Change | Effect on pair hashes |
|---|---|
| Add a model or version | None for existing pairs. |
| Change one model's ID | That model's pairs. |
| Edit a version's execution overrides or resolved version | That version's pairs. |
| Edit shared execution code | Every pair in the family. |
| Rename a pair's keys, retaining resolved content | None. |
| Edit `collectTokenCosts.ts` | None; token costs can be re-collected from preserved output. |

A parser correction affects interpretation, so it does not change execution identity.
Imports from outside the family folder are not covered by its content hash; the
reproducibility limits in
[060-experiment-parameters.md](060-experiment-parameters.md#open-questions) apply.
_(Referenced by: [030-terminology.md](030-terminology.md),
[060-experiment-parameters.md](060-experiment-parameters.md#parameter-hashing-and-identity),
[087-collecting-token-costs.md](087-collecting-token-costs.md#backfilling-token-costs),
[004-addressing-harness-model-pair.md](004-addressing-harness-model-pair.md).)_
