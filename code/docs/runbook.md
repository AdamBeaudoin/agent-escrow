# Agent Escrow Runbook

## 1) Install and verify tools
- `forge --version`
- `cast --version`
- `anvil --version`
- Prefer Tempo's Foundry fork (`forge -V` includes `-tempo`) for Tempo-specific flags.

## 2) Configure environment
1. Copy template:
   - `cp .env.example .env`
2. Fill values:
   - `TEMPO_RPC_URL`
   - `TEMPO_CHAIN_ID` (mainnet is `4217`)
   - `VERIFIER_URL` (`https://contracts.tempo.xyz`)
   - `DEPLOYER_PRIVATE_KEY`
   - `REQUESTER_PRIVATE_KEY`
   - `WORKER_PRIVATE_KEY`
   - `JUDGE_PRIVATE_KEY`
   - `REQUESTER_ADDRESS`
   - `WORKER_ADDRESS`
   - `JUDGE_ADDRESS`
   - `TIP20_STABLECOIN_ADDRESS`
   - `TASK_BOUNTY_AMOUNT`
   - `TASK_METADATA_HASH`
   - `JUDGE_REVIEW_PERIOD_SECONDS` (seconds after work submission for judge to resolve; use `0` to disable on-chain timeout reclaim)

## 3) Build and test locally
- `make build`
- `make test`

## 4) Fund mainnet wallets
- Ensure deployer/requester/worker/judge have sufficient TIP-20 balances for:
  - bounty escrow amount
  - transaction fees

## 5) Deploy to Tempo mainnet
- `source .env`
- `make deploy-mainnet`
- Optional verified deploy:
  - `make deploy-mainnet-verify`
- Copy the deployed address into:
  - `ESCROW_ADDRESS=<deployed_contract_address>`

## 6) Run live demo flow (manual judge model)
- Step 1 (requester creates task + escrow funding):
  - `make demo-step1`
- Step 2 (worker accepts task):
  - `TASK_ID=1 make demo-step2`
- Step 3 (worker submits output):
  - `TASK_ID=1 WORK_REF=ipfs://QmYourResult make demo-step3`
- Step 4 (judge resolves payout):
  - `TASK_ID=1 APPROVE=true RESOLUTION_MEMO="accepted" make demo-step4`
- Refund path (second scenario):
  - `TASK_ID=2 APPROVE=false RESOLUTION_MEMO="rejected" make demo-step4`
- Judge inactive / timeout (requester reclaim — task must have been created with `JUDGE_REVIEW_PERIOD_SECONDS > 0`):
  - After `submitWork`, wait until `submittedAt + JUDGE_REVIEW_PERIOD_SECONDS` on-chain
  - `TASK_ID=1 make demo-step5`

## 7) Tempo-specific checklist
- Use TIP-20 balances (`cast erc20 balance`) for UX checks, not native token balance.
- For non-TIP-20 contract calls, account needs a valid fee token balance unless using Tempo Transactions.
- If using Tempo fork, you can explicitly set fee token with `--tempo.fee-token <TOKEN_ADDRESS>`.

## 8) Demo checklist
- Pre-fund requester wallet with mainnet TIP-20 stablecoin.
- Confirm worker and judge addresses are correct.
- Capture balances before and after resolve.
- Run two scenarios: happy path payout and reject/refund.
