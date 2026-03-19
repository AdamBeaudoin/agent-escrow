#!/usr/bin/env bash
set -euo pipefail

JUDGE_URL="${JUDGE_URL:-http://localhost:4102/health}"

echo "Checking judge health: $JUDGE_URL"
curl -s "$JUDGE_URL"
echo ""
