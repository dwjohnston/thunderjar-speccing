#!/usr/bin/env bash
# Demonstrates the claims in spec/022-coding-conventions.md using tsc and git.
set -u
cd "$(dirname "$0")"
W=$(mktemp -d)
{
echo "tsc version: $(tsc -v)"
cat > "$W/lib.ts" <<'TS'
export interface Ctx { initialPrompt: string; resultPath: string }
export interface Harness { version: string; cli: (ctx: Ctx) => string; collectTokenCosts: (raw: string) => number }
export const declareHarness = (h: Harness): Harness => h;
TS
cat > "$W/good.ts" <<'TS'
import { declareHarness } from "./lib";
export default declareHarness({
  version: "2.1.283",
  cli: (ctx) => `claude -p "${ctx.initialPrompt}" > ${ctx.resultPath}`,   // ctx inferred
  collectTokenCosts: (raw) => raw.length,                                  // raw inferred
});
TS
cat > "$W/bare.ts" <<'TS'
// bare object: ctx has no type (implicit any)
export default { version: "2.1.283", cli: (ctx) => `claude ${ctx.initialPrompt}` };
TS
cat > "$W/as.ts" <<'TS'
import type { Harness, Ctx } from "./lib";
// 'as' silences the missing required field collectTokenCosts
export default { version: "2.1.283", cli: (ctx: Ctx) => "x" } as Harness;
TS
cat > "$W/satisfies.ts" <<'TS'
import type { Harness } from "./lib";
export default { version: 2, cli: () => "x", collectTokenCosts: () => 0 } satisfies Harness;
TS
cat > "$W/forgot.ts" <<'TS'
// forgetting satisfies/annotation: wrong shape compiles fine
export default { version: 2, cli: () => "x" };
TS
cat > "$W/wrongcall.ts" <<'TS'
import { declareHarness } from "./lib";
export default declareHarness({ version: 2, cli: () => "x", collectTokenCosts: () => 0 });
TS
cd "$W"
for f in good bare as satisfies forgot wrongcall; do
  echo; echo "=== $f.ts ==="; cat $f.ts | sed 's/^/  | /'
  tsc --noEmit --strict --target es2022 --module esnext --moduleResolution bundler $f.ts && echo "  -> compiles cleanly"
done
cd - >/dev/null
echo; echo "=== git ignore of _generated/ ==="
G=$(mktemp -d); cd "$G"; git init -q
mkdir -p thunderjar/_generated; touch thunderjar/_generated/parameter-names.d.ts
printf 'thunderjar/_generated/\n' > .gitignore
git check-ignore -v thunderjar/_generated/parameter-names.d.ts
git status --short
} 2>&1 | sed "s#$W#<tmp>#g" | tee output.txt
