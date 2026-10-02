import { declareExperiment } from "./declare";
export default declareExperiment({
  promptSet: ["snerk"], harness: ["claude-code-2-1-283", "opencode-1-4-0"],
  model: ["sonnet-5-5", "gpt-5"], task: "is-prime", initialPrompt: ["plain"], iterations: 1,
});
