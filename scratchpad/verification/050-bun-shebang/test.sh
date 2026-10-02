#!/usr/bin/env bash
# Demonstrates: npm "bun" package + "#!/usr/bin/env bun" shebang, run via npx vs directly,
# with no global Bun on PATH; and the --ignore-scripts case.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
W="$(mktemp -d)"
# PATH with any global bun directories removed
CLEAN_PATH="$(echo "$PATH" | tr ':' '\n' | while read -r d; do [ -x "$d/bun" ] || echo "$d"; done | paste -sd:)"
export PATH="$CLEAN_PATH"
{
echo "global bun on PATH? $(command -v bun || echo no)"
mkdir -p "$W/tj/bin" && cd "$W/tj"
cat > bin/tj.js <<'JS'
#!/usr/bin/env bun
console.log("hello from bun " + Bun.version);
JS
chmod +x bin/tj.js
cat > package.json <<'J'
{"name":"fake-thunderjar","version":"0.0.0","bin":{"tj":"bin/tj.js"}}
J
mkdir -p "$W/proj" && cd "$W/proj"
npm init -y >/dev/null
npm install --no-audit --no-fund --loglevel=error bun "$W/tj" 2>&1 | grep -v notice
echo "--- node_modules/.bin:"; ls node_modules/.bin
echo "--- via npx (PATH gets node_modules/.bin):"; npx --no-install tj 2>&1
echo "--- node_modules/.bin/tj directly (PATH not set up):"; ./node_modules/.bin/tj 2>&1
echo "--- npm run script:"; npm pkg set scripts.tj=tj >/dev/null; npm run -s tj 2>&1
echo "--- install with --ignore-scripts:"
mkdir -p "$W/proj2" && cd "$W/proj2" && npm init -y >/dev/null
npm install --ignore-scripts --no-audit --no-fund --loglevel=error bun "$W/tj" 2>&1 | grep -v notice
npx --no-install tj 2>&1 | head -5
} 2>&1 | tee "$HERE/output.txt"
rm -rf "$W"
