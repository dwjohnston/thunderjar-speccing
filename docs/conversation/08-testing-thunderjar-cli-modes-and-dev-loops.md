# Testing Thunderjar, CLI modes and dev loops

_Source: `docs/conversation_json.md` lines 488–580. See [README](README.md) for context._

**Covers:** Testing Thunderjar itself (first pass): unit vs orchestration vs integration, detecting container exit (`docker wait`), fake harness as a normal harness config, CLI scriptable vs interactive modes, local dev loops, local vs CI run provenance.

**User:** Okay, so let's talk about testing this application now. The application is going to be a CLI-based tool, written in JavaScript, and we need to be able to test it. So what we can imagine is that you're going to run `thunderjar run test` and then the test name, and that's going to create the Docker containers. For each permutation of what we're testing, it's going to load up the Docker container with all of the code that it needs, and then it will execute that. And then once those are complete, we will run our test measurements.

**Agent:** Right, so this is a step removed from what we've been designing — now we're talking about how you'd get confidence that Thunderjar itself, the orchestrator, works correctly, separate from the coding-agent runs it's orchestrating.

That naturally splits into a few layers, and they want pretty different testing strategies.

The core logic — building the matrix of permutations from your config, generating the right git checkout commands, constructing Docker image tags, parsing the structured JSON result object into your summary format — that's all pure-ish functions with predictable inputs and outputs, so ordinary unit tests, no Docker involved at all. That's the bulk of your test coverage and the cheapest to run.

The Docker orchestration layer — actually spinning up containers, running them, committing them, pushing to a registry — is where it gets more interesting, because you probably don't want every CI run of Thunderjar's own test suite to spin up real Claude Code sessions burning real API cost against real models. So this is a natural seam for exactly the dependency-injection pattern you landed on earlier for MCP servers, an abstraction over "container runtime" and "coding agent invocation" that in tests gets swapped for a fake, a container that just echoes back a canned result object instantly, so you can test "did Thunderjar correctly parse this JSON and build this summary" without any Docker daemon or API call actually happening.

Then a smaller number of true integration tests, maybe just a handful, that do run a real trivial Docker container end to end, to catch the things a mock can't, like whether your actual `docker commit` and tagging shell-out code works against a real daemon.

Is the CLI itself using something like `commander` or is it built on a lower-level arg-parsing setup, that'll shape how you approach testing the command surface itself?

**User:** Quick question. If the coding harness is running inside a Docker container, how do we become aware of when it has exited?

**Agent:** Docker itself tells you this natively, no polling of logs or anything fancy needed.

If you're running the container via the Docker CLI or SDK synchronously — `docker run` and waiting on it — the process just blocks until the container's main process exits, then returns control to you with the exit code, so you already know the moment it's done.

If you're spinning containers up asynchronously, which is presumably your case since you're firing off a hundred in parallel, the Docker Engine API exposes a `wait` endpoint per container, `docker wait <container_id>`, that blocks until that specific container transitions to a stopped state and returns its exit code. So your orchestrator would fire off all two hundred `docker run -d` calls to start them detached, then issue a `wait` call per container, either in parallel promises or via the Docker SDK's event stream, and each one resolves independently as that container finishes. That resolution is your trigger to immediately kick off the `docker commit`, extract the JSON result and trace, and push, all per-container, as soon as it's individually done rather than waiting for the whole batch.

**User:** Okay, so let's test them. I really want to get into the nitty gritty here. Let me play out some thoughts. The first thing is, when you do the Thunderjar test run, essentially you're going to create a bunch of Docker images — you're going to prepare these Docker images. I suppose that could just be a test, right? We go `thunderjar run` [transcribed as "Thunder Data Run"], and all it does is prepare the Docker image up to actually executing. You wouldn't need to run any real AI agent, because you just have a fake agent that is just a script, and that works quite well.

