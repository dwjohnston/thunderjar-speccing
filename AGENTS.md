# AGENTS.md

## General Agent instructions

### AI Generated Content Headers

#### Commit messages

Add the following message the bottom of commit messages: 

```
🤖 Commit message created by AI. <harness>/<model>
```

Populate the `<harness>/<model` part with appropriate values. 

## What this repo is

We are speccing out the Thunderjar application, as described in the source design
conversation, split by topic in [docs/conversation/](docs/conversation/README.md).
This repo does not contain Thunderjar's implementation — just the spec.

## Spec conventions

- The spec is a work in progress. Nothing written down in `spec/` should be treated as
  canonical or final — it reflects current thinking, not a locked decision.
- A paragraph starting with 🙋‍♂️ is a note from the user *about* the documentation itself
  (a comment, correction, or question on what's written), not part of the spec's actual
  content. Don't fold it into surrounding prose as if it were a spec statement.

## Folder structure

- `docs/` — source material: the raw and extracted design conversation(s) this spec is derived from.
- `docs/conversation/` — the design conversation split into topic files. Start at its
  `README.md` (index, terminology drift, decisions) and read only the parts you need.
  Don't read `docs/conversation_json.md` or `docs/conversation_raw.json` unless you need
  to check the original wording.
- `spec/` — the spec itself, one file per concern. See `spec/README.md` for the index and reading order.
- `spec/*.raw.md` — the user's own scratch notes for the corresponding spec page (e.g.
  `03-terminology.raw.md` for `03-terminology.md`). Do not read these unless the user
  specifically points you at one.

## Working style

- Before starting any task, read all of the spec files in `spec/` (see `spec/README.md`
  for the index and reading order). The spec pages are interconnected, so partial context
  risks contradicting or duplicating existing decisions.
- Err on the side of brevity in spec pages. If more detail is needed, the user will ask for it.
- Update this file as we go. If the user gives a nudge or piece of guidance that reflects a
  general principle (not a one-off), suggest the AGENTS.md update and ask before adding it.
  Never update this file automatically/silently.
