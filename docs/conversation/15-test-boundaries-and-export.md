# Test boundaries, and exporting the conversation

_Source: `docs/conversation_json.md` lines 1747–1848. See [README](README.md) for context._

**Covers:** Test boundaries for Thunderjar: recording adapters, fake harness in real Docker, artifact assertions, lifecycle tests, unit tests, real-harness smoke test; renaming to test-boundaries.md; exporting the conversation.

**User:** Let's talk about testing this. If we take the CLI, for example — whether you're running the CLI interactively, or running it with the CLI one-liners because you'll be running it in a CI pipeline — I'm thinking the way you would test this is that you would dependency-inject anything non-deterministic. That includes the Docker. You would just cut everything off: you wouldn't actually spawn Docker, and instead of running actual Docker, you would just print the Docker commands that get run. And then you could just assert on standard out. That would be a pretty nice way to do this. For the Docker stuff, there are a couple of things. One would be: you have a starting Docker image. Assuming we've got the right Docker image, you can run your fake harness, and we know that the fake harness is going to make whatever file changes. I think that probably wants to go all the way up to creating the metadata report, that kind of thing. And then the purging stuff — the concept of purging or restoring, that kind of thing. I think that's a... well, given that this Docker image already exists, let's do the restore and now expect: these branches exist, these files exist. Give me your breakdown.

**Agent:** Your instinct is sound: push everything non-deterministic behind injected interfaces, then test at three layers with increasing realism.

**Layer 1: CLI with a dry-run adapter (fast, no Docker)**
- Inject every side-effecting dependency: Docker, git, registry, filesystem, clock, and ID/randomness. Give each a real implementation and a recording one.
- The recording Docker adapter prints the commands it would have run, and tests assert on stdout. Interactive and one-liner modes both go through the same command layer, so one strategy covers both.
- Make the printer a real implementation of the same interface rather than a separate `--dry-run` code path. Otherwise the tested path diverges from the shipped one.
- Normalize volatile output (timestamps, temp paths) before snapshotting, and be careful about asserting on exact flag ordering, since it will make tests brittle.
- For the interactive CLI, keep the view-model separate from the rendering, so most of it is testable as plain data with only a thin layer left to check.
- This layer proves the wiring: the right permutations, tags, and commands are generated. It doesn't prove the commands work.

**Layer 2: Real Docker with a fake harness**
- Start from a known base image and run a deterministic fake harness in place of the real agent. It's a script that makes scripted changes (write these files, create this branch) and can be parameterized to crash, time out, or emit a given token count.
- Run the whole pipeline: container run, then measuring instruments, then the metadata report. Assert on the resulting metadata and container state.
- It's slower and needs Docker, so tag it and keep it out of the fast inner loop.
- The fake harness costs nothing to run and never involves an LLM. Add a contract check that its output shape matches what real harnesses produce, so the two don't quietly drift apart.

**Layer 3: Lifecycle (restore and purge)**
- Start from an image that already exists, either a checked-in fixture or one produced by a Layer 2 run.
- After a restore, assert that the expected branches and files exist. For purge, assert that images and metadata are removed per the retention policy, that nothing still referenced is removed, and that running it twice is safe.
- If you want to test the registry push and pull for real, use a throwaway local registry container rather than a mock.

**Pure unit tests (cheap and worth doing early)**
- Hashing gets golden-value tests: the same parameters always give the same hash, changing any relevant parameter changes it, and irrelevant differences such as key ordering don't.
- Measuring instruments are pure functions over fixture directories, so they're trivial to test in isolation.

**One gap remains**
None of this exercises a real harness talking to a real model. A small, manual or scheduled smoke test against a real harness would cover that. It should be non-blocking, since it's non-deterministic and costs money.

Want me to fold this into a draft of `testing-strategy.md`?

**User:** I think there's probably another layer which is something around

'Given that I have an experiment like this, it will create a docker image, and now \<assertions on the docker image\>, correct git history, correct files, etc'

**Agent:** Yes, that's a distinct layer, and it's about the artifact itself rather than the process that produced it. Layer 2 asks "did the pipeline run correctly end to end?", whereas this asks "given this experiment definition, is the resulting image what the spec says it should be?"

**Layer 2.5: Artifact assertions (image as the unit under test)**

