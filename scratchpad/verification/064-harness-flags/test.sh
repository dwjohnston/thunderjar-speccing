#!/bin/bash
# Checks CLI flags used by the harness example exist. No API calls, no daemon needed.
set -u
cd "$(dirname "$0")"
{
echo "== claude --version"; claude --version
echo "== claude --help (flags used by the example cli)"
claude --help 2>&1 | grep -E -- '(^|\s)(-p, --print|--model |--allowedTools|--output-format)' 
echo "== docker run --help: -e/--env"
docker run --help 2>&1 | grep -E -- '^\s+-e, --env'
echo "== docker COPY --from is Dockerfile syntax (no daemon to build here)"
} 2>&1 | tee output.txt
