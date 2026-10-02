#!/usr/bin/env bash
# Checks that the base image tag used in the spec example exists on Docker Hub.
set -u
cd "$(dirname "$0")"
{
  echo "== node:20-bookworm on Docker Hub =="
  curl -sS https://hub.docker.com/v2/repositories/library/node/tags/20-bookworm \
    | python3 -c 'import sys,json; d=json.load(sys.stdin); print("name:",d["name"]); print("last_updated:",d["last_updated"]); print("platforms:",sorted({i["os"]+"/"+i["architecture"] for i in d["images"]}))'
} 2>&1 | tee output.txt
