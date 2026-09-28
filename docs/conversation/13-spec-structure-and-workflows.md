# Spec structure and workflows

_Source: `docs/conversation_json.md` lines 1409–1610. See [README](README.md) for context._

**Covers:** Spec page structure; local and CI user workflows; pinned vs floating experiments (floating deferred); the spec file list as it evolved.

**User:** Okay, so from here: I've already given it a couple of goes, getting AI to create a spec from this conversation, and if I'm honest it has not done a particularly good job. What I'm wanting to do from here is create a spec. Here's the thing: I think I have a pretty clear understanding of what needs to be built. What I need to do is get this into a fairly detailed spec, and it's going to need to be multiple pages. So let's create a spec structure. What I don't want is one 2000-line markdown file, because that's hard for me to read. So let's just talk about what the structure would look like. I'll throw some stuff at you and we'll go through it one by one. We need one which is a motivation.md file, which talks about the problem we're trying to solve. And then, possibly in that file or maybe in a different file, there's user experience — our main workflows. I think we can assume the user has already set the application up; setting the application up is probably another file. So, given the user has already got the application set up, there are two camps of workflow. One is stuff the user would do on their own machine. The other is how the behavior is when it's running in CI — what that experience is, how things get surfaced up, et cetera. Right?

**Agent:** That's a solid split already: motivation as its own short file, then user...

**User:** So when they're running it on their own machine — let's see, one key one is: they've done some task, and the AI tripped up on what they thought was a pretty simple instruction. So they go and create a test case — an experiment — to capture that trip-up. And then they adjust their prompts to fix the trip-up. And they enter this iterative loop to check that their prompt... firstly, they enter an iterative loop to make sure that the experiment, the task and the measurements they defined were working,

**Agent:** Got it, so that's flow one: notice a trip-up, encode it as an experiment, then iterate on the harness itself, task, measurements, before even getting to the prompt fix, just to make sure the experiment's actually measuring the right thing.

**User:** and then maybe they... Yep. What else have we got?

**Agent:** Want me to just hold that thread open while you think, or should I throw out a couple of likely next-flow candidates, like the CI-triggered regression check, or someone else on the team discovering the experiment later and reusing it?

**User:** Oh, yeah, okay. Another workflow will be: a new model comes out. So there's a new version of Sonnet, and we create a new experiment and run it, and we quickly eyeball it. With that one there probably isn't so much of an iterative flow — we're just adding a new one. We'll probably run it locally just to see how it went, but that's one you really want to ship to CI, to be capturing regularly.

**Agent:** Got it, that's flow two then: new model drops, spin up a fresh experiment against it, quick local sanity check, then hand it off to CI for ongoing regular capture rather than iterating locally.

Want to keep stacking up workflows before we go back and structure the actual file breakdown, or pause here and start sketching the doc structure with what we've got so far?

**User:** Now let's talk about CI flows. In the CI flows, this would be something that's probably not running that often, because it would probably be expensive. Maybe it's running monthly, or maybe weekly. There are a few things. You would have a static set of experiments that just run monthly, and you wouldn't really expect anything to be changing. But if things did change, that would be something to be very aware of, and you would report that out via your standard reporting tools. Another flow would be: all right, we'll keep the experiments, but we're also going to have one that's basically running against the latest commit, against the latest... what was our term there? Code state. What do we call it — experiment parameter. So the latest code state parameter. We'd probably be doing some kind of live update every time there's a new commit: there'll be a set of experiments that get updated to be the most recent or something. That's something we need to drill into. And then also the same with the prompts. Because one of the key motivations is worrying that, although we haven't made any drastic changes, performance degrades just as the code base gets bigger and as more prompts and skills, et cetera, get added.

**Agent:** Got it, so CI flow one is the scheduled, low-frequency sweep, weekly or monthly, static experiment set, mostly expecting no change, and flagging loudly via your normal reporting if something does shift. CI flow two is the continuous one, tracking against the latest code state parameter on every commit, plus the equivalent for prompts, specifically to catch that slow performance-degradation-as-the-codebase-grows problem, which sounds like a core motivation worth calling out explicitly in the motivations file.

That's a good set to work with. Do you want to capture one or two more flows, or shall we pause and start sketching the actual file structure now?

