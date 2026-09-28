# Gaps, the existing config and content hashing

_Source: `docs/conversation_json.md` lines 582–753. See [README](README.md) for context._

**Covers:** Gaps (infra flakiness, assertion versioning, cost guardrails); immutable v2 files vs content hashing; the existing repo's `ThunderJarConfig` pasted in; name + content hash as identity for prompt sets and measurers; backfilling new measurements on restored containers.

**User:** Yeah, that makes sense to me. Okay, look, I think everything we've talked about covers the gist of everything. How about you — can you come up with any gaping things you think we haven't talked about?

**Agent:** A few genuine gaps worth naming.

First, flakiness and retries within Thunderjar's own test suite, not the coding agent's flakiness, but if a Docker daemon call or a registry push occasionally times out for boring infrastructure reasons, you'll want that distinguished cleanly from an actual failing assertion, otherwise noisy infra failures pollute your pass-rate statistics.

Second, we never really discussed versioning the assertions themselves. If you improve a database assertion helper six months from now, and someone reruns an old test case against it, do old preserved runs get reinterpreted under new assertion logic, or are results permanently tied to the assertion version that produced them? That matters a lot for your trend-over-time comparisons being trustworthy.

Third, and maybe the biggest one, cost and rate-limit governance for the batch-of-fifty-or-hundred loop specifically, some kind of built-in guardrail or estimated-cost preview before firing off a hundred real paid API calls, since that's an easy way to get an unpleasant surprise if someone fat-fingers the iteration count.

Want to dig into any of those, or are you happy to leave it here for now and let those percolate?

**User:** Yeah, brilliant. Those last two are both really good points. On the cost thing, I would say that's a nice-to-have to build later. On the flakiness thing, again, I would probably flag it as a nice-to-have to do later. Because really, in terms of actually building this, we're trying to build a proof of concept. But yes, the test assertions themselves — that absolutely sounds like something that needs to be dealt with. Now, what I would say is: if I've got my test case, which is code at commit A and prompts at commit B,

**User:** and then I've got my test assertions at commit X, and then I update my test assertions at commit Y — those are two completely different test cases, right? Maybe I want to compare them against each other, but not really. Those are two completely different test cases. How do you cover that in this conceptual model? Do you have any thoughts?

**Agent:** That actually resolves cleanly if you just extend your existing matrix rather than inventing a new mechanism, treat the assertion set's own commit or version hash as a sixth axis alongside code commit, prompt commit, model, harness version, and task, exactly the same way you're already handling code versus prompts as separate commits.

So a run's full identity becomes that whole tuple, and two runs that differ only in assertion commit are, as you say, genuinely different test cases, not directly comparable pass-rate to pass-rate, since a change in assertion logic can make the same underlying agent behavior newly pass or newly fail for reasons that have nothing to do with the agent getting better or worse. Your trend-over-time view then naturally becomes, hold everything constant except one axis and compare along that axis, code-commit-over-time trends only make sense when assertion commit is pinned, assertion-commit comparisons only make sense when code and prompts are pinned, and so on, which is really just applying the same matrix discipline you already have to the one axis you'd been implicitly treating as fixed background rather than a first-class parameter.

**User:** Yeah, I don't think I'm a big fan of what you're talking about. That starts feeling really hard to understand. I think I would sooner just have — I need to get clear on some of the terminology — but each test case would be its own file, right? And have some kind of commit hooks or something that says, once you've created the file, you never change it. Some way of saying, right, now it's finalized, never touch it ever again. And if you want to modify it, you have to create a v2 of it, and that way you're being really clear about what you're doing, rather than some whole commit thing that seems a bit messy. With the prompts, I'm more comfortable with the prompts. Now, I think one thing to be clear about is — tell you what, have you got the link to the Thunderjar repository there?

**Agent:** I don't have it pulled up right now, but I do have it noted, it's `github.com/dwjohnston/thunderjar`. Want me to actually go fetch what's in there so we're looking at the real current state rather than reasoning from memory?

