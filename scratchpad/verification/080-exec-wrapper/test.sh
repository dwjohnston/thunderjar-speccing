#!/bin/sh
# Runs the spec's execution wrapper (080) locally with a stand-in command.
# No Docker daemon is available in this sandbox, so docker commit is not exercised.
set -u
cd "$(dirname "$0")"
{
out=$(mktemp -d)
for cmd in "sleep 1" "sh -c 'exit 3'"; do
  start=$(date +%s%3N)
  eval "$cmd"
  code=$?
  end=$(date +%s%3N)
  echo "{\"startedAt\":$start,\"finishedAt\":$end,\"exitCode\":$code}" > "$out/run.json"
  echo "cmd: $cmd"; cat "$out/run.json"
  command -v python3 >/dev/null && python3 -c "import json,sys;d=json.load(open('$out/run.json'));print('valid JSON, elapsed ms:',d['finishedAt']-d['startedAt'])"
done
rm -rf "$out"
echo "--- date %3N support (GNU coreutils):"; date --version | head -1
if command -v busybox >/dev/null; then echo "--- busybox date:"; busybox date +%s%3N; fi
} 2>&1 | tee output.txt