**User:** Sorry, let me just clarify there. I think both of those that you described would still be on a cadence. I don't think you would be running these experiments every commit — that sounds way too expensive. So maybe it's a weekly task. The point here is that you probably have two categories of experiment. One is where you've caught specific regressions, and you're saying, well, at this exact commit with this exact prompt it does the thing, and with this exact commit and this other exact prompt it doesn't do the thing — and those ones we just want to keep static. The other is checking: at the code state and the prompts as they are now, how is this behaving, versus as they were at these fixed points in time? But both of those would still be running as part of the same weekly cadence.

**Agent:** Got it, thanks for the correction. So both CI flows share the same weekly cadence, the distinction is really about what the experiment's parameters point at: fixed, pinned-in-time experiments that lock in a known regression case for stability tracking, versus floating experiments that track current code state and current prompts, so you can watch for that gradual drift or degradation as the codebase evolves, all evaluated on the same schedule.

That's a nice clean two-category split. Want to note one or two more flows, or start sketching the file structure now?

**User:** Okay, so with that concept of — what do you call it — static experiments and floating experiments, this is something we're going to need to dig into. I think we'd just flag that as something we'll dig into... actually, let's talk about it a little bit now. How would we do that? One way I'm thinking about it is that your CI, as part of the pipeline, would just be updating this experiment. So you could have an experiment which you call "our standard floating experiment", and maybe it has commit X and then commit Y, and on the weekly cadence it just updates commit Y, kind of thing. Do you have any thoughts?

**Agent:** Good question, let me think through it out loud with you rather than just search blindly, since this is really about your own architecture, not an established pattern out there.

So one clean way: the floating experiment's config doesn't hardcode a commit hash at all, it points at something like "latest on main," and a CI step resolves that to an actual commit hash right before the run kicks off, then stamps that resolved hash onto the run's metadata for the record. That way the experiment definition itself stays stable and declarative, "compare fixed-baseline-commit-X against whatever's current," and only the resolution step, run weekly, injects the moving part.

Does that match what you were picturing, or were you thinking the experiment definition file itself gets literally rewritten each week with a new commit hash committed back into git?

**User:** So that latter one was what I was thinking about. But that's not something I'm particularly sold on — I'm thinking out loud here. Because, let's say for example, let's talk about token cost. We want to be able to compare experiments

**Agent:** Yeah, go on, comparing experiments on token cost, that's a good concrete angle to pull the design against.

**User:** over time.

**Agent:** Right, and that longitudinal view is actually a strong argument against rewriting the experiment file in place each week, because if you overwrite the commit hash every time, you lose the history, you can't easily go back and say "show me token cost for this experiment across the last two months" since each past run's context gets clobbered.

That pushes toward your first option instead: the experiment definition stays a stable pointer, "latest on main," and every resolved run, with its actual commit hash, model version, token cost, whatever, gets recorded as its own dated record in the data store. So the experiment identity is stable and comparable over time, but each execution's specifics are preserved as history underneath it rather than overwriting the source config. Does that resolve the tension for you?

**User:** Yeah, it's sounding okay. It sounds like we now have two different experiment types. And

**Agent:** Right, that does feel like it's shaking out as two genuinely different experiment kinds with different behavior, not just two configurations of the same thing. One's pinned and static by design, the other resolves a moving target at execution time and accumulates history underneath a stable identity.

Might be worth literally naming that distinction in the spec, something like pinned experiments versus floating experiments, as a first-class concept rather than an implementation detail. Want to sit with that as a flagged open question for the spec, or keep pulling on this thread now?

**User:** Yes.

**Agent:** Got it, I'll flag pinned versus floating experiments as a named open...

**User:** Yes. I think the way you framed that is perfect. Yeah, I'm not exactly sure about it; that's something worth thinking about. Here's what I think I want to say: for the first pass, we'll just stick to pinned experiments. Because we haven't built anything, and we are going to need to be a bit practical in terms of what we're building here.

**Agent:** That's a sensible scoping call, pinned experiments only for the first pass, ship something concrete, and let floating experiments sit in the spec as a clearly flagged future direction rather than something you're designing fully now.

Want me to note that as the official scope decision, first pass is pinned-only, floating experiments deferred, and then move on to sketching the actual file structure for the spec?

**User:** Yeah, sure. Let's move on. Okay, so hang on — the file structure for the spec. Right. All right, what did we have? We had motivation. We had CI workflows. We're going to have what the experience of setting it up is.

**Agent:** Right, so far that's motivation as one file, user experience split into local workflows and CI workflows, possibly as two files or two sections, and a setup or getting-started file. Want to keep listing candidate files, or should I also fold in structural pieces from the terminology work, like a dedicated glossary file and a core concepts or data model file?

