# High-Level Groupings

A map of Thunderjar's concepts, so thinking can be constrained to one area at a time.

## The model in one sentence

A **test case** is a matrix of parameters. Each combination (a **permutation**) is
built into an image, run repeatedly, **measured**, and the results are **compared**.

## Six areas

### A. Declare — what do I want to vary?

Concepts: test case, the 5 parameters, task, matrix shape, permutation.

- [030-terminology.md](../spec/030-terminology.md)
- [051-configuration-folder-structure.md](../spec/051-configuration-folder-structure.md)
- [055-declaring-test-cases.md](../spec/055-declaring-test-cases.md)
- [060-test-case-parameters.md](../spec/060-test-case-parameters.md)

### B. Identity — when are two runs comparable?

Concepts: parameter hash, permutation hash, floating parameter.

- [060-test-case-parameters.md](../spec/060-test-case-parameters.md) (parameter hashing and identity, moving targets)
- [064-harness.md](../spec/064-harness.md) (Hashing section)
- [081-docker-tagging.md](../spec/081-docker-tagging.md) (permutation hash in tags)

### C. Build and run — what happens in one container run?

Concepts: prerun image, harness invocation, postrun image, iteration.

- [061-base-image.md](../spec/061-base-image.md)
- [062-code-state.md](../spec/062-code-state.md)
- [063-prompt-set.md](../spec/063-prompt-set.md)
- [064-harness.md](../spec/064-harness.md)
- [065-model.md](../spec/065-model.md)
- [066-task.md](../spec/066-task.md)
- [080-docker-execution.md](../spec/080-docker-execution.md)
- [081-docker-tagging.md](../spec/081-docker-tagging.md)

### D. Measure — did the agent do well?

Concepts: task measurements, instruments, measurement container, backfill.

- [066-task.md](../spec/066-task.md)
- [060-test-case-parameters.md](../spec/060-test-case-parameters.md) (measuring instruments, measurement context)
- [085-test-case-results.md](../spec/085-test-case-results.md)
- [045-shipped-skills.md](../spec/045-shipped-skills.md) (capturing sessions as test cases)

### E. Record and compare — where does it go, and how do I read it?

Concepts: run data store, image store, Result, aggregation result, token costs.

- [070-data-architecture.md](../spec/070-data-architecture.md)
- [071-data-persistence.md](../spec/071-data-persistence.md)
- [085-test-case-results.md](../spec/085-test-case-results.md)
- [087-collecting-token-costs.md](../spec/087-collecting-token-costs.md)

### F. Operate — how do I drive it?

Concepts: CLI, CI vs local, restore/purge, setup.

- [040-user-experience.md](../spec/040-user-experience.md)
- [050-setup-and-configure.md](../spec/050-setup-and-configure.md)
- [090-restore-purge.md](../spec/090-restore-purge.md)
- [100-cli-reference.md](../spec/100-cli-reference.md)
- [110-cli-report-visualization.md](../spec/110-cli-report-visualization.md)

### Outside the six areas

Meta pages:

- [020-goals-non-goals.md](../spec/020-goals-non-goals.md)
- [021-human-zone-out.md](../spec/021-human-zone-out.md)
- [130-open-questions.md](../spec/130-open-questions.md)

About building Thunderjar itself, not using it:

- [022-coding-conventions.md](../spec/022-coding-conventions.md)
- [120-test-boundaries.md](../spec/120-test-boundaries.md)
- [140-tooling.md](../spec/140-tooling.md)
- [141-runnable-artifact.md](../spec/141-runnable-artifact.md)
- [150-repository-layout.md](../spec/150-repository-layout.md)
