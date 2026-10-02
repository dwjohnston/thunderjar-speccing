#!/usr/bin/env bash
# Demonstrates: a commit SHA from `git rev-parse main` pins exactly one tree,
# and `git checkout <sha>` reproduces it even after main moves.
set -u
cd "$(mktemp -d)"
git init -q -b main . && git config user.name t && git config user.email t@example.com
echo one > f.txt && git add f.txt && git commit -qm one
sha=$(git rev-parse main)
echo "rev-parse main -> $sha"
echo "tree of that commit -> $(git rev-parse "$sha^{tree}")"
echo two > f.txt && git commit -qam two
echo "main moved -> $(git rev-parse main)"
git checkout -q "$sha"
echo "after checkout, f.txt = $(cat f.txt); tree = $(git rev-parse HEAD^{tree})"