The flow is: define a fixture experiment, execute it with the fake harness, then inspect the resulting image or container as data.

Things to assert on:
- **Tag and identity:** the image tag equals the expected parameter hash. Changing one parameter produces a different tag, and re-running the identical definition produces the same tag. This is where the hashing contract gets checked against real Docker rather than just as a pure function.
- **Git state inside the image:** the expected branches exist, the commit history matches what the fake harness scripted (count, order, messages), and the working tree is clean or dirty as expected. The checked-out commit should be the pinned one.
- **Filesystem contents:** the files the harness was scripted to write exist with the expected content, and files that should be absent are absent (for example, nothing from the host leaking in, and no credentials).
- **Metadata embedded or attached:** labels on the image (parameter hash, experiment name, permutation, iteration) are present and correct, and the metadata report matches the image it describes.
- **Reproducibility of the base:** the starting layers match the declared base image digest, so you know the pinned state was actually what got used.

Practical suggestions:
- Write a small helper that takes an image reference and returns a plain object (labels, git log, branch list, file tree). Assertions then run against that object, which keeps tests readable and lets you snapshot it.
- Consider running the inspection inside the container via `docker run --rm <image> git log ...` versus exporting the filesystem. The first is easier for git state, the second for exact file contents.
- Keep the fixture experiments tiny (a few files, a couple of scripted commits) so image builds stay fast.
- This layer doubles as the safety net for restore, since a restore test can start from a known-good fixture image and assert the same artifact shape.

Do you want this as its own named layer in `testing-strategy.md`, or folded into the Docker-execution layer as its assertion phase? I lean toward separate, since it has a different failure meaning: Layer 2 failing means the pipeline broke, while this failing means the artifact contract broke.

**User:** Yes, I think call it 'test-boundaries.md'

**Agent:** I'll take that as renaming `testing-strategy.md` to `test-boundaries.md`, with the four layers inside it. The name fits, since each layer is defined by where the mock/real boundary sits:

1. Pure units (hashing, measuring instruments)
2. CLI with recording adapters (Docker is never spawned)
3. Real Docker with a fake harness (pipeline end to end)
4. Artifact assertions (image tag, git history, files, labels)
5. Lifecycle (restore/purge from an existing image)

The real-harness smoke test sits outside these as a non-blocking, non-deterministic check.

Updated file list:

1. **motivation.md**
2. **goals-non-goals.md**
3. **terminology.md**
4. **user-experience.md**
5. **setup-and-configure.md**
6. **experiment-parameters.md**
7. **data-architecture.md**
8. **docker-execution.md**
9. **restore-purge.md**
10. **cli-reference.md**
11. **cli-report-visualization.md**
12. **test-boundaries.md** *(renamed from testing-strategy.md)*
13. **open-questions.md**
14. **tooling.md**

If you meant a separate file just for the artifact-assertion layer, alongside a general testing-strategy file, tell me and I'll split it. Otherwise, do you want to draft `test-boundaries.md` now?

**User:** Is there a way we can export this entire conversation

**Agent:** Let me check the current docs for how export works, since that's a product feature that may have changed.

I didn't find an official Anthropic help page in the results, only third-party write-ups, so treat this as unverified against Anthropic's own docs.

- **Account-level export:** According to one guide, you request it from Settings, it's emailed to you, and it covers your whole history as JSON. It's all or nothing, with no way to pick a single conversation. Another source says the export is available on the web app and Claude Desktop only, not iOS or Android.
- **Single-conversation export:** Browser extensions and bookmarklets fill this gap. One open-source Chrome extension exports individual conversations or bulk ZIPs as JSON, Markdown, or plain text. A bookmarklet downloads the open conversation as a Markdown file and runs entirely in your browser. These are unofficial, so weigh that before granting them access to your chats.
- **Copy and paste:** This is the lowest-tech option. Select the conversation and paste it into a Markdown file.

I can also build the export from inside this chat. This conversation was compacted, so the early part exists only as a summary in my context, though the full transcript of that earlier part is stored in the container. I could produce a single Markdown file with that summary, the transcript reference, and everything from here onward (terminology decisions, the 14-file spec structure, the agentic-coding framing, and the four-layer test breakdown).

Do you want that file, or is a full raw export what you're after?
