#!/usr/bin/env bash
# No Docker daemon in sandbox, so check tags against the distribution reference grammar:
# tag := [\w][\w.-]{0,127}  (also what `docker tag` enforces)
set -u
cd "$(dirname "$0")"
{
re='^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$'
ULID=01K4X9J2E8MQZ3ABCDEFGHJKMN
echo "full ULID length: ${#ULID}"
echo "spec example execution ID '01k4x9j2e8mqz3' length: 14"
for t in prerun-h4f9a21c8 postrun-e01k4x9j2e8mqz3-h4f9a21c8-i00 "postrun-e${ULID}-h4f9a21c8-i00"; do
  if [[ $t =~ $re ]]; then echo "valid (${#t} chars, max 128): $t"; else echo "invalid: $t"; fi
done
} 2>&1 | tee output.txt
