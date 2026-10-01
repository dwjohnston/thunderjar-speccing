// Demo: invalid harness × model combinations are a type error.
// Run: bunx tsc --noEmit
// Every `@ts-expect-error` line below is a real type error. If any of them
// stopped erroring, tsc would fail with "Unused '@ts-expect-error' directive".

// ---------------------------------------------------------------------------
// _generated/ — what the type generator would emit from the harness folders'
// `models` maps.
// ---------------------------------------------------------------------------

type HarnessModels = {
    "claude-code-123": "sonnet-5.5" | "haiku-4.5";
    "opencode-123": "sonnet-5.5" | "gpt-5" | "haiku-4.5";
};

type HarnessName = keyof HarnessModels;

// ---------------------------------------------------------------------------
// Option: cross product — two arrays, every combination must be valid.
// The allowed models are the ones that *every* listed harness can run.
// ---------------------------------------------------------------------------

type ModelName = HarnessModels[HarnessName];

// The harnesses that can run model M.
type HarnessesFor<M extends ModelName> = {
    [H in HarnessName]: M extends HarnessModels[H] ? H : never;
}[HarnessName];

// The models every harness in H can run.
type ModelsForAll<H extends HarnessName> = {
    [M in ModelName]: [H] extends [HarnessesFor<M>] ? M : never;
}[ModelName];

function declareExperiment<
    const H extends readonly HarnessName[],
    const M extends readonly ModelsForAll<H[number]>[],
>(config: { harness: H; model: M }) {
    return config;
}



// 👇 This is the chosen method. 
// OK: Claude Code can run both models.
declareExperiment({
    harness: ["claude-code-123"],
    model: ["sonnet-5.5", "haiku-4.5"],
});

// OK: Sonnet runs on both harnesses.
declareExperiment({
    harness: ["claude-code-123", "opencode-123"],
    model: ["sonnet-5.5"],
});

declareExperiment({
    harness: ["claude-code-123", "opencode-123"],

    //@ts-expect-error
    model: ["sonnet-5.5", "gpt-5"],
});

// ---------------------------------------------------------------------------
// Option: pairs — each harness/model pair checked on its own.
// ---------------------------------------------------------------------------

type Agent = {
    [H in HarnessName]: { harness: H; model: HarnessModels[H] };
}[HarnessName];

function declareExperimentPairs(config: { agents: Agent[] }) {
    return config;
}

// OK: the mixed experiment the cross product can't express.
declareExperimentPairs({
    agents: [
        { harness: "claude-code-123", model: "sonnet-5.5" },
        { harness: "opencode-123", model: "sonnet-5.5" },
        { harness: "opencode-123", model: "gpt-5" },
    ],
});

declareExperimentPairs({
    agents: [
        // @ts-expect-error — claude-code-123 + gpt-5 can't run
        { harness: "claude-code-123", model: "gpt-5" },
    ],
});
