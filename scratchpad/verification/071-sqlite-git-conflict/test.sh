#!/usr/bin/env bash
# Demonstrates: committing a SQLite file to git and writing to it from two branches
# produces a binary merge conflict that git cannot resolve.
set -u
cd "$(dirname "$0")"
(
W=$(mktemp -d); cd "$W"
git init -q -b main . && git config user.email t@example.invalid && git config user.name t
mk() { python3 - "$@" <<'PY'
import sqlite3,sys
c=sqlite3.connect("runs.db"); c.execute("create table if not exists runs(id text)")
c.execute("insert into runs values(?)",(sys.argv[1],)); c.commit(); c.close()
PY
}
mk base; git add runs.db; git commit -qm base
git checkout -q -b ci;  mk ci-run;  git commit -qam ci
git checkout -q main; git checkout -q -b dev; mk dev-run; git commit -qam dev
echo "--- git merge ci into dev"
git merge ci 2>&1; echo "exit=$?"
echo "--- git status"; git status --short
) 2>&1 | tee output.txt
