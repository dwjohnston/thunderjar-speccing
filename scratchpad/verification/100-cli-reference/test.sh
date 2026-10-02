#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
{
echo "# git version"; git --version
echo "# branch names from restore are valid refs?"
for id in postrun-e01K4X9J2E8MQZ3V7R5T0WABCDE-h4f9a21c8-i00; do
  git check-ref-format --branch "thunderjar/$id" && echo "valid: thunderjar/$id"
done
echo "# example IDs match ULID format (26 chars Crockford base32)?"
for id in 01K4X9J2E8MQZ3V7R5T0WABCDE 01K5A2B7C9D4F6G8H0JKMNPQRS; do
  echo "$id" | grep -Eq '^[0-7][0-9A-HJKMNP-TV-Z]{25}$' && echo "ULID ok: $id" || echo "ULID BAD: $id"
done
} > output.txt 2>&1
