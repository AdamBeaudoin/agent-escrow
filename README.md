# Agent Escrow

Three-party escrow for AI agent tasks on **Tempo Mainnet**. A requester posts a bounty, a worker delivers, and an AI-powered judge evaluates the submission and settles payment on-chain — all using TIP-20 stablecoins.

**Deployed on Tempo Mainnet:** [`0xC76dECE5078f6a1E611e2404c6b21306a15240d8`](https://explore.tempo.xyz/address/0xC76dECE5078f6a1E611e2404c6b21306a15240d8)

## How It Works

```
Requester                    Worker                      Judge (Claude AI)
    │                           │                              │
    ├─ createTask(bounty) ──►   │                              │
    │   (USDC locked in escrow) │                              │
    │                           ├─ acceptTask() ──►            │
    │                           ├─ submitWork(ref) ──►         │
    │                           │                    ◄── evaluate(workRef)
    │                           │                              ├─ resolveTask(approve/reject)
    │   ◄── bounty paid to worker (if approved)                │
    │   ◄── bounty refunded (if rejected)                      │
```

If the judge is inactive, the requester can reclaim the bounty after a configurable timeout via `claimJudgeTimeout`.

## Project Structure

| Directory | Description |
|-----------|-------------|
| `code/` | Solidity smart contract (Foundry), deploy scripts, tests |
| `mpp-services/judge-service/` | Node.js judge API — Claude AI evaluation + on-chain auto-settlement |
| `docs/` | Task schema, judging rubric, guides |

## Quick Start

### 1. Smart Contract

```bash
cd code
cp .env.example .env    # fill in private keys and addresses
forge build
forge test
```

Deploy to Tempo Mainnet (requires [Tempo Foundry fork](https://docs.tempo.xyz)):

```bash
make deploy-mainnet
```

### 2. Judge Service

```bash
cd mpp-services/judge-service
cp .env.example .env    # fill in ANTHROPIC_API_KEY, JUDGE_PRIVATE_KEY, ESCROW_ADDRESS
npm install
npm start
```

### 3. Run the Demo Flow

```bash
cd code
make demo-step1   # Requester creates task with bounty
make demo-step2   # Worker accepts
make demo-step3   # Worker submits work
# Then call the judge service API, which evaluates via Claude and auto-settles on-chain
```

## Contract States

`Created` → `Accepted` → `Submitted` → `ResolvedPaid` | `ResolvedRefunded` | `TimedOut` | `Cancelled`

## Tech Stack

- **Smart Contract:** Solidity 0.8.24, Foundry, TIP-20 (USDC.e on Tempo)
- **Judge Service:** Node.js, Express, Anthropic Claude API
- **Chain:** Tempo Mainnet (chain ID 4217) — gas paid in stablecoins via `--tempo.fee-token`

## Environment Setup

All secrets go in `.env` files (gitignored). See `.env.example` in each directory for the template. Never commit real private keys or API keys.

## License

MIT