**User:** Yeah, so there's definitely a terminology MD. Okay, now we've got this concept of the Docker — everything up to the Docker run, and the Docker capturing. You run the experiment. The experiment is a set of permutations. And then that is going to spawn the Docker containers. This file will contain information about how the Docker containers get tagged, and then also information about preserving the Docker containers in a registry. There'll be a separate file — help me with some terminology here — it's a kind of configuration, which is to say: this is how you preserve the Docker containers. That might be "we don't do anything", or it might be "this is the URL of the container registry".

**User:** The other thing is that that configuration file would also be how you save the metadata as well.

**Agent:** For that kind of file, "preservation" or "retention" would work well, retention strategy or retention config, covering both where the container images land and how long or whether the metadata gets kept. Would either of those fit what you're after, or is there a more specific angle you're going for?

**User:** Okay, so there are — let me — okay, there are three concepts here, I think, and maybe you want to add your own. One is this concept of the experiment parameters — experiment parameter definitions — and how we are going to hash them to make sure each experiment is genuinely comparable.

**Agent:** Right, that's concept one, the hashing and identity mechanism, how experiment parameter definitions get fingerprinted so you can trust two runs are actually comparable...

**User:** And then you've got the concept of how we actually do the Docker run and the details of that. And then ultimately the artifact of that.

**Agent:** Got it, so that's concept two, the actual Docker execution mechanics, the container run itself and what comes out of it as an artifact.Sorry, that was me pulling up doc tools in...

**User:** the artifact of that

**Agent:** No worries, go on, the artifact of that, the third concept.

**User:** Yeah, you've got the Docker run, and the artifact of that being the preserved Docker containers as well as the summary metadata. And then the third concept is the restore and purging.

**Agent:** Right, so concept three is lifecycle management, restoring an archived container back for inspection, and purging old ones, presumably tied to whatever retention policy applies. So that gives you three clean files: experiment parameter hashing and identity, Docker execution and artifact production, and restore slash purge lifecycle.

Does that three-way split feel complete, or is there a fourth angle in there, like the actual registry configuration itself, where things get stored, as a separate concern?

**User:** Okay, so then other things are going to be about general tooling: what programming languages and things like that, what the requirements there are. Which, by the way, is going to be...

**User:** So what's this out of time warning about? I don't understand it.

**Agent:** That's just my own session running long, nothing about Thunderjar. No need to worry about it, want to keep going with the file structure? You were about to get into general tooling requirements, languages and the like.

**User:** Yeah, so that's going to be Bun, TypeScript. You need to enforce file structure with linting.

**User:** Are you there?

**Agent:** Yeah, I'm here! So, tooling file covers Bun and TypeScript as the stack, plus linting to enforce the file structure conventions. Anything else on the tooling side, or shall we keep building out the rest of the file list?

**User:** All right, could you print what the file list has currently?

**Agent:** Sure, here's the running list. Motivation, its own file covering the problem you're solving. Terminology, the glossary. User experience, likely split into local workflows and CI workflows. Setup, getting the application running initially.

Then three files under the execution concept: experiment parameter hashing and identity, Docker execution and artifacts, and restore and purge lifecycle. And finally, tooling, covering Bun, TypeScript, and linting for file structure enforcement.

**User:** Print it now

**Agent:** Here's the current file list:

1. **motivation.md** — the problem being solved
2. **terminology.md** — glossary
3. **user-experience.md** — local workflows and CI workflows (possibly split into two)
4. **setup.md** — getting the application running initially
5. **experiment-parameters.md** — parameter hashing and identity, ensuring comparability
6. **docker-execution.md** — the Docker run mechanics and resulting artifacts
7. **restore-purge.md** — lifecycle management, restoring archived containers, purging old ones
8. **tooling.md** — Bun, TypeScript, linting for file structure enforcement

Anything to add, split, or rename before we move on?

**User:** Is there anything you think is missing.

**Agent:** A few candidates that don't have a home yet in the list:

- **Configuration reference** — the actual schema/API for `thunderjar.config.ts`, harnesses, prompt sets, tasks, measuring instruments. This is distinct from motivation/terminology and probably needs its own file since it'll have a lot of code samples.
- **Data architecture / storage model** — the two-tier metadata + artifact store design, separate from the Docker-execution file since it's more about how results get persisted and queried long-term, not the run mechanics themselves.
- **Reporting** — how results actually surface to a human, especially for the CI flows ("report that out via your standard reporting tools" needs its own detail: what's the report, where does it go, what triggers a flag).
- **CLI reference** — the actual commands a user runs, if that's substantial enough to warrant its own page rather than living in setup.
- **Goals / non-goals** — you had this in earlier drafts; worth keeping distinct from motivation, since motivation is "why does this problem exist" and goals/non-goals is "what are we and aren't we committing to build."
- **Open questions / risks / deferred work** — a dumping ground for exactly the kind of things we've been flagging today (floating experiments, container-run naming risk, cache isolation specifics) so they don't get lost or block the main spec from feeling "done."
- **Testing strategy for Thunderjar itself** — how you're testing the tool, separate from how the tool tests prompts. Easy to conflate given the domain.

Cache isolation also came up as its own substantial design topic in an earlier session — might deserve its own file rather than being folded into Docker execution.

Want me to slot these into the list, or do you want to weigh in on which are worth keeping first?

**User:** The configuration reference - a lot of that should be covered in the experiment-parameters.md.

What we'll do is put a high level overview of the configuration in `setup.md` (rename to setup-and-configure.md)

And have it reference into other appropriate places.

Data architecture - this is really just a configuration question - but it's separate from the experiment-parameters. But yes, it should have its own file.


CLI reference yes.
We also want another detailed page on CLI Report visualisation for the interactive CLI.

Everything else yes.

**Agent:** Updated list:

1. **motivation.md** — the problem being solved
2. **goals-non-goals.md** — what's in scope vs explicitly not
3. **terminology.md** — glossary
4. **user-experience.md** — local workflows and CI workflows
5. **setup-and-configure.md** *(renamed from setup.md)* — getting the application running, plus a high-level configuration overview that references out to the detailed config pages below
6. **experiment-parameters.md** — parameter hashing/identity, plus the bulk of the detailed configuration reference (harnesses, prompt sets, tasks, measuring instruments)
7. **data-architecture.md** *(new)* — the two-tier metadata + artifact store design, as its own configuration-adjacent concern separate from experiment-parameters
8. **docker-execution.md** — the Docker run mechanics and resulting artifacts
9. **cache-isolation.md** *(new)* — its own file, split out of docker-execution
10. **restore-purge.md** — lifecycle management, restoring archived containers, purging old ones
11. **reporting.md** *(new)* — how results surface to a human, especially for CI flows
12. **cli-reference.md** *(new)* — the actual CLI commands
13. **cli-report-visualization.md** *(new)* — detailed page on the interactive CLI's report visualization
14. **testing-strategy.md** *(new)* — how Thunderjar itself is tested, kept distinct from how Thunderjar tests prompts
15. **open-questions.md** *(new)* — risks, deferred work, unresolved design questions (floating experiments, container-run naming risk, etc.)
16. **tooling.md** — Bun, TypeScript, linting

That's 16 files. Want to keep refining this list, or move on to drafting one of them?

**User:** Where did cache-isolation come from?

**Agent:** Fair question — I marked it "(new)" meaning new to this file list, not a concept I invented just now. It came from an earlier session: the compacted summary I have references a prior conversation titled "thunderjar-design-deepdive" that covered "data architecture, cache isolation, and a test-matrix model" as its own substantial design topic. I pulled it into this file list because it seemed like enough of a distinct concern to warrant its own page, split out of docker-execution, but I hadn't actually re-confirmed the details of that discussion with you in this session.

Want me to pull up that transcript and refresh what was actually decided there before we commit to giving it its own file, or does cache isolation not actually need a dedicated page here?

**User:** Remove cache isolation, remove reporting.md

**Agent:** Updated list:

1. **motivation.md** — the problem being solved
2. **goals-non-goals.md** — what's in scope vs explicitly not
3. **terminology.md** — glossary
4. **user-experience.md** — local workflows and CI workflows
5. **setup-and-configure.md** — getting the application running, plus a high-level configuration overview referencing out to detailed config pages
6. **experiment-parameters.md** — parameter hashing/identity, plus the bulk of the detailed configuration reference
7. **data-architecture.md** — the two-tier metadata + artifact store design
8. **docker-execution.md** — the Docker run mechanics and resulting artifacts
9. **restore-purge.md** — lifecycle management, restoring archived containers, purging old ones
10. **cli-reference.md** — the actual CLI commands
11. **cli-report-visualization.md** — detailed page on the interactive CLI's report visualization
12. **testing-strategy.md** — how Thunderjar itself is tested
13. **open-questions.md** — risks, deferred work, unresolved design questions
14. **tooling.md** — Bun, TypeScript, linting

That's 14 files. Anything else to adjust, or ready to move on?
