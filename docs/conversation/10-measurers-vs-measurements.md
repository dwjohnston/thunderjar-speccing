# Measurers vs measurements

_Source: `docs/conversation_json.md` lines 755–912. See [README](README.md) for context._

**Covers:** The user's earlier terminology.md pasted in; measurer (type) vs measurement (instance); broad globs vs exact filenames; shared named measurements rejected in favour of copy-paste; design risks.

**User:** ````
# Thunderjar Terminology

## Task

A **task** is the combination of a starting commit and a task instruction. It defines *what* the agent is asked to do and *from what state*.

Tasks also declare **measurements** — the assertions evaluated after the agent runs to determine pass/fail.

## Task Instruction

A **task instruction** is the text sent to the agent defining what it should do. It lives on the task definition. Distinct from a prompt set, which configures the agent's environment rather than directing its work.

When invoking a harness, the harness `cli` callback receives this as `ctx.taskInstruction` (along with `ctx.model` and `ctx.worktreePath`).

## Experiment

An **experiment** is a configured comparison: it names a task and a set of **variables**, then runs the task once for every permutation of those variables.

```ts
{
  experimentName: 'hello',
  taskId: 'normalise-compute-node',
  variables: {
    harnesses: {
      'claude-code': ['claude-haiku-4-5-20251001'],
      'cursor': ['composer-2.5'],
    },
    promptSets: ['skills-v1', 'minimal'],
  }
}
```

The above produces 2 × 2 = 4 runs.

## Variables

The dimensions that differ across runs within an experiment:

| Variable | What it controls |
|---|---|
| `model` | The LLM used by the harness |
| `harness` | The agent tool (e.g. claude-code, cursor) |
| `promptSet` | The prompt set applied to the worktree before a run |

## Prompt Set

A **prompt set** is a named, reusable configuration that defines how to overlay prompt files into the worktree before a run. It is referenced by ID. Distinct from a task instruction — a prompt set configures the agent's environment (e.g. installs a CLAUDE.md), while a task instruction tells the agent what to do.

A prompt set is a reproducible action, expressed as a shell command:

```ts
promptSets: {
  'skills-v1': { apply: 'git checkout abc123 -- CLAUDE.md .claude/' },
  'minimal':   { apply: 'git checkout def456 -- CLAUDE.md' },
}
```

This keeps prompt sets general enough to work across repos and teams, not just git-based workflows.

## Run

A single execution of a task under one specific combination of variable values. A run produces a **result**.

## Measurer

A **measurer** is a named, reusable definition of how to observe something about a run. It is registered once (built-in or user-defined) and referenced by name in task definitions. A measurer is parameterised by a config type and a value type:

```ts
registerMeasurer<{ glob: string }, boolean>({
    measurerName: "file-present",
    evaluate: (config, context) => Promise<MeasurementResult<boolean>>
})
```

Built-in measurers (e.g. `fileCreated`, `grep`) are pre-registered by the framework.

## Measurements

Observations evaluated at the end of a run. They are defined on the task, not the experiment, because what you want to measure about a task does not change across variable permutations.

A **measurement** is a task-level declaration that applies a measurer with specific config:

```ts
measurements: [
    { measurerName: "file-present", config: { glob: "output/add.ts" } }
]
```

A measurement returns a **`MeasurementResult<T>`** — not a verdict:

```ts
type MeasurementResult<T> =
  | { outcome: 'measured', data: T }
  | { outcome: 'skipped' }
  | { outcome: 'erroredWhileMeasuring', error: Error }
```

`data` can be any type — numeric (e.g. token count), boolean (e.g. file present/absent), or anything else. `'skipped'` means the measurement could not be evaluated (e.g. the run errored before relevant output existed). `'erroredWhileMeasuring'` means the measurement function itself threw during evaluation.

## Result

The outcome of a run: the set of measurement values produced by that run. Results are stored with the full variable context so experiments can be compared across runs.
````