**User:** So the concept there is... because in your Thunderjar configuration, you're actually going to have some amount of script to say exactly what CLI command to run when we say we're going to run the agent.

**User:** So you could just have one of the harnesses be a fake harness, right?

**Agent:** That's a clean way to get real coverage without real API calls, treat "fake harness" as just another entry in the same harness-config mechanism, not a special test-only code path bolted on separately.

So concretely, the config that says "harness equals Claude Code, invoke it via `claude -p`" is structurally identical to a config that says "harness equals fake, invoke it via `node fake-agent.js`," same interface, same expected output shape, JSON result object with usage, cost, session ID, whatever. That means your integration tests get to exercise the entire real pipeline, image build, container start, wait, commit, push, parse — using nothing but that fake harness, and the only thing you're mocking is the one genuinely expensive, non-deterministic, external-dependency step. Everything downstream of "container produced a result" is tested completely for real.

And it doubles as a nice authoring tool too, since you could write a handful of fake harness scripts that deliberately produce edge cases, one that never commits, one that produces a malformed JSON result, one that times out, to test that your measurement and reporting layer handles those failure modes correctly, which is much harder to reliably trigger with a real model.

**User:** Yeah. So what I'm thinking about here is, I guess, the testing boundaries. Because what I'm imagining there is, okay, you say `thunderjar test run` [audio garbled: "safe ego, from the jar, test one"],

**Agent:** That search p...

**User:** and that creates some Docker images and actually executes some stuff. And then as part of our actual test, we do a search of what Docker images were created, check that they have the right tags on them, and then inspect the image and assert on these file changes, which are deterministic. [audio partly garbled] Thank you.

**User:** So then there's the other side of the story, which is to say: given that we've done whatever test runs, and we've got this summary and these Docker images, what happens when I call prune? Or,

**User:** given that these Docker images were created, check that they upload to the registry correctly. I don't think that worries me too much. Right. So the other thing is, when doing this development, we definitely do want this kind of fake path where...

**Agent:** Right, so you're describing exactly the assertion-on-Docker-metadata layer, and it sounds solid: after a run, your test queries the Docker daemon or registry by the tag scheme, finds the expected number of images with the expected labels, inspects one, and asserts on its layer diff or file contents, all without needing any AI involved since the fake harness already produced deterministic, known output.

And prune is a good second scenario to nail down explicitly, since it's destructive, so you'd want a test that runs a fake test batch, confirms the images exist, calls prune with some retention r...

**User:** I can be kind of just cool. [audio garbled]

**Agent:** All good, take your time.

**User:** What I was saying is just that when I'm doing the development work, I want to be invoking the CLI and trying to get the real experience, including seeing, like, the — [audio glitch: "the" repeated many times]

**Agent:** I think the audio might have glitched there, that last bit came through as a repeated word. Were you saying you want to run the CLI for real during development, so you can watch the actual output as it happens, rather than only asserting on it after the fact?

**User:** Yes, that's correct. Remember that there are two use cases for this tool. One is in CI pipelines, where essentially you're just going to be running a set of scripts, etc. But the other is that you're going to have this interactive CLI experience where you want to be exploring, digging into previous test runs, and doing the whole restore type stuff.

**Agent:** That's a meaningful split for how you architect the CLI itself, not just how you test it — two genuinely different UX modes on the same underlying engine.

The CI mode wants to be non-interactive, scriptable, exit-code-driven, machine-readable output, the kind of thing you'd wire into a pipeline and just check the return code and maybe parse a JSON summary from stdout. The interactive mode is a completely different animal, browsing past runs, drilling into an iteration, triggering a restore, that's arguably closer to a TUI, something like an interactive picker over your metadata store, than a traditional single-shot CLI command.

Worth deciding early whether that interactive mode is a separate `thunderjar explore` style subcommand built with something like `ink` or `blessed` for a proper terminal UI, versus just a series of individual `thunderjar show <run-id>` type commands that you chain together manually, since that decision shapes a good chunk of your CLI's dependency footprint and testing approach, the TUI route needs its own separate testing strategy from the rest of the command surface.

