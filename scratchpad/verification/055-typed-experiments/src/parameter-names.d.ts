type PromptSetName = "snerk" | "glurk";
type TaskName = "is-prime" | "sort";
type InitialPromptNames = { "is-prime": "plain" | "terse"; "sort": "asc" };
type HarnessName = "claude-code-2-1-283" | "opencode-1-4-0";
type ModelName = "sonnet-5-5" | "haiku-4-5" | "gpt-5";
type HarnessModels = {
  "claude-code-2-1-283": "sonnet-5-5" | "haiku-4-5";
  "opencode-1-4-0": "sonnet-5-5" | "gpt-5";
};
