#!/usr/bin/env bash
# Demo: a package with bun as exact dependency + `#!/usr/bin/env bun` bin; run via package manager
# with no global bun on PATH, loading a .ts config directly.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
W="$(mktemp -d)"
exec > >(tee "$HERE/output.txt") 2>&1
export PATH="/opt/node22/bin:/usr/bin:/bin"
echo "global bun on PATH: $(command -v bun || echo none)"
BUNV=$(npm view bun version)
echo "pinning bun exactly to $BUNV"
mkdir -p "$W/pkg" "$W/user" && cd "$W/pkg"
cat > package.json <<J
{"name":"thunderjar","version":"0.0.0","bin":{"thunderjar":"./cli.js"},"exports":{".":"./index.js"},"dependencies":{"bun":"$BUNV"}}
J
printf 'export const declareConfig = (c) => c;\n' > index.js
cat > cli.js <<'J'
#!/usr/bin/env bun
const cfg = (await import(process.cwd() + "/thunderjar.config.ts")).default;
console.log("runtime:", typeof Bun !== "undefined" ? "bun " + Bun.version : "not bun", "| config:", JSON.stringify(cfg));
J
chmod +x cli.js
npm pack --silent >/dev/null 2>&1; TGZ=$(ls *.tgz)
cd "$W/user" && npm init -y >/dev/null && npm install --silent "$W/pkg/$TGZ" 2>&1 | tail -3
cat > thunderjar.config.ts <<'J'
import { declareConfig } from "thunderjar";
interface C { name: string }
export default declareConfig({ name: "demo" } as C);
J
echo "--- node_modules/.bin:"; ls node_modules/.bin
echo "--- bun version in .bin:"; node_modules/.bin/bun --version
echo "--- npx thunderjar (no global bun):"; npx --no-install thunderjar
echo "--- npm run script:"; npm pkg set scripts.tj=thunderjar >/dev/null; npm run -s tj
echo "--- direct ./node_modules/.bin/thunderjar with .bin NOT on PATH:"; node_modules/.bin/thunderjar 2>&1 | head -2  # expected to fail: no bun on PATH
rm -rf "$W"
