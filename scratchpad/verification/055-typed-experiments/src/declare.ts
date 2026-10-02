// intersect HarnessModels[K] across each listed harness K (distribute over H, not over the model union)
type CommonModels<H extends HarnessName> =
  (H extends unknown ? (x: HarnessModels[H]) => void : never) extends (x: infer I) => void ? I : never;
type Spec<T extends TaskName, H extends HarnessName> = {
  promptSet: PromptSetName[];
  harness: H[];
  // models runnable by EVERY listed harness (intersection); H is inferred from `harness` only
  model: NoInfer<CommonModels<H>>[];
  task: T;
  initialPrompt: InitialPromptNames[T][];
  iterations: number;
};
export function declareExperiment<const T extends TaskName, const H extends HarnessName>(s: Spec<T, H>) { return s; }
