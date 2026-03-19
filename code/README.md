# Agent Escrow (Foundry)

Trust-minimized three-party workflow:
- requester escrows TIP-20 stablecoin bounty (optional **judge review period** for timeout reclaim)
- worker accepts and submits `workRef`
- judge resolves payout (`approve=true`) or refund (`approve=false`)
- if the judge never resolves and the review window elapsed, **requester** calls `claimJudgeTimeout` (demo: `make demo-step5`)

## Contracts and scripts
- `src/AgentEscrow.sol`
- `test/AgentEscrow.t.sol`
- `script/Deploy.s.sol`
- `script/Demo.s.sol`

## Teammate setup (install these first)
- `git` (latest stable)
- `Homebrew` (macOS package manager)
- `tirith` (optional but recommended terminal guardrail)
- Tempo Foundry toolchain (`forge`, `cast`, `anvil`, `chisel`) via `foundryup -n tempo`
- `jq` (for JSON parsing)

### macOS install commands
```bash
brew update
brew install jq sheeki03/tap/tirith
curl -L https://foundry.paradigm.xyz | bash
source ~/.zshenv
foundryup -n tempo
forge -V
cast --version
anvil --version
```

`forge -V` should include `-tempo`.

## Quickstart
1. `cp .env.example .env`
2. Fill required values in `.env`
3. `source .env`
4. Ensure deployer/requester/worker/judge wallets are funded on Tempo mainnet
5. `make build`
6. `make test`

## Deploy
- `make deploy-mainnet`
- Verified deploy: `make deploy-mainnet-verify`

## Demo flow
- Create task: `make demo-step1`
- Accept task: `TASK_ID=1 make demo-step2`
- Submit work: `TASK_ID=1 WORK_REF=ipfs://QmResult make demo-step3`
- Resolve paid: `TASK_ID=1 APPROVE=true RESOLUTION_MEMO="accepted" make demo-step4`
- Resolve refund: `TASK_ID=2 APPROVE=false RESOLUTION_MEMO="rejected" make demo-step4`
- Judge timeout reclaim: `TASK_ID=1 make demo-step5` (only after review window; set `JUDGE_REVIEW_PERIOD_SECONDS` in `.env` at task creation)

## MPP integration (separate services)
- Worker MPP service: `../mpp-services/worker-service`
- Judge MPP service: `../mpp-services/judge-service`
- Setup/run guide: `../mpp-services/README.md`

See full walkthrough in `docs/runbook.md`.