**User:** Okay, I posted the terminology MD file above. Be aware that, firstly, I haven't read it just now. I wrote it quite a while ago, with the assistance of AI. Secondly, it's potentially a work in progress, and it likely does not align with some of the terminology we've been using in this conversation. Now, one of the things I want to get into: we've been using this term "measurer" and "measurement", and there are a couple of concepts here that I want to tease apart. For example, I have this concept of a test-based measurement. Say the AI task was, hey, generate me a function that determines if a number is prime. Part of the measurements, or the correctness test, might be that we would create a file, import the file that the AI created, and run tests against it. That's one of the trickier use cases. The other kind of measurement you might do is a simple grep, like does the file contain a piercing mirror [?], for example. The two things I want to tease apart here: you've got these different kinds of testing types — does a file exist? Does a commit exist? Does a file contain text? Does the outputted file pass this unit test?

**User:** But then you have specific implementations of those: does the file contain the text `ts-ignore`, does the file contain the text `foobar`, or whatever. And in the case we were talking about above, where you could add measurements retroactively to a previous run, you're really talking about that specific implementation of a measurement.

**Agent:** Right, so that's a type-versus-instance distinction, and it maps directly onto what's already in your terminology doc, actually, you've basically already named the type half of it.

A **measurer** is the type, the general capability, `grep`, `fileCreated`, and presumably a new one for your prime-number example, something like `unitTest` or `importAndRun`, that takes a glob, spins up or imports the output file, and runs assertions against it. That's registered once, it's code, it's the "does a file contain text" machinery in the abstract.

A **measurement** is the instance, a specific config applied to that measurer on a specific task, `grep` with pattern `TS-ignore` versus `grep` with pattern `foo-bar` are two different measurements using the same measurer. And that lines up exactly with what your doc already says, measurements are the task-level declarations that pair a measurer name with config.

So when we were talking earlier about retroactively adding checks to an old run by restoring its container, what you're actually doing is adding a new measurement, a new measurer-plus-config pairing, not a new measurer, unless the thing you need to check requires genuinely new evaluation logic, like your unit-test-runner case, in which case that's a new measurer too. Does that split feel right, or is there a third layer you're also trying to pull apart?

**User:** No, that makes sense. Although one thing to maybe dig into there — let's take "does the file contain `ts-ignore`?" Are we talking about: does this specific file X contain `ts-ignore`? Or is it that "a file contains `ts-ignore`", and then which file is a configurable part of it?

**Agent:** Ahh, good question, and I think it's the latter, the glob and the pattern are both just config values plugged into the same general-purpose `grep` measurer, not baked into it.

So "does `output/add.ts` contain `TS-ignore`" and "does `output/prime.ts` contain `TS-ignore`" are two different measurements, same measurer, same pattern, different glob. And "does `output/add.ts` contain `foo-bar`" is a third measurement, different pattern, same glob. The measurer itself is generic, it just knows how to take a glob and a pattern and report present or absent, all the specificity, which file, which text, lives in the measurement's config, not in the measurer's code.

**User:** Yes, okay, so the things I would call out there: having a general "contains `ts-ignore`" is a good kind of measurement that you would want to apply across presumably multiple test cases, right? So the concept here is that we are reusing measurements across different test cases. Maybe we say, well, no, we won't do that — that's something else. The other thing is: is it `prime.ts`, is it `is-prime`, is it PascalCase `IsPrime`? There, you need to allow for a certain amount of non-determinism — particularly if you're talking about commit messages, that kind of thing.

**Agent:** Right, so that's actually two separate problems hiding under one worry, worth pulling apart.

The reuse one is a clean structural question, do you want a shared measurement, like your TS-ignore check, defined once and referenced by name across many tasks, or do you re-declare an equivalent measurement per-task even if the config is identical. Given your reuse instinct, I'd guess you want measurements themselves to be nameable and referenceable too, not just measurers, so `contains-ts-ignore` becomes a named, shared measurement using the `grep` measurer, and a task just lists which named measurements apply to it. That's a real design choice, and it's got the same hash-identity question we discussed earlier, if `contains-ts-ignore`'s config changes, does every task referencing it silently change too.

