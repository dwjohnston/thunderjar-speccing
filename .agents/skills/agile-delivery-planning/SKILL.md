---
name: agile-delivery-planning
description: Plan and maintain Thunderjar's incremental delivery, in the delivery/ folder. Use when the user asks to plan, reorder, add or detail delivery stories, to break an area of the spec into buildable work, or to work out what to build next.
---

# Agile Delivery Planning

The spec (`spec/`) is the product requirements document: the upfront investigation, done
so we don't code first and discover mistakes far down the path. Planning delivery means
turning it into a sequence of small stories that build a working application.

## Principles

- **The spec is a guide, not stone.** Delivery will surface mistakes in it. When a story
  contradicts or outgrows the spec, say so and propose the spec change. Follow the spec
  conventions in `AGENTS.md`, and ask before changing a decision other pages reference.
- **Every story leaves a fully running application.** Never plan a story that only makes
  sense once a later one lands. Scaffolding, stubs and fakes are fine; a broken or
  half-wired app is not.
- **Start with the thinnest possible app.** Story 1 is the published npm package, the
  documentation page and the CI pipeline, doing nothing but printing "hello world!".
- **Defer the expensive parts.** Prefer fakes (e.g. a shell command standing in for an
  agent) so downstream behaviour can be built and tested early. Real agents and Docker
  come late.
- **Respect v1 scope.** Don't plan stories for non-goals in `spec/020-goals-non-goals.md`.

## Files in `delivery/`

| File | Purpose |
|---|---|
| `0000_high-level-groupings.md` | Concept map: the six areas (A–F) and the spec pages for each. |
| `0100_agile-delivery-stories.md` | The ordered story list, in phases. The source of truth for order. |
| `1XXX_<story>.md` | One file per story in phase 1: `1100`, `1200`, `1300`… |
| `2XXX_<story>.md` | One file per story in phase 2, and so on for each phase. |

- **The first digit is the phase.** `1XXX` files are phase 1 stories, `2XXX` phase 2,
  and each phase has many stories. `0XXX` files are overview material, not stories.
- **Files are written for a human reader**, high-level enough to give a clear picture of
  what is happening without reading the spec. Be concise; the user will ask for detail.
- **The phases and their order are defined in `0100`.** When a story is added, merged,
  removed or moved between phases, rename its file and fix every reference.
- **Note which area(s)** (A–F in `0000`) each story touches.

## Writing a story

- A short bold name, then one or two sentences on what the user can do or see afterwards.
- Phrase it as observable behaviour (a command, its output), not as an internal task.
- Keep it small enough that the app is demonstrably running at the end.

## Working style

- Read `delivery/` and the spec pages relevant to the area before changing anything.
- Brainstorm in chat first; write to files once the user agrees.
- Do not expand story detail unprompted. Brevity is easier to correct than bulk.

## Format

A story file has a title, a one-or-two sentence summary, and two key sections:
**Artifacts** and **How to test**.

```markdown
# <NNNN>: <Story name>

<One or two sentences: what the user can do or see once this story is done.>

Areas: <A–F letters from 0000>

## Artifacts

<What exists after this story that didn't before. Concrete and checkable: published
packages, commands, files and folders, pages, pipelines.>

## How to test

<The testing strategy for this unit test? is docker involved? manual?>

<command that will be invoked to run test>

## Human interventins

<Any tasks that the human is required >
```

- **Artifacts** are things you can point at:
  - "`thunderjar` is on npm"
  - "CI pipelines exists" 
  - "`thunderjar init` command exists" 
- **How to test** 
  - Should be possible for both humans and agents to easily verify. 
    - eg. 👍 simple scripts to run in `package.json` 
    - 👎 convoluted command line 
  - **Mark human work with 👷‍♂️.** Some tasks humans will need to do. eg. supplying a secret, click ops work, visual verification. Denote these tasks with the 👷‍♂️.  

### Example task: human-verified

Needs setup and checking by hand, so the 👷‍♂️ tasks are marked.

```markdown
# 1100: Hello world

`npx thunderjar` prints "hello world!", and the package, docs page and CI pipeline exist.

Areas: F

## Artifacts

- `thunderjar` package published to npm
- Documentation page, live at a public URL
- CI pipeline that tests and publishes on merge

## How to test

Verified by a human.

1. 👷‍♂️ Run `npx thunderjar`.
2. Expect the output `hello world!`.
3. 👷‍♂️ Open the documentation page and expect it to load.
4. 👷‍♂️ Merge a trivial change and expect CI to pass.

## Human interventions

- 👷‍♂️ Create the npm account (or org) and publish token, and add the token as a CI secret.
- 👷‍♂️ Choose a docs host, and configure it in its web console (site, domain, deploy
  from the repo).
- 👷‍♂️ Verify the docs page by eye.
```

### Example: agent-verified

The agent runs the check itself, so there are no 👷‍♂️ tasks.

```markdown
# 1500: Permutations

`thunderjar plan` expands an experiment's matrix and prints each permutation.

Areas: A

## Artifacts

- `thunderjar plan` 

## How to test

Regular unit test calls the `thunderjar plan` and asserts on std out. 

- `bun test` 

## Human interventions

None.

```

