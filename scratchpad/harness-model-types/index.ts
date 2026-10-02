// Demo: complete harness/model pair strings are type checked independently.
// Run: bunx --bun tsc --noEmit
// Each @ts-expect-error must correspond to a real error or tsc fails.

// Generated from each family's versions.ts and models.ts.
type HarnessModelName =
  | `claude-code@${"2.1.283" | "2.2.0"}/${"haiku-4-5" | "sonnet-5-5"}`
  | `codex@${"0.9.0"}/${"gpt-luna"}`;

function declareExperiment(config: { harnessModel: HarnessModelName[] }) {
  return config;
}

// Mixed families, versions and models belong to the same experiment.
declareExperiment({
  harnessModel: [
    "claude-code@2.1.283/haiku-4-5",
    "claude-code@2.2.0/haiku-4-5",
    "codex@0.9.0/gpt-luna",
  ],
});

// Every declared version/model combination within a family is selectable.
declareExperiment({
  harnessModel: [
    "claude-code@2.1.283/sonnet-5-5",
    "claude-code@2.2.0/sonnet-5-5",
  ],
});

declareExperiment({
  harnessModel: [
    // @ts-expect-error — model absent from this family
    "claude-code@2.1.283/gpt-luna",
  ],
});

declareExperiment({
  harnessModel: [
    // @ts-expect-error — version absent from this family
    "claude-code@9.9.9/haiku-4-5",
  ],
});

declareExperiment({
  harnessModel: [
    // @ts-expect-error — family absent
    "unknown@0.9.0/gpt-luna",
  ],
});

declareExperiment({
  harnessModel: [
    // @ts-expect-error — incomplete pair
    "claude-code@2.1.283",
  ],
});

declareExperiment({
  // @ts-expect-error — separate harness/model arrays are not experiment axes
  harness: ["claude-code"],
  model: ["haiku-4-5"],
});