The naming non-determinism one is a genuinely different problem, that's not about your measurement being wrong, it's about the glob needing to tolerate the agent's own output naming choices, `is-prime.ts` versus `isPrime.ts` versus `prime.ts`. That probably means the glob itself needs to be looser, or you need a discovery step before measurement, like "find whatever file was created in `output/`" rather than hardcoding the filename in the glob at all. Which of those two feels like the sharper edge to dig into first?

**User:** Well, actually, on that latter point, maybe the answer — for the "does it contain `ts-ignore`" check — is that the check just goes against `*.ts`, and maybe that should be the recommended pattern. That's absolutely fine. Testing against a specific file name, you could say, is a kind of code smell. Or actually you are expecting exact file names to exist, in which case that's a particular thing that you'd be testing for anyway.

**Agent:** That's a clean resolution actually, it sidesteps the naming non-determinism problem entirely rather than solving it, a glob like `output/star-dot-ts` for the TS-ignore check just doesn't care what the agent named the file.

And it gives you a nice implicit signal too, if a measurement's glob is broad, `output/star-dot-ts`, `output/star-star`, that's a behavioural check, it's testing something true regardless of naming. If a measurement's glob is a specific filename, that's implicitly also asserting the agent named the file correctly, which is a legitimate thing to want to test sometimes, you just want to be deliberate about which one you're doing rather than accidentally coupling an unrelated check to exact naming. Sounds like that resolves the second problem, does the reuse question still feel open, or are you thinking out loud on that one too?

**User:** Look, I think this is fine. So let's get you to do another pass about, you know what,

**Agent:** Sure, happy to take another pass. Do you want me to fold everything we've covered into an updated version of that terminology...

**User:** of everything we've talked about, thinking about this concept generally: what are the things that would say, no, this wouldn't work because...

**Agent:** Let me actually push on this properly rather than just nodding it through.

The sharpest risk I'd flag is that determinism assumption doing a lot of quiet work across the whole design, the hash-based versioning for prompt sets and measurers only holds if agents themselves are excluded from the loop, which they are, good, but your `onWorktreeCreate` and prompt set `apply` commands are shell commands, and nothing stops someone writing one that pulls from a network resource or reads a timestamp, the system can't detect that violation, it'll just silently produce hash drift that looks like a bug rather than what it is.

The second one is your restore-and-backfill workflow quietly assumes the container's filesystem state is a complete, sufficient proxy for "what happened," that's true for file-based measurements, but your prime-number unit-test measurer needs the actual runtime environment, correct Node or Bun version, installed dependencies, anything the agent's process touched outside files, and if the container snapshot didn't capture that faithfully, a measurement written today might not restore-and-run correctly against a container from three weeks ago, dependency drift in the base image, for instance.

Third, smaller but real, named shared measurements create a many-to-many web, if `contains-ts-ignore` is referenced by thirty tasks and you ever do legitimately want to change it, you're now blocked by every task that depends on it, that's the classic shared-utility versioning problem, not fatal, but worth deciding now whether that coupling is desired or something you want to actively avoid.

Do any of those land as real concerns, or do they feel like edge cases you're comfortable waving off for a proof of concept?

**User:** I think that third one does put the nail in the coffin for something like having a "contains `ts-ignore`" check measurement. Yeah, it does feel like copy-pasting your measurements is the right way to go.

**Agent:** That's a reasonable call, actually, copy-paste avoids the coupling problem entirely, each task owns its own measurement config outright, nobody's change ripples anywhere else, and given tasks probably aren't numerous enough yet for the duplication itself to be painful, it's a fine trade.

Worth noting it doesn't fully kill reuse as a concept, just reuse-by-reference. If duplication does get painful later, you could still offer something like a config-generating helper function developers call at config-authoring time, that produces the measurement config inline for each task, so the repetition's in the compiled config file, not in what the developer types. But that's a nice-to-have, not something you need to design for now.