**User:** All right. Yeah, go have a look at it, take a look at the example commits, and you can see in the Thunderjar config how we are doing the prompt application.

**User:** And one thing you'll note is that the prompt application is me just copying the prompt. But that could be a git checkout of a specific commit type thing. So go take a look at that.

**Agent:** That search isn't surfacing the actual `dwjohnston/thunderjar` repo directly, web search doesn't seem to be indexing it, possibly it's private, or new enough not to be crawled yet. Is it public? If it's private I genuinely won't be able to pull its contents without you sharing the file directly, web search only reaches what's publicly indexed.

**User:** Are you able to just visit that URL directly?

**Agent:** I don't have a direct URL-fetch tool available right now, just web search, which isn't indexing it, likely because the repo's private or too new. If you can paste the relevant config file or commit contents in as text, I can dig into the prompt-application approach with you directly that way.

**User:** Sure, I'm just going to paste it in now.

**Agent:** Go ahead, I'm ready for it.

**User:** ```
import { ThunderJarConfig } from '../src/ThunderJarConfig.ts';

const instruction =
    'Write a TypeScript function called `add` that takes two numbers and returns their sum. Save the file as add.ts. Put it in the output folder. Commit the changes.';

export default new ThunderJarConfig()
    .configure({
        testRunner: 'bun test',
        harnessWorkingDirectory: 'evaluation-sandbox',
        onWorktreeCreate: () => 'git config commit.gpgsign false',
    })
    .registerHarness({
        harnessName: 'claude-code',
        models: ['claude-haiku-4-5-20251001'],
        cli: (ctx) =>
            `claude -p "${ctx.taskInstruction}" --model ${ctx.model} --allowedTools "Write,Edit,Read,Bash" --append-system-prompt "You are running in headless (non-interactive) mode."`,
    })
    .registerHarness({
        harnessName: 'opencode',
        models: [
            'opencode/deepseek-v4-flash-free',
            'opencode/north-mini-code-free',
            'opencode/claude-haiku-4-5',
            'opencode/big-pickle',
        ],
        cli: (ctx) =>
            `XDG_DATA_HOME=${ctx.worktreePath}/.opencode opencode run "${ctx.taskInstruction}" --model ${ctx.model} --dangerously-skip-permissions`,
    })
    .registerHarness({
        harnessName: 'cursor',
        models: ['composer-2.5', 'kimi-k2.5'],
        cli: (ctx) => `agent -p --force "${ctx.taskInstruction}" --model ${ctx.model}`,
    })
    .registerPromptSet({
        promptSetName: 'snerk',
        cli: () => 'cp evaluation-sandbox/prompts/base_prompt_snerk.md CLAUDE.md',
    })
    .registerPromptSet({
        promptSetName: 'glurk',
        cli: () => 'cp evaluation-sandbox/prompts/base_prompt_glurk.md CLAUDE.md',
    })
    .registerTask({
        taskName: 'add-function',
        instruction,
        measurements: [
            { measurerName: 'fileCreated', config: { glob: 'output/add.ts' } },
            {
                measurerName: 'grep',
                config: { glob: 'output/**', pattern: 'snerk', expect: 'present', scope: 'worktree' },
            },
        ],
    })

    .registerExperiment({
        experimentName: 'snerk-vs-glurk',
        taskName: 'add-function',
        commitHash: 'HEAD',
        variables: {
            harnesses: { 'claude-code': ['claude-haiku-4-5-20251001'] },
            promptSets: ['snerk', 'glurk'],
        },
    })
    .registerExperiment({
        experimentName: 'snerk-various-opencode',
        taskName: 'add-function',
        commitHash: 'HEAD',
        variables: {
            harnesses: {
                opencode: [
                    'opencode/deepseek-v4-flash-free',
                    'opencode/north-mini-code-free',
                    'opencode/claude-haiku-4-5',
                    'opencode/big-pickle',
                ],
            },
            promptSets: ['snerk'],
        },
    })
    .registerExperiment({
        experimentName: 'snerk-various-cursor',
        taskName: 'add-function',
        commitHash: 'HEAD',
        variables: {
            harnesses: { cursor: ['composer-2.5', 'kimi-k2.5'] },
            promptSets: ['snerk'],
        },
    })
    .construct();
```

