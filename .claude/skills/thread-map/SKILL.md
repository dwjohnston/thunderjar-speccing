---
name: thread-map
description: Keep a long exploratory/planning conversation organised as a tree of nodes in a markdown file, so branches don't get lost and deep dives don't pollute the main context. Use when the user says "/thread-map", "map this conversation", "track the options", or when an answer branches into multiple possibilities (hypotheses, options, approaches) that will be explored one at a time.
---

# Thread Map

A conversation is anchored by a markdown file (the **map**). The map is the source of truth for
what has been raised, what is settled, and what is still open. The chat is just the current view.

## File

Path: `.claude/threads/<short-topic-slug>.md` (create the dir if needed). One file per conversation topic.

```markdown
# <Topic / the original question>

## Context
<2-5 lines: the problem, constraints, what the user has told us. Update rarely.>

## Nodes
- [ ] **N1 Alpha bravo charlie** — open
  - Claim: <one line>
  - Notes: <findings so far, 1-4 lines>
  - [x] **N1.1 What is "alpha"?** — resolved: <one-line answer>
- [~] **N2 Delta tango** — exploring
- [x] **N3 Echo foxtrot** — ruled out: <why>
- [-] **N4 Golf** — parked: <why / when to revisit>

## Decisions
- <decision> (from N#)

## Open questions
- <things only the user can answer>
```

Status markers: `[ ]` open, `[~]` exploring, `[x]` resolved / ruled out, `[-]` parked.
IDs are stable and never reused. Nest clarifying side-questions under the node that spawned them.

## Rules

1. **Create the map the moment an answer fans out** into 2+ possibilities. Seed one node per
   possibility, tell the user the path, and continue.
2. **Re-read the map at the start of each turn** (it is short). Never rely on memory of the chat
   for what's open.
3. **Update the map after every substantive exchange**: set status, add a one-line result, add
   new child nodes. Edit in place; keep entries terse. Record conclusions, not transcript.
4. **Keep the main thread clean via branch subagents.** When the user asks to dig into a node
   ("tell me about Delta Tango"), spawn a subagent (Agent tool, `general-purpose` or `Explore`)
   with only: the Context section, that node's entry, and the specific question. It returns a
   <=10 line summary; write that into the node and present it. Do not carry the full exploration
   into the main thread. Simple one-line clarifications ("what is alpha?") can be answered
   inline and logged as a child node.
5. **Close the loop**: end each response with a compact status line listing open nodes, e.g.
   `Open: N1 (alpha bravo), N2 (delta tango) · Resolved: N3 · Parked: N4`. If the user has
   drifted, name the node they drifted from rather than silently dropping it.
6. **Don't invent nodes** the user or you haven't actually raised. Don't pad the map.
7. When all nodes are resolved/parked, summarise into **Decisions** and offer next steps
   (plan, implementation, handoff).

## Commands the user may use
- `map` — print the current map.
- `back to N#` — resume that node.
- `park N#` / `drop N#` — change status.
- `fork N#: <question>` — explicitly spawn a branch subagent for that node.
