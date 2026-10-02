#!/usr/bin/env bash
# Checks that prefixed tags in one repository are valid per the distribution reference grammar:
# tag := [\w][\w.-]{0,127}
set -u
cd "$(dirname "$0")"
{
re='^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$'
for t in prerun-3f9a2c postrun-3f9a2c-run1 prerun- "-bad" "has space" "prerun:x"; do
  if [[ $t =~ $re ]]; then echo "valid:   '$t'"; else echo "invalid: '$t'"; fi
done
echo "single repo example refs: registry.example.com/thunderjar/images:prerun-3f9a2c and :postrun-3f9a2c-run1"
} 2>&1 | tee output.txt