**Agent:** Okay, this is really clarifying, actually, a few things fall into place from seeing it directly.

First, terminology check: `measurers` are what we've been calling assertions this whole conversation, `fileCreated` and `grep` here. Good to have the real names now.

On the prompt application question, yeah, exactly what you said, `promptSets` right now are literally just a `cp` of a static markdown file into `CLAUDE.md` at worktree setup time, no git involved at all. Swapping that `cli` field to something like `git show <commit>:prompts/snerk.md > CLAUDE.md`, or even just checking out that one file from a specific commit into the worktree, would be a small, contained change since the whole promptSet abstraction is already just "run this shell command during setup," you're not fighting the architecture, just changing what one function returns.

A few things jump out from seeing the actual shape of this:

The `variables` block on `registerExperiment` is your matrix-axis mechanism, and right now it only varies `harnesses` and `promptSets`, task and `commitHash` are pinned per-experiment rather than swept. That maps cleanly onto what we discussed, though I notice `commitHash` is currently just `'HEAD'` as a literal string, not yet wired up to actually checking out that commit into the worktree for the test run, or is that handled elsewhere in `ThunderJarConfig` that isn't shown here?

On the assertion-versioning conversation we just had, seeing this config makes me like your file-per-test-case, never-mutate, bump-to-v2 instinct even more, since a `measurers` array is just plain data sitting inline in the task registration, there's no separate "assertion commit" to track, the task's own commit in its own config file already is the assertion version, for free, without needing a sixth matrix axis at all. That's simpler than what I was proposing.

One real gap I'd flag from reading this literally: `harnessName` and `models` are declared once per harness up top, but the experiments then re-list which subset of those models to use per-experiment, that's duplication that could drift, is there validation anywhere that an experiment's requested model is actually one the named harness supports?

**User:** So let's get back to the issue we were talking about, that if your tests

**User:** All right, so let's get back to that issue that if the test measurements change, then they wouldn't be consistent across runs. What I'm thinking is, if you take a look at that concept of prompt set I have — earlier in the conversation I was saying that the prompts are a specific commit, but really it doesn't have to be a specific commit, it could be anything that's just a function that gets applied. But yes, if you adjusted the prompt set, then you would have that same problem, right?

**Agent:** Right, exactly, same failure mode, just relocated. If someone edits the `snerk` prompt set's markdown file in place, every historical run tagged `promptSets: snerk` retroactively becomes ambiguous, since "snerk" no longer reliably points at one fixed piece of content, exactly the versioning problem we hit with measurers.

And actually, seeing the config now, I think your v2 instinct resolves this one the same clean way. Since `registerPromptSet` just takes a name and a function, the discipline would be, once a promptSet name has been used in any experiment run, that name is frozen, content and all, and a change becomes `snerk-v2` as a new registration, not an edit to `snerk`. That's consistent with your file-per-task, never-mutate approach, and it means the promptSet name itself becomes the stable version identifier, no separate commit-hash tracking needed, same logic you liked for measurers, just applied here too.

**User:** Now, here's what I'm thinking. Firstly, your Thunderjar config isn't a single file. You would have a folder for prompt sets, a folder for measurers, a folder for tasks maybe, I'm not sure. So you could still have the snerk prompt set, and that is a file. And then when you actually run a test using the snerk prompt set, you use a hash of that file. So you could allow someone to edit the file, but when you're actually recording the data, you're recording it with the prompt set name as well as the file hash, and it's that combination that you use to determine fixedness. I think the key thing is that you would have to make sure the contents of the file are truly deterministic. If it was making an API call, for example, that wouldn't be very reliable, but I think we can call that kind of issue a user error.

