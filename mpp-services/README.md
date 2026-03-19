# MPP Services

MPP-gated judge service for the Agent Escrow hackathon demo.

- `judge-service`: Claude AI evaluation endpoint with on-chain auto-settlement

Uses `mppx/express` with Tempo mainnet mode by default.

## Prerequisites
- Node.js 20+
- Anthropic API key (optional — falls back to heuristic judging)

## Setup

```bash
cd judge-service
cp .env.example .env    # fill in MPP_RECIPIENT, ANTHROPIC_API_KEY, JUDGE_PRIVATE_KEY, ESCROW_ADDRESS
npm install
npm start
```

Required `.env` values:
- `MPP_SECRET_KEY` — secret for challenge signing (`openssl rand -hex 32`)
- `MPP_RECIPIENT` — wallet address that receives MPP payments
- `MPP_CURRENCY` — TIP-20 token address used for payment
- `MPP_USE_TESTNET=false`

## Judge Routes

- `GET /health`
- `POST /judge/evaluate` (MPP-gated)
- `POST /judge/evaluate-test` (dev only, disabled in production)

## Example paid request

```bash
tempo wallet login --network tempo

tempo request --network tempo http://localhost:4102/judge/evaluate \
  -X POST \
  -H "content-type: application/json" \
  -d '{"taskId":"1","workRef":"ipfs://QmYourOutput","rubric":"Verify deliverable is complete"}'
```

## Deploy (Docker)

```bash
docker compose up --build
```

## Linking to on-chain escrow

- Judge service `approve` maps to `resolveTask(..., approve, memo)` in the smart contract
- Set `JUDGE_PRIVATE_KEY` and `ESCROW_ADDRESS` in `.env` for auto-settlement
