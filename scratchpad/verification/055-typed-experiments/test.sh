#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
{
echo "tsc version: $(tsc -v)"
for f in ok bad-model bad-prompt bad-name; do
  echo "--- src/$f.ts"
  tsc --noEmit --strict --target es2022 --moduleResolution bundler --module esnext src/parameter-names.d.ts src/declare.ts src/$f.ts && echo "OK: no type errors"
done
} > output.txt 2>&1
cat output.txt
