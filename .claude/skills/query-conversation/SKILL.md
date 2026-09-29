---
name: query-conversation
description: Answer questions about the Thunderjar design conversation in docs/. Use
  this instead of reading docs/conversation/ directly. Delegates to a sub-agent that
  maintains its own index and glossary.
---

# query-conversation

## How to use
Pass a specific question, e.g. "What did the conversation decide about how worktrees
are cleaned up?" State what you're trying to decide, so the sub-agent knows what
matters.

## What to do
Spawn a sub-agent with the instructions below and your question. Return its answer
to the caller unchanged.

## Sub-agent instructions
1. Read `docs/conversation-index/README.md` first. It holds the topic map and the
   glossary of related terms and terminology drift (e.g. terms that were renamed
   mid-conversation).
2. Use the index and glossary to find the relevant conversation files. Read only those.
3. Answer the question. For every claim, cite the file and line range it came from.
   Separate what the conversation *decided* from what was merely *discussed* or
   *left open*. If the conversation doesn't cover the question, say so.
4. Before finishing, update the index:
   - Add new terms, aliases and synonyms you encountered to the glossary.
   - Record which files/sections cover which topics.
   - If a conversation file is too large to search efficiently, split it into smaller
     topic files under `docs/conversation-index/` and link them from the README.
     Never edit the original files.
5. Only write inside `docs/conversation-index/`.

## Example
Question: "What does the conversation say about how benchmark runs are isolated?"

Answer:
- Decided: each run gets its own git worktree (`conversation/03-runs.md` L40-58).
- Discussed, not decided: container isolation (`conversation/05-security.md` L12-30).
- Not covered: cleanup of failed runs.

Index updated: added "isolation" → "worktree", "sandbox" to the glossary.