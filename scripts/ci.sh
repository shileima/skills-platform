#!/usr/bin/env bash
# CI: validate every skill, then run the unit tests.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== skilldev validate =="
node bin/skilldev.mjs validate

echo
echo "== node --test tests/ =="
node --test "tests/"*.test.mjs

echo
echo "CI OK"
