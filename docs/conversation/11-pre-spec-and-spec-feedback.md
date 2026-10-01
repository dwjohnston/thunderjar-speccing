# Pre-spec and spec feedback

_Source: `docs/conversation_json.md` lines 914–1157. See [README](README.md) for context._

**Covers:** Pre-spec request, quick-fire decisions round, full spec request, and the user's comments on the spec artifact (motivations, base image, MCP faking out of scope, hashed harness definitions, per-environment config, TypeScript 7).

_[Editor: the user's artifact comments below were relayed into the chat wrapped in repeated tool boilerplate (relay instructions, thread IDs, anchor element paths). That boilerplate has been removed; only the comment text and timestamp are kept. The spec artifact itself (https://claude.ai/code/artifact/bb50009f-7148-47df-a1cc-02a6d6a2eb69) is not part of this transcript.]_

**User:** All right.

**User:** Summarise everything we have talked about as a spec.

**User:** Summarise everything we have talked about as a spec.

More of a pre-spec. At this point we have a pretty clear idea of what we want to build. Document it, call out the risks and still open questions. I will later iterate with an AI for fully speccing this out.

**Agent:** Outline's up — filling it in now, section by section.

Good, that worked. Continuing with the rest of the sections.

Now risks and open questions — the substantive part.

All sections are filled. Now the required comment — asking David to confirm/choose on something genuinely open in the doc.

Thunderjar Pre-Spec is ready — read it over, edit inline, or comment.

**User:** Your task. Enter a quick fire iterative loop with me, asking me questions, we're just trying to make clear some of these really low hanging fruit.

**Agent:** Let's knock these out one at a time.

_[Editor: in this quick-fire round, each user message pairs a question (Q) with the user's answer (A).]_

**User:** Q: Is `commitHash: 'HEAD'` actually wired up to checkout a commit into the worktree anywhere in ThunderJarConfig, or is it currently just a literal placeholder string?
A: Shouldn't be allowed/is for debugging only.

**Agent:** Got it — `HEAD` is a debug-only convenience, not a supported production value. Next.

**User:** Q: Should an experiment referencing a model not declared on its harness be caught at config-build time, or is a runtime failure fine for now?
A: Build-time validation error

**User:** Q: When a prompt set or measurement's computed hash doesn't match a previously seen hash for that name, should that be a hard error, or just a flagged warning that still lets the run proceed?
A: Warning only — flag it but still record the run

**Agent:** Next.

**User:** Q: Base-image/dependency drift affecting restored containers (e.g. a measurer needing the exact runtime years later) — in scope to solve now, or deferred risk for the PoC?
A: I'm not seeing how this is a problem. The fact that we are using containers should perfectly solve this problem. Though - this does highlight the need to preserve the containers at _the start_ of a run as well. Like what I'm thinking here is that sure, say the node version gets a minor bump etc, then technically measurements from now vs six months ago aren't comparable. We could opt into comparing them nonetheless. Or we just accept that, you run the 'now' measurement with the same old docker image.

**Agent:** That reframes it well — the container itself is the pinned runtime, so restoring old image + old node version means no drift at all. The gap was just that snapshots need to capture start-of-run state too, not only the end state. Good catch.

One more:

**User:** Q: Given we now need a start-of-run snapshot too (for exact runtime restore), should that be taken for every run by default, or only for flagged/failing runs like the end-state snapshot?
A: I think the container snapshot becomes one of the variables of a task.

**Agent:** That's a clean fold-in — same pattern as prompt sets and measurements: the container base image is versioned/hashed and pinned as part of the task's identity, not a separate snapshot-timing policy.

**User:** Q: For flakiness in Thunderjar's own infra calls (Docker/registry) vs genuine assertion failures — worth a quick default now, or still fine to defer?
A: For now, treat all errors as a kind of special error case that we ignore.

**Agent:** Good — that folds cleanly into the existing `erroredWhileMeasuring` outcome type, no special retry machinery needed.

That covers the concrete open items sitting in the doc right now. Want me to keep going with another round, or fold these six answers into the doc?

**User:** Update the doc.

**Agent:** All ten edits applied successfully. Now replying to the open comment thread with the decision.

Doc's updated with all six decisions, and I replied in the comment thread.

**User:** Summarise everything we have talked about as a spec.

Make use of the https://github.com/dwjohnston/thunderjar repository to give context, but do not consider it authoritative. The ideas discussed in this chat should be considered authoritative. 

The spec should include details about

- file structure
- configuration structure
- tools (packages etc) used to author the application
- What tools the user is expected to have available on their machine
- Detailed diagrams using mermaid js outlining user flows

**Agent:** Outline's up — now pulling in the repo for context.

Now reading the repo and prior notes for context.

Filling in the overview first.

Now terminology.

Now the core concepts: identity, hashing, backfill.

Next, the file structure.

Now the configuration structure.

Now run execution.

Now the data architecture.

Now the CLI.

Now the authoring tools and testing strategy.

Now what users need installed.

Now the user-flow diagrams.

Last section: risks and open questions.

[Thunderjar Specification](https://claude.ai/code/artifact/bb50009f-7148-47df-a1cc-02a6d6a2eb69) is ready. You can edit it inline or leave comments and I'll revise.

**User (comment on the spec artifact, 2026-09-25T16:04:59Z):**
> ＠Claude I think it's worth expanding the motivations. 
>
> This blog post of mine also has context: https://blacksheepcode.com/posts/coding_agent_testing
>
> One motivation is that our coding prompts might be working fine, but in six months time we notice it performing worse. Is that because the model is worse, or is that our prompts have become bloated ? or is it our codebase? 
>
> Another motivation is that we might be considering switching model, or switching harness, and wanting to know if it is still performing well.

**Agent:** I added a Motivations section to the Overview; my reply is in the comment thread on the page.

**User (comment on the spec artifact, 2026-09-25T16:06:12Z):**
> ＠Claude I think it's worth having a conversation about whether the terminology works. For example Measurer and Measurement might just be confusing.

**Agent:** I replied in the comment thread on the page with some terminology options to choose from.

**User (comment on the spec artifact, 2026-09-25T16:08:27Z):**
> ＠Claude We also need to include the base docker image that the prompt initially starts running in. 
>
> Some context:
>
> Base-image/dependency drift affecting restored containers (e.g. a measurer needing the exact runtime years later) — in scope to solve now, or deferred risk for the PoC? I'm not seeing how this is a problem. The fact that we are using containers should perfectly solve this problem. Though - this does highlight the need to preserve the containers at _the start_ of a run as well. Like what I'm thinking here is that sure, say the node version gets a minor bump etc, then technically measurements from now vs six months ago aren't comparable. We could opt into comparing them nonetheless. Or we just accept that, you run the 'now' measurement with the same old docker image.

**Agent:** I added the base image digest to run identity and a preserved start image per permutation, and replied in the comment thread on the page.

**User (while viewing the spec artifact):** For now, MCP faking is out of scope.

**Agent:** MCP faking is now out of scope. It's listed under non-goals, and the fake MCP servers and the `mcpCalls` measurer are moved to Deferred. I also took out the `mcp-fakes/` folder, the `mcpFakes` task field and the pipeline step that started fake servers, and the credentials section now just says tasks with external side effects aren't covered in the proof of concept.

**User (comment on the spec artifact, 2026-09-25T16:12:43Z):**
> ＠Claude You are following the existing repository too literally here. 
>
> I think registering harnesses need to be a first class ... artifact? Like prompt sets. And doing the file hashing stuff. That is, changing the configuration of the harness should invalidate comparison between an older and new run.

**Agent:** Harnesses now have their own hashed definition folders; my reply is in the comment thread on the page.

**User (comment on the spec artifact, 2026-09-25T16:16:04Z):**
> ＠Claude I think what we want is some kind thunderjar.local and thunderjar.ci files that allow configuration on a per environment basis. It's not to say that 'local runs are always ephemeral' - that's likely the recommended flow, but that's just a configuration for the user to make.

**Agent:** I added per-environment config files (`thunderjar.local.ts` and `thunderjar.ci.ts`); my reply is in the comment thread on the page.

**User (comment on the spec artifact, 2026-09-25T16:16:36Z):**
> ＠Claude Version 7.

**Agent:** The spec now says TypeScript 7; my reply is in the comment thread on the page.

**Agent:** Hey, I've lost the thread on this — long conversations do this sometimes. Let's start a fresh conversation.
