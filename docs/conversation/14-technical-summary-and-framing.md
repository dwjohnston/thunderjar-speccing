# Technical summary and new-session framing

_Source: `docs/conversation_json.md` lines 1612–1745. See [README](README.md) for context._

**Covers:** Technical summary of Thunderjar and a framing prompt for a new agentic-coding strategy session.

**User:** Create a summary of the idea.

It does not need to be particularly detailed, but the technical scope needs to be captured.

The concept of hashing the experiment parameters, using those as docker tags, preserving the docker containers, later doing restores from them etc.

I need to start a new agent session talking about strategies for doing this with an agentic flow.

The idea is, I'll give the AI an outline of what the project involves, and tell it 'There will be a spec for you' - given this, how do I implement this using AI? I'm not looking for feedback from the AI about the technicals of the project itself, more the techniques for agentic coding.

**Agent:** Here's a summary capturing the technical scope:

---

**Thunderjar — Technical Summary**

Thunderjar is a prompt/agent-testing framework (Bun/TypeScript) for benchmarking AI coding-agent behavior in a repeatable, comparable way — deliberately avoiding pass/fail framing in favor of neutral "measurements."

**Core concepts:**
- **Experiment definition** — a named, version-controlled config (task + swept variables: harness, model, prompt set, etc.)
- **Experiment execution** — one occasion of running that definition, fanning out into every combination of its variables
- **Permutation** — one specific combination of variables within an execution
- **Container run** — the concrete unit of work: a Docker container spun up for one permutation, executing the task
- **Iteration** — a repeat of a container run, for pass-rate/statistical purposes
- **Measuring instrument** — a single-purpose, user-pluggable function that takes a container run's output and produces one **measurement** (not a verdict — just data: exists/doesn't, a count, a score, etc.)

**Identity & comparability:**
Experiment parameters (harness, prompt set, task, model, code state, etc.) are hashed to produce a stable identity. This hash is used as the Docker image/container tag, so two runs are only "comparable" if their parameter hash matches — this is the core mechanism that keeps benchmarking honest across time and machines.

**Execution & artifact lifecycle:**
1. Experiment execution resolves its permutations → spins up one Docker container run per permutation, tagged by the parameter hash.
2. Container runs produce artifacts: the container itself (preserved to a registry) plus summary metadata (stored separately, two-tier: metadata store + artifact store).
3. Preserved containers can later be **restored** (pulled back for inspection) or **purged** (per retention policy).

**Experiment types:**
- **Pinned experiments** (v1 scope) — fixed to an exact commit/prompt state, used to lock in known regression cases and track them statically over time.
- **Floating experiments** (deferred, not v1) — track "current" code/prompt state against a fixed baseline, to catch gradual drift/degradation; raises open design questions about whether they mutate config or accumulate resolved-run history underneath a stable identity.

**Usage patterns:**
- Local: iterate on a failing case → build an experiment to capture it → fix prompts → re-run.
- Local: new model release → spin up a fresh experiment, eyeball locally, then hand off to CI.
- CI: weekly/monthly cadence running both pinned and (later) floating experiments, reporting regressions.

---

Want me to also draft the framing/instructions you'd give the new session about *not* wanting technical feedback on the project itself, just agentic-coding-process strategy — or are you handling that part yourself?

**User:** Yes.

**Agent:** Here's a framing you could open the new session with:

---

**Framing for new session:**

"I'm going to give you an outline of a project (Thunderjar) below, and separately I have a detailed multi-file spec already written for it that I'll hand over once we start implementation. I do **not** want feedback on the project's technical design — that's already decided and specced elsewhere.

What I want from you is help thinking through **strategies for implementing this with an agentic coding workflow** — i.e., how do I best use an AI coding agent (like Claude Code) to actually build this thing, given that:

- There's a fairly large, multi-file spec (~14 files: motivation, terminology, user experience, setup/config, experiment parameters, data architecture, docker execution, restore/purge, CLI reference, CLI report visualization, testing strategy, open questions, tooling)
- The spec is detailed but the codebase doesn't exist yet — this is greenfield
- I'm time-poor, so I want an approach that minimizes how much I need to babysit or re-explain context
- I want confidence that the agent is building against the actual spec, not drifting or hallucinating decisions I didn't make

