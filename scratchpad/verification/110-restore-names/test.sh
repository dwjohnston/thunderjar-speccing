#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
N='postrun-e01K4X9J2E8MQZ3V7R5T0WABCDE-h4f9a21c8-i03'
{
echo "## git: is thunderjar/<name> a valid branch name?"
git check-ref-format --branch "thunderjar/$N" && echo "valid"
echo "## docker reference grammar (distribution/reference): path-component := [a-z0-9]+ (separator [a-z0-9]+)*"
for n in "$N" "$(echo "$N" | tr A-Z a-z)"; do
  if echo "$n" | grep -Eq '^[a-z0-9]+([._-]+[a-z0-9]+|__[a-z0-9]+)*$'; then echo "valid image name:   $n"; else echo "INVALID image name: $n"; fi
done
} > output.txt 2>&1