**Agent:** That's a nicer solution than the freeze-and-rename convention, actually, because it removes the human discipline requirement entirely, nobody has to remember not to edit a file, the system just detects when they did and reflects it honestly in the record.

So concretely, at run time you'd compute a content hash of the promptSet's actual output, or the source file, or both, and store name-plus-hash as the true identity in your run metadata, not just the name. Then your trend-over-time view can say, these five runs all used snerk at hash abc123, genuinely comparable, versus this later run used snerk at hash def456, flag it, different actual content despite the same label, don't silently compare it against the earlier batch. And your file-never-mutate instinct from before actually still shows up naturally as a nice-to-have on top, since if you wanted to enforce immutability rather than just detect drift, the hash gives you the mechanism to do it, reject a run if the computed hash doesn't match a hash you've seen and pinned before for that name.

Your determinism caveat is the right scope boundary too, this only cleanly works for static or deterministically-generated content, and a promptSet that shells out to something non-deterministic breaking your hash-based comparisons is fair to call user error rather than a framework problem, same as we already carved model-delegation nondeterminism out as an observed outcome rather than a controlled variable earlier.

**User:** And then another concept here is you could do a similar thing with measurements. The thinking here is that I could have a task using code commit A and prompt set B, and I had my measurements A, B and C, and that's working fine. But then later on I'm like, oh, actually, I should be measuring D, E and F. The main thing is that I shouldn't have to go and rerun that coding agent in order to add additional measurements against it. I should be able to restore those previously saved runs and just apply those new measurements later on. The same thing applies there, of course: the measurements themselves can't change. But you could always add new measurements. That seems like not a problem.

**Agent:** Oh, that's a really nice consequence of the container-restore architecture we already landed on. Since you're preserving full filesystem state via `docker commit` for every run, or at least flagged ones, applying a brand new measurer to an old run doesn't require re-running the agent at all, you just restore the container and execute the new measurer's check against the already-existing final state.

And the hash idea extends cleanly here too, same pattern as promptSets, each measurer's logic gets content-hashed, so a run's stored results become a growing map of measurer-name-plus-hash to pass or fail, rather than one fixed array. Adding D, E, F later means restoring the old container, running the three new measurers against it, and appending their results to that same run's record, existing A, B, C results untouched, since their measurer hashes haven't changed. Retroactively editing what B actually checks for is exactly the case the hash catches, that's not "adding a measurement," that's silently redefining an existing one, and now you can tell the difference automatically instead of trusting nobody touched the file.

Does that match what you were picturing, restoring specifically to backfill new measurers onto historical runs, rather than needing everything decided upfront?

**User:** Yes, and there's also a nice developer experience workflow here. Say I create the initial task prompt and I use the prompt set, and an AI goes off and does the thing, and it looks like it's all working fine. But as a developer, I'm struggling to get the measurers right, because it's like writing a test or something like that. I don't want to have to keep rerunning it every time just to test that I've got my measurers right. So the idea is: no, we've already done the AI run, now I'm just working on getting my measurers right.

**Agent:** That's a really clean split, it decouples two totally different iteration loops that normally get smooshed together and made expensive as a result. Writing a measurer is fundamentally just writing a test against a known filesystem state, that's a fast, local, deterministic loop, restore the container once, then hammer on the measurer logic against that same fixed snapshot as many times as you want, no tokens spent, no agent variance to worry about, you're purely debugging your own grep pattern or glob or assertion logic.

It's basically test-driven development against a fixture, the agent run produced the fixture once, expensively, and now the fixture is free to reuse. Combined with the hash idea, once you're happy with the measurer, it gets locked in with its content hash, and you've effectively built the assertion using the exact same restore-and-inspect workflow a developer would use to debug a failing one later.
