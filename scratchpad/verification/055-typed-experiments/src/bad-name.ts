import { declareExperiment } from "./declare";
export default declareExperiment({
  promptSet: ["snerkk"], harness: ["claude-code-2-1-283"],
  model: ["haiku-4-5"], task: "is-prime", initialPrompt: ["plain"], iterations: 1,
});
