#!/usr/bin/env bash
# Demonstrates that @ts-ignore silences a TypeScript type error (tsc exits 1 without it, 0 with it).
set -u
W=$(mktemp -d); cd "$W"
printf 'const n: number = "oops";\n' > bad.ts
printf '// @ts-ignore\nconst n: number = "oops";\n' > ignored.ts
npm install --silent --no-audit --no-fund typescript >/dev/null 2>&1
npx tsc --version
echo "--- without @ts-ignore"; npx tsc --noEmit bad.ts; echo "exit=$?"
echo "--- with @ts-ignore"; npx tsc --noEmit ignored.ts; echo "exit=$?"
