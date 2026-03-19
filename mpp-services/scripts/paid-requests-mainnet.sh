#!/usr/bin/env bash
set -euo pipefail

if ! command -v tempo >/dev/null 2>&1; then
  echo "tempo CLI not found. Install and load env first."
  exit 1
fi

NETWORK="${TEMPO_NETWORK:-tempo}"
WORKER_URL="${WORKER_URL:-http://localhost:4101}"
JUDGE_URL="${JUDGE_URL:-http://localhost:4102}"

echo "Using network: $NETWORK"
echo "Worker: $WORKER_URL"
echo "Judge:  $JUDGE_URL"
echo "Tip: run 'tempo wallet login --network $NETWORK' first if needed."

tempo request --network "$NETWORK" "${WORKER_URL%/}/work/submit" \
  -X POST \
  -H "content-type: application/json" \
  -d '{"taskId":"1","requesterAddress":"0x0000000000000000000000000000000000000000","artifactUrl":"https://example.com/output","summary":"first pass"}'

tempo request --network "$NETWORK" "${JUDGE_URL%/}/judge/evaluate" \
  -X POST \
  -H "content-type: application/json" \
  -d '{"taskId":"1","workRef":"ipfs://mock-good-output","rubric":"correctness"}'

