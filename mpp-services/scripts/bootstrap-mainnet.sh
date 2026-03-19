#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKER_DIR="$ROOT_DIR/worker-service"
JUDGE_DIR="$ROOT_DIR/judge-service"

WORKER_ENV="$WORKER_DIR/.env"
JUDGE_ENV="$JUDGE_DIR/.env"

if [[ ! -f "$WORKER_ENV" ]]; then
  cp "$WORKER_DIR/.env.example" "$WORKER_ENV"
fi

if [[ ! -f "$JUDGE_ENV" ]]; then
  cp "$JUDGE_DIR/.env.example" "$JUDGE_ENV"
fi

if [[ -z "${MPP_SECRET_KEY:-}" ]]; then
  MPP_SECRET_KEY="$(openssl rand -hex 32)"
fi

set_kv() {
  local file="$1"
  local key="$2"
  local value="$3"
  if grep -q "^${key}=" "$file"; then
    perl -0777 -i -pe "s/^${key}=.*$/${key}=${value}/mg" "$file"
  else
    printf "%s=%s\n" "$key" "$value" >>"$file"
  fi
}

DEFAULT_CURRENCY="0x20c000000000000000000000b9537d11c60e8b50"
ZERO_ADDR="0x0000000000000000000000000000000000000000"
RECIPIENT="${MPP_RECIPIENT:-$ZERO_ADDR}"
CURRENCY="${MPP_CURRENCY:-$DEFAULT_CURRENCY}"

set_kv "$WORKER_ENV" "MPP_SECRET_KEY" "$MPP_SECRET_KEY"
set_kv "$WORKER_ENV" "MPP_USE_TESTNET" "false"
set_kv "$WORKER_ENV" "MPP_RECIPIENT" "$RECIPIENT"
set_kv "$WORKER_ENV" "MPP_CURRENCY" "$CURRENCY"

set_kv "$JUDGE_ENV" "MPP_SECRET_KEY" "$MPP_SECRET_KEY"
set_kv "$JUDGE_ENV" "MPP_USE_TESTNET" "false"
set_kv "$JUDGE_ENV" "MPP_RECIPIENT" "$RECIPIENT"
set_kv "$JUDGE_ENV" "MPP_CURRENCY" "$CURRENCY"

echo "Mainnet bootstrap complete."
echo "Updated:"
echo "  - $WORKER_ENV"
echo "  - $JUDGE_ENV"
echo ""
if [[ "$RECIPIENT" == "$ZERO_ADDR" ]]; then
  echo "⚠ Set MPP_RECIPIENT in both .env files (or re-run: MPP_RECIPIENT=0xYourWallet ./scripts/bootstrap-mainnet.sh)"
  echo "  Services require a non-zero payout address to start."
fi
echo "Next:"
echo "  1) Set MPP_RECIPIENT if still placeholder"
echo "  2) Add ANTHROPIC_API_KEY to $JUDGE_ENV (optional, fallback judge works without it)"
echo "  3) Start worker service: cd \"$WORKER_DIR\" && npm run dev"
echo "  4) Start judge service:  cd \"$JUDGE_DIR\" && npm run dev"

