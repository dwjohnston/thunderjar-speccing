# Model

The root LLM selected within a [harness/model pair](064-harness.md#addressing-a-pair).
Model values live in each harness family's `models.ts`, alongside its version map;
see [064-harness.md](064-harness.md#family-declaration).

## Harness-specific IDs

Each family explicitly maps model names to the IDs its CLI accepts. A model name is
local to that family; there is no central model declaration.

```ts
// experiment-parameters/harnessModels/claude-code/models.ts
export default declareHarnessModels({
  "haiku-4-5": "claude-haiku-4-5-20251001",
});
```

```ts
// experiment-parameters/harnessModels/opencode/models.ts
export default declareHarnessModels({
  "haiku-4-5": "anthropic/claude-haiku-4-5-20251001",
});
```

An experiment selects a complete pair, such as `claude-code@2.1.283/haiku-4-5`.
The resolved ID reaches `cli` as `ctx.modelId` — see
[064-harness.md](064-harness.md#cli-running-the-agent). The model ID contributes to
the pair hash; model names do not determine execution identity.
_(Referenced by: [064-harness.md](064-harness.md#family-declaration),
[060-experiment-parameters.md](060-experiment-parameters.md),
[004-addressing-harness-model-pair.md](004-addressing-harness-model-pair.md).)_

**Future:** a central model catalogue with per-family ID transformations. See
[020-goals-non-goals.md](020-goals-non-goals.md#non-goals-v1).

## Sub-agent models

The pair controls the root model. Sub-agent models are recorded as outcomes, in the
per-model breakdown of [087-collecting-token-costs.md](087-collecting-token-costs.md).
