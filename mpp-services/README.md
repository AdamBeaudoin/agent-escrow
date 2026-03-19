# MPP Services (Two-Service Setup)

This folder contains two separate Node/Express services for hackathon demo alignment:

- `worker-service`: MPP-gated work submission endpoint
- `judge-service`: MPP-gated evaluation endpoint

Both use `mppx/express` with Tempo mainnet mode by default.

## Prerequisites
- Node.js 20+
- Tempo CLI installed (`tempo`)
- Mainnet-funded account for client-side requests

Use one shared `MPP_SECRET_KEY` across both services for a stable local demo:

```bash
openssl rand -hex 32
```

Or run bootstrap once (generates/syncs `MPP_SECRET_KEY`; set payout wallet explicitly if needed):

```bash
MPP_RECIPIENT=0xYourWallet ./scripts/bootstrap-mainnet.sh
```

Required MPP values in both `.env` files:
- `MPP_SECRET_KEY` - shared secret for challenge signing
- `MPP_RECIPIENT` - wallet address that receives MPP payments
- `MPP_CURRENCY` - TIP-20 token address used for payment (mainnet default in templates)
- `MPP_USE_TESTNET=false` - keep mainnet mode

## 1) Start worker service
```bash
cd worker-service
cp .env.example .env
npm install
npm run dev
```

Worker routes:
- `GET /health`
- `POST /work/submit` (MPP-gated)

## 2) Start judge service
```bash
cd ../judge-service
cp .env.example .env
npm install
npm run dev
```

For LLM-based judging, set `ANTHROPIC_API_KEY` in `judge-service/.env`.
If the key is unset or provider fails, the service auto-falls back to heuristic judging.

Judge routes:
- `GET /health`
- `POST /judge/evaluate` (MPP-gated)

## 3) Example paid requests
You can use Tempo CLI for MPP requests (mainnet):

```bash
tempo wallet login --network tempo
```

```bash
tempo request --network tempo http://localhost:4101/work/submit \
  -X POST \
  -H "content-type: application/json" \
  -d '{"taskId":"1","artifactUrl":"https://example.com/output","summary":"first pass"}'
```

```bash
tempo request --network tempo http://localhost:4102/judge/evaluate \
  -X POST \
  -H "content-type: application/json" \
  -d '{"taskId":"1","workRef":"ipfs://mock-abc","rubric":"accuracy"}'
```

## Deploy publicly (HTTPS)

1. Read **[`../docs/GO_LIVE.md`](../docs/GO_LIVE.md)**.
2. **Render:** from repo root, use **`../../render.yaml`** (workspace `Tempo Hackathon/render.yaml`) → Blueprint → set `MPP_SECRET_KEY` + `MPP_RECIPIENT` on **both** web services (same secret).
3. **Docker:** `docker compose -f docker-compose.yml up --build` (needs `.env` in each service dir), or build each `Dockerfile` on Railway/Fly.

Servers bind **`0.0.0.0`** and honor **`PORT`** (set automatically on most hosts).

After deploy:

```bash
export WORKER_URL="https://your-worker.onrender.com"
export JUDGE_URL="https://your-judge.onrender.com"
./scripts/paid-requests-mainnet.sh
```

## Convenience scripts
- `./scripts/bootstrap-mainnet.sh` - create/update both `.env` files, sync one `MPP_SECRET_KEY`, force `MPP_USE_TESTNET=false`
- `./scripts/health-check.sh` - check worker/judge health endpoints
- `./scripts/paid-requests-mainnet.sh` - run both paid request examples on `tempo` network

## Demo intent
- Use MPP payment receipts to prove machine-to-machine access payment
- Use escrow contract for final on-chain payout/refund settlement

## Linking to on-chain escrow
- Define the task off-chain per **`../docs/task-schema.md`**, compute **`metadataHash`**, and use that in `createTask`.
- Use worker **`workRef`** from `POST /work/submit` (or your IPFS hash) for `submitWork`.
- Judge service **`approve`** should match `resolveTask(..., approve, memo)` in `code/script/Demo.s.sol` step 4.

## Security note
- Never paste API keys into chat or commit them to git.
- Store keys only in local `.env` files that stay out of version control.

