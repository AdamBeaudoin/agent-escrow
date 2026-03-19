#!/usr/bin/env bash
set -euo pipefail

WORKER_URL="${WORKER_URL:-http://localhost:4101/health}"
JUDGE_URL="${JUDGE_URL:-http://localhost:4102/health}"

echo "Checking worker health: $WORKER_URL"
curl -s "$WORKER_URL"
echo ""
echo "Checking judge health: $JUDGE_URL"
curl -s "$JUDGE_URL"
echo ""

