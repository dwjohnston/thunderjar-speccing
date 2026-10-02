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

**Do not read `docs/conversation/`, `docs/conversation_json.md` or
`docs/conversation_raw.json` directly.** They are long and slow to read. Instead,
invoke the `query-conversation` skill with the question you need answered. Only read
the source files yourself when the skill's answer cites a location and you need to
verify the exact original wording.

## Current phase

We're actively defining out the project — filling in stub spec pages from the design
conversation — while also deliberately constraining what's in scope for v1. When
something comes up that's a reasonable idea but not needed for v1, prefer flagging it
as a non-goal over speccing it out in detail. See
[`spec/020-goals-non-goals.md`](spec/020-goals-non-goals.md).

## Spec conventions

- The spec is a work in progress. Nothing written down in `spec/` should be treated as
  canonical or final — it reflects current thinking, not a locked decision.
- A paragraph starting with 🙋‍♂️ is a note from the user *about* the documentation itself
  (a comment, correction, or question on what's written), not part of the spec's actual
  content. Don't fold it into surrounding prose as if it were a spec statement.
- Whenever something is identified as out of scope, record it in
  `spec/020-goals-non-goals.md` (a non-goal), not just in the page where it came up.
- `spec/020-goals-non-goals.md` also has a "To revisit" section, for a different thing:
  unresolved questions we **are** intending to address in v1, just not yet settled — as
  opposed to non-goals, which are explicitly deferred past v1. Don't conflate the two;
  file each in its own section, cross-linked with the page where the question came up.
- `spec/021-human-zone-out.md` records a third, different thing: places the user has
  flagged that they stopped paying close attention. Unlike the two sections above, an
  entry says nothing about whether the content is resolved — it may be entirely correct.
  It says the content was never really reviewed, so it carries less authority than the
  prose around it and must not be cited as a settled decision. When a later task depends
  on something listed there, say so and get it confirmed rather than building on it
  silently. Add an entry whenever the user says they've zoned out, lost track, or waved
  something through; name the page and section, and be specific about which parts were
  agent-proposed rather than user-decided. You may *offer* to add one when a decision was
  largely yours and passed without pushback, but ask first — this is the user's flag to
  raise, not a self-assessment you file on their behalf. Remove an entry once they've
  reviewed it properly, whether or not the content changed.
- **Describe v1 as it is.** Everything in a page's main body must be true of v1. Don't
  describe a fuller design and then walk parts of it back ("three tiers — but the third
  isn't populated"). If something is deferred, leave it out of the main description and
  mention it once, in a short "Future" note at the end of the section, linking to its
  non-goal in `020-goals-non-goals.md`.
- **Don't write the spec as a diff.** The reader hasn't seen earlier versions of the page
  or the conversation behind it. Avoid framing like "extends X to…", "not A but B",
  "now", "no longer", "moved from". State what the design is, not how it got there.
- Before finishing a page, check every count, list and table: is each item real in v1?
  If not, take it out of the list.
- When a page lists options that are still undecided, give each one a short name (e.g.
  *instrument-owned*, *measurement-chosen*) and use it in the option's heading. Refer to
  options by name, in the spec and in conversation, never by list position: positions
  shift when an option is added or ruled out, and names don't. Ruled-out options keep
  their names, listed under a "Ruled out" heading, rather than being deleted.
- Whenever a page defines a format or syntax (a tag scheme, a config shape, a naming
  convention, etc.), always follow the abstract `<placeholder>` definition with a
  concrete example block showing real, filled-in values. Never leave a format defined
  only in the abstract.
- Whenever a CLI usage line contains `<angle>` syntax, an example block with real,
  filled-in values follows it immediately, before any prose. This applies to every
  command in `spec/100-cli-reference.md`.
- Backlinks: whenever a page states or relies on a decision that's actually owned by
  another page (not just a `030-terminology.md` glossary entry — any decision on any
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
  `030-terminology.raw.md` for `030-terminology.md`). Do not read these unless the user
  specifically points you at one.

## Working style

- Before starting any task, read all of the spec files in `spec/` (see `spec/README.md`
  for the index and reading order). The spec pages are interconnected, so partial context
  risks contradicting or duplicating existing decisions.
- Err on the side of brevity in spec pages. If more detail is needed, the user will ask for it.
- Update this file as we go. If the user gives a nudge or piece of guidance that reflects a
  general principle (not a one-off), suggest the AGENTS.md update and ask before adding it.
  Never update this file automatically/silently.


☝️ **Remember:** Err on the side of brevity. It is much easier for the human reader to read something and recognise that something is missing, and ask for more, than it is for a human to read and parse something and make the determination that the thing is not needed.