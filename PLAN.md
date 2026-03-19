# Agent Escrow Execution Plan

## Objective
Ship a working Tempo escrow prototype where three parties can coordinate task payment without trusting each other.

## Architecture
- `EscrowFactory` (optional for hackathon): creates tasks and stores task IDs.
- `AgentEscrow` contract:
  - immutable stablecoin token address
  - per-task struct: requester, worker, judge, bounty, deadline, status, workRef
  - state transitions guarded by role checks
- Off-chain artifacts:
  - worker output stored externally (link, IPFS hash, or repo commit)
  - `workRef` submitted on-chain

## Contract State Machine
- `Created`: requester funds bounty and names worker + judge.
- `Accepted`: worker confirms participation.
- `Submitted`: worker posts `workRef`.
- `ResolvedPaid`: judge approves; worker receives bounty.
- `ResolvedRefunded`: judge rejects; requester refunded.
- `TimedOut`: after work is submitted, if judge does not resolve within `judgeReviewPeriod`, requester calls `claimJudgeTimeout` and reclaims bounty (`judgeReviewPeriod == 0` disables this path).

## Milestones
1. Define interface and invariants
   - Events, errors, and state transition guards.
2. Implement contract
   - Role auth, token transfer safety, timeout logic.
3. Add tests
   - Success path, unauthorized actions, dispute/refund, timeout.
4. Demo integration
   - CLI or minimal page for create/accept/submit/resolve.
5. Dry-run pitch
   - Run two scripted scenarios with timestamps and expected balances.

## Team Ownership Split
- You (Product + Demo)
  - Task schema and acceptance criteria template.
  - Demo UX flow and narration.
  - Edge-case documentation and judging script.
- Teammate (Protocol + Reliability)
  - Contract implementation and deployment.
  - Test coverage and failure-mode checks.
  - Final network deployment + contract verification.

## Definition of Done
- Deployed contract address on Tempo **mainnet** (or organizer-specified network).
- Test suite passes for all critical transitions.
- 2-minute happy path + 1-minute dispute path demo works live.
- README and quickstart are clear enough for external judges to run.
