#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
{
echo "# claude --version: $(claude --version 2>&1)"
echo "# payload.json = real output of: claude -p hi --output-format json (session_id/uuid redacted)"
echo "## top-level keys"; jq -r 'keys|join(" ")' payload.json
echo "## flat usage keys (snake_case?)"; jq -r '.usage|keys|join(" ")' payload.json
echo "## modelUsage entry keys (camelCase?)"; jq -r '.modelUsage|to_entries[0].value|keys|join(" ")' payload.json
echo "## cost/duration/basis"; jq -c '{total_cost_usd,duration_api_ms,costBasis:(.modelUsage|map(.costBasis))}' payload.json
echo "## spec's 4 buckets: flat usage vs modelUsage"
jq -c '{flat:(.usage|{input_tokens,output_tokens,cache_creation_input_tokens,cache_read_input_tokens}), perModel:(.modelUsage|to_entries[0].value|{inputTokens,outputTokens,cacheCreationInputTokens,cacheReadInputTokens})}' payload.json
} > output.txt 2>&1
cat output.txt
