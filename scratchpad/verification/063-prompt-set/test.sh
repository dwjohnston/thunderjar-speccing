#!/usr/bin/env bash
# Demonstrates `git checkout <commit> -- <path> && cp` from the spec's applyParameter fragment.
set -u
cd "$(mktemp -d)"
git init -q . && git config user.email t@example.invalid && git config user.name t
mkdir prompts && echo "v1 prompt" > prompts/snerk.md
git add . && git commit -qm one && C=$(git rev-parse --short HEAD)
echo "v2 prompt (drifted)" > prompts/snerk.md && git commit -qam two
echo "worktree edit (uncommitted)" > prompts/snerk.md
echo "== worktree before: $(cat prompts/snerk.md)"
git checkout "$C" -- prompts/snerk.md && cp prompts/snerk.md CLAUDE.md
echo "== CLAUDE.md after pinned checkout: $(cat CLAUDE.md)"
git status --short
