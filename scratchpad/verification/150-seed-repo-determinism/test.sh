#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
{
git --version
mk() {
  d=$(mktemp -d); cd "$d" || exit 1
  git init -q -b main
  export GIT_AUTHOR_NAME=Seed GIT_AUTHOR_EMAIL=seed@example.invalid GIT_AUTHOR_DATE="2020-01-01T00:00:00Z"
  export GIT_COMMITTER_NAME=Seed GIT_COMMITTER_EMAIL=seed@example.invalid GIT_COMMITTER_DATE="2020-01-01T00:00:00Z"
  echo hello > a.txt; git add a.txt; git -c commit.gpgsign=false commit -q -m "seed"
  git rev-parse HEAD; cd /; rm -rf "$d"
}
echo "run 1:"; h1=$(mk); echo "$h1"
echo "run 2 (different temp dir):"; h2=$(mk); echo "$h2"
[ "$h1" = "$h2" ] && echo "IDENTICAL hashes" || echo "DIFFERENT hashes"
} > output.txt 2>&1
