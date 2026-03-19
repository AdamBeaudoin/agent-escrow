#!/usr/bin/env bash
set -euo pipefail

if ! command -v tempo >/dev/null 2>&1; then
  echo "tempo CLI not found. Install and load env first."
  exit 1
fi

NETWORK="${TEMPO_NETWORK:-tempo}"
JUDGE_URL="${JUDGE_URL:-http://localhost:4102}"

echo "Using network: $NETWORK"
echo "Judge:  $JUDGE_URL"
echo "Tip: run 'tempo wallet login --network $NETWORK' first if needed."

tempo request --network "$NETWORK" "${JUDGE_URL%/}/judge/evaluate" \
  -X POST \
  -H "content-type: application/json" \
  -d '{"taskId":"1","workRef":"ipfs://QmYourOutput","rubric":"Verify deliverable is complete and meets quality standards"}'
