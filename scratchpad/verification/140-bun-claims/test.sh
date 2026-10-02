#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
W=$(mktemp -d)
cat > "$W/index.ts" <<'TS'
import { Database } from "bun:sqlite";
export interface Foo { a: number }
export function declareX(): Foo { return { a: 1 }; }
const db = new Database(":memory:");
db.run("create table t(x)");
db.run("insert into t values (42)");
console.log("sqlite:", JSON.stringify(db.query("select x from t").all()));
const h = (o: object) => new Bun.CryptoHasher("sha256").update(JSON.stringify(o)).digest("hex");
console.log("sha256 key-order-sensitive:", h({a:1,b:2}) === h({b:2,a:1}) ? "equal" : "differs");
const p = Bun.spawn(["git", "--version"], { stdout: "pipe" });
console.log("spawn:", (await new Response(p.stdout).text()).trim());
TS
echo "bun $(bun --version)"
echo "--- run ts directly (no build step)"; bun run "$W/index.ts"
echo "--- bun build"; bun build "$W/index.ts" --outdir "$W/dist" --target bun 2>&1 | sed "s#$W#TMP#g"; ls "$W/dist"
echo "--- any .d.ts emitted by bun build?"; ls "$W/dist" | grep -c '\.d\.ts' 
echo "--- type errors: bun run does not check"
echo 'const n: number = "str"; console.log("ran despite type error");' > "$W/bad.ts"; bun run "$W/bad.ts"
rm -rf "$W"
