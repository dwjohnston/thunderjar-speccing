# Harness/Model Pair Design

**Status: applied.** The five experiment parameters are base image, code state, prompt
set, harness/model pair and initial prompt. The matrix crosses those five axes;
any valid mix of pairs can be selected in one experiment.

The design is recorded in:

- [Declaring Experiments](055-declaring-experiments.md#an-experiment-is-a-matrix): the
  matrix and generated pair types.
- [Harness/Model Pair](064-harness.md): the family declaration, versions, context and
  execution hash boundary. Token-cost collection is separate from execution identity.
- [Model](065-model.md): explicit model-to-ID maps per family.
- [Configuration Folder Structure](051-configuration-folder-structure.md): one family
  folder yields multiple pair values.

The runnable type demo is in `scratchpad/harness-model-types/`.