Questions I want your help with (process-level, not project-level):
- How should I sequence handing over the spec — all files up front, or incrementally per feature/milestone?
- Should I have the agent write its own task/todo breakdown from the spec before coding, and if so, how do I verify that breakdown is faithful to the spec?
- What's a good way to structure the repo/CLAUDE.md or equivalent so the agent has durable, correct context across many sessions, given the spec content itself will live outside the repo initially?
- How do I best catch drift — the agent quietly deciding something the spec didn't say, or contradicting something it did?
- Given the spec has explicit 'pinned v1 scope, floating deferred' type decisions, how do I stop the agent from over-building or speculatively implementing deferred scope?

Outline of the project (for context only, not for critique):"

*(then paste the technical summary)*

---

Want me to tighten this further, or adjust the emphasis on any of the questions?

**User:** Post all as a md codeblock

**Agent:** ```markdown
# Framing for New Session

I'm going to give you an outline of a project (Thunderjar) below, and separately I have a detailed multi-file spec already written for it that I'll hand over once we start implementation. I do **not** want feedback on the project's technical design — that's already decided and specced elsewhere.

What I want from you is help thinking through **strategies for implementing this with an agentic coding workflow** — i.e., how do I best use an AI coding agent (like Claude Code) to actually build this thing, given that:

- There's a fairly large, multi-file spec (~14 files: motivation, terminology, user experience, setup/config, experiment parameters, data architecture, docker execution, restore/purge, CLI reference, CLI report visualization, testing strategy, open questions, tooling)
- The spec is detailed but the codebase doesn't exist yet — this is greenfield
- I'm time-poor, so I want an approach that minimizes how much I need to babysit or re-explain context
- I want confidence that the agent is building against the actual spec, not drifting or hallucinating decisions I didn't make

Questions I want your help with (process-level, not project-level):

- How should I sequence handing over the spec — all files up front, or incrementally per feature/milestone?
- Should I have the agent write its own task/todo breakdown from the spec before coding, and if so, how do I verify that breakdown is faithful to the spec?
- What's a good way to structure the repo/CLAUDE.md or equivalent so the agent has durable, correct context across many sessions, given the spec content itself will live outside the repo initially?
- How do I best catch drift — the agent quietly deciding something the spec didn't say, or contradicting something it did?
- Given the spec has explicit "pinned v1 scope, floating deferred" type decisions, how do I stop the agent from over-building or speculatively implementing deferred scope?

Outline of the project (for context only, not for critique):

---

## Thunderjar — Technical Summary

Thunderjar is a prompt/agent-testing framework (Bun/TypeScript) for benchmarking AI coding-agent behavior in a repeatable, comparable way — deliberately avoiding pass/fail framing in favor of neutral "measurements."

**Core concepts:**
- **Experiment definition** — a named, version-controlled config (task + swept variables: harness, model, prompt set, etc.)
- **Experiment execution** — one occasion of running that definition, fanning out into every combination of its variables
- **Permutation** — one specific combination of variables within an execution
- **Container run** — the concrete unit of work: a Docker container spun up for one permutation, executing the task
- **Iteration** — a repeat of a container run, for pass-rate/statistical purposes
- **Measuring instrument** — a single-purpose, user-pluggable function that takes a container run's output and produces one **measurement** (not a verdict — just data: exists/doesn't, a count, a score, etc.)

**Identity & comparability:**
Experiment parameters (harness, prompt set, task, model, code state, etc.) are hashed to produce a stable identity. This hash is used as the Docker image/container tag, so two runs are only "comparable" if their parameter hash matches — this is the core mechanism that keeps benchmarking honest across time and machines.

**Execution & artifact lifecycle:**
1. Experiment execution resolves its permutations → spins up one Docker container run per permutation, tagged by the parameter hash.
2. Container runs produce artifacts: the container itself (preserved to a registry) plus summary metadata (stored separately, two-tier: metadata store + artifact store).
3. Preserved containers can later be **restored** (pulled back for inspection) or **purged** (per retention policy).

**Experiment types:**
- **Pinned experiments** (v1 scope) — fixed to an exact commit/prompt state, used to lock in known regression cases and track them statically over time.
- **Floating experiments** (deferred, not v1) — track "current" code/prompt state against a fixed baseline, to catch gradual drift/degradation; raises open design questions about whether they mutate config or accumulate resolved-run history underneath a stable identity.

**Usage patterns:**
- Local: iterate on a failing case → build an experiment to capture it → fix prompts → re-run.
- Local: new model release → spin up a fresh experiment, eyeball locally, then hand off to CI.
- CI: weekly/monthly cadence running both pinned and (later) floating experiments, reporting regressions.
```
