# Prompt Set

A named, reusable action that overlays prompt files (`CLAUDE.md`, skills, rules) into
the worktree before the harness runs.

One of the five test case parameters. Hashing and `applyParameter` are common to all of
them — see [060-test-case-parameters.md](060-test-case-parameters.md).

## Declaration

Lives at `test-case-parameters/promptSets/<name>/index.ts`.

```ts
// test-case-parameters/promptSets/snerk/index.ts
export default declarePromptSet({
  config: { commit: "e4f5a6" },
  applyParameter: (config, ctx) =>
    `COPY ${ctx.git.show(config.commit, "prompts/snerk.md")} /workspace/CLAUDE.md`,
});
```

| Field | What it is |
|---|---|
| `config` | Optional. Whatever the fragment needs, typically the commit the prompt files are read from. |
| `applyParameter` | Returns a Dockerfile fragment that puts the prompt files in `/workspace`. |

A prompt set that keeps its files beside its declaration copies them from `ctx.dir`
instead, with no git: `COPY ${ctx.dir}/CLAUDE.md /workspace/CLAUDE.md`.

## Prompt files come from a pinned commit

Prompt files are read from a pinned commit, not taken from whatever happens to be in the
worktree. Otherwise the declaration's parameter hash stays the same while the file it
applies changes underneath it — the silent drift the hash exists to catch.

`ctx.git.show(commit, path)` has Thunderjar read the file with `git show e4f5a6:prompts/snerk.md`
into the build context, and returns the path the fragment copies it from:

```dockerfile
COPY git/e4f5a6/prompts/snerk.md /workspace/CLAUDE.md
```

Only the files are copied, never the commit's history, so a prompt set from a later
commit than the code state doesn't show the agent anything after the code state's commit.
The commit must be in the local repository, as for a code state — see
[062-code-state.md](062-code-state.md#where-the-commit-comes-from).

The prompt files themselves stay in the normal project tree (`prompts/snerk.md` above).
The declaration points at them rather than copying them into `.thunderjar/`.

## Independent of code state

The commit is the prompt set's own, independent of the code state's. That keeps the two
axes orthogonal: a matrix can vary prompt sets while holding code state fixed, which is
the single most common test case shape.

## When it applies

Build time only. Its fragment runs after the code state's, and before the initial prompt's.
