#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
W=$(mktemp -d); export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
export GIT_AUTHOR_NAME=agent GIT_AUTHOR_EMAIL=a@x GIT_COMMITTER_NAME=agent GIT_COMMITTER_EMAIL=a@x
git --version
git init -q -b main $W/dev && cd $W/dev && echo base>f && git add f && git commit -qm base
git clone -q $W/dev $W/image && cd $W/image
echo agent>g && git add g && git commit -qm "agent commit"
echo "modified" >> f; echo untracked > u.txt   # uncommitted end state
cd $W/dev; echo "dev wip" > wip.txt; echo "dev edit" >> f
echo "--- dev status before"; git status --short
echo "--- restore: fetch into branch (image repo, HEAD)"
git fetch -q $W/image HEAD:thunderjar/container-run-123 && echo fetch ok
echo "--- Thunderjar commit built in image copy w/ temp index (image untouched)"
cd $W/image; export GIT_INDEX_FILE=$W/tmpidx; git read-tree HEAD; git add -A
T=$(git write-tree); unset GIT_INDEX_FILE
C=$(GIT_AUTHOR_NAME=Thunderjar GIT_COMMITTER_NAME=Thunderjar git commit-tree $T -p HEAD -m "thunderjar: uncommitted changes at end of container-run-123")
echo "image status unchanged:"; git status --short
cd $W/dev; git fetch -q $W/image $C:refs/thunderjar-tmp 2>&1 | head -2
git update-ref -d refs/thunderjar-tmp 2>/dev/null
git fetch -q $W/image HEAD && echo "(commit object $C not reachable by ref; need ref)" 
cd $W/image && git update-ref refs/thunderjar/restore $C
cd $W/dev && git fetch -q --force $W/image refs/thunderjar/restore:thunderjar/container-run-123
echo "--- dev after"; git branch --show-current; git status --short
git log --format='%an | %s' thunderjar/container-run-123
git show --stat --format= thunderjar/container-run-123
echo "--- second restore, same branch name, no force"
git fetch $W/image HEAD:thunderjar/container-run-123 2>&1 | sed "s#$W#<tmp>#g"; echo "exit=${PIPESTATUS[0]}"
echo "--- outside a repo"
cd $W && git rev-parse --git-dir 2>&1 | sed "s#$W#<tmp>#g"; echo "exit=${PIPESTATUS[0]}"