**User:** I'm not sure it does. What I would argue is that something that is testable is testable both ways. If you've architected your dependency injection sensibly, it should make testing both paths pretty straightforward. But let's move on. What was I going to say? All right, something we need to consider is that when you're doing these locally, there are two iterative loops the developer is going to be running into. One is: I'm a developer and I'm trying to write a certain skill. I've got my Thunderjar tests and I keep working on the skill, and the tests are failing, or I haven't written the test correctly, so I'm running it again and again until it starts passing, and I'm like, okay, great, happy with my tests, happy with my prompts, right?

**Agent:** Right, that's the fast inner loop, tight iterate-on-the-prompt cycle, presumably wanting quick single-iteration runs r...

ather than the...

**User:** The other thing is... what was

**User:** that? I cannot remember. Maybe you can help me think of it — there's another use case where the developer is going to be running these tests repeatedly

**User:** locally.

**Agent:** Could be the flip side of what you just described, the developer's iterating on Thunderjar itself, the tool, tweaking an assertion type or a harness config, and re-running the same known-passing test case repeatedly just to confirm they haven't broken the framework, rather than iterating on the prompt or skill under test.

Or, going back to something you raised earlier, it could be the statistical confidence loop, where one iteration passing isn't enough to trust, so even during active development you're re-running the same test case ten or twenty times just to see the pass rate stabilize before you believe the skill actually works reliably, that's a genuinely different rhythm from the fast single-shot loop, slower, batch-oriented, but still very much a local dev-machine activity rather than a CI concern.

**User:** Yes. Yeah, that's fair enough. I think basically there are two things. Maybe they're working on the prompt, and they trust the tests. Or they're working on the tests, and they trust the prompt. Maybe it's both. But the point is that there's an iterative loop. Probably what's happening is that you're doing single iterations until you've got the skill or the test right. And then once you're pretty confident with it, you're like, all right, let's do it 50 times locally to check that it's 99% or whatever it is.

**Agent:** That's a clean two-phase pattern, and it suggests your CLI probably wants an explicit iteration-count flag that defaults low, one, for that fast single-shot loop, and gets bumped up deliberately, fifty, a hundred, once you've moved into the confidence-checking phase, rather than always defaulting to a big batch and forcing the fast loop to wait on ninety-nine wasted iterations while you're still just getting the prompt to work at all.

And that split probably wants to show up in your caching and cost strategy too, since a single quick iteration during active prompt tweaking is exactly the case where you might not care about...

the...

**User:** But then the question is: in this scenario I've got these past runs, and they're all accumulating in maybe a local SQL database or something like that. But that's a different thing to what is created and stored by CI. What I'm wondering is, possibly you want some kind of... like an authentication mechanism kind of thing. Sorry, what I'm getting at here is that there's stuff I did while I was doing local development that we can probably just throw away — that stuff doesn't really count, it was useful for when I was doing development. The test runs that we actually care about are probably the ones that ran on the CI server. But of course, later I probably want to be able to dig into those, so they need to be saved somewhere.

**Agent:** Right, so this is really a provenance and retention distinction rather than an authentication one, tagging each run with where it came from, local scratch work versus CI, and letting that tag drive very different lifecycle rules.

Local dev runs could default to ephemeral, short retention, maybe even a separate local-only SQLite file that never syncs anywhere, genuinely throwaway once you've moved past the fast-iteration phase. CI runs get tagged as canonical and pushed to your shared metadata store and registry with proper long-term retention, since those are the ones representing real, trustworthy evidence about how a commit actually performs. And critically, that tag needs to be visible when you're browsing runs later, so your explore or restore tooling can filter to "only show me CI-verified runs" by default, and treat local ones as noise unless you specifically ask to see them.
