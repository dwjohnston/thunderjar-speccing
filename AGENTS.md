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

## Current phase

We're actively defining out the project — filling in stub spec pages from the design
conversation — while also deliberately constraining what's in scope for v1. When
something comes up that's a reasonable idea but not needed for v1, prefer flagging it
as a non-goal over speccing it out in detail. See
[`spec/02-goals-non-goals.md`](spec/02-goals-non-goals.md).

## Spec conventions

- The spec is a work in progress. Nothing written down in `spec/` should be treated as
  canonical or final — it reflects current thinking, not a locked decision.
- A paragraph starting with 🙋‍♂️ is a note from the user *about* the documentation itself
  (a comment, correction, or question on what's written), not part of the spec's actual
  content. Don't fold it into surrounding prose as if it were a spec statement.
- Whenever something is identified as out of scope, record it in
  `spec/02-goals-non-goals.md` (a non-goal), not just in the page where it came up.
- `spec/02-goals-non-goals.md` also has a "To revisit" section, for a different thing:
  unresolved questions we **are** intending to address in v1, just not yet settled — as
  opposed to non-goals, which are explicitly deferred past v1. Don't conflate the two;
  file each in its own section, cross-linked with the page where the question came up.
- Whenever a page defines a format or syntax (a tag scheme, a config shape, a naming
  convention, etc.), always follow the abstract `<placeholder>` definition with a
  concrete example block showing real, filled-in values. Never leave a format defined
  only in the abstract.
- Backlinks: whenever a page states or relies on a decision that's actually owned by
  another page (not just a `03-terminology.md` glossary entry — any decision on any
  page), link to that source page, and add a `_(Referenced by: <this page>.)_` note at
  the exact point in the source page where the decision is stated. Before changing a
  decision that has "Referenced by" notes, check and update each listed page too. Notes
  can still go stale, so also grep the spec for the concept as a fallback when in doubt.

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
