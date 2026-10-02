#!/usr/bin/env bash
# Shows a template-literal type over unions yields the valid pair strings,
# and that an invalid pair is a type error.
set -u
cd "$(dirname "$0")"
D=$(mktemp -d)
cat > "$D/pairs.ts" <<'TS'
type Versions = "2.1.283" | "2.2.0";
type Models = "haiku-4-5" | "sonnet-4-5";
type ClaudeCode = `claude-code@${Versions}/${Models}`;
type Codex = `codex@0.9.0/gpt-luna`;
type Pair = ClaudeCode | Codex;
const ok: Pair[] = ["claude-code@2.1.283/haiku-4-5", "codex@0.9.0/gpt-luna"];
const bad: Pair = "claude-code@2.2.0/gpt-5";
TS
echo "tsc version: $(tsc -v)"
echo "--- expect exactly one error (the claude-code/gpt-5 line) ---"
tsc --noEmit --strict "$D/pairs.ts" 2>&1 | sed "s#$D/##"
echo "tsc exit: ${PIPESTATUS[0]}"
rm -rf "$D"
