import { declareExperiment } from "./declare";
export default declareExperiment({
  promptSet: ["snerk", "glurk"], harness: ["claude-code-2-1-283"],
  model: ["haiku-4-5"], task: "is-prime", initialPrompt: ["plain", "terse"], iterations: 5,
});
