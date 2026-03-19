# Agent Escrow Tasks

## You (Product / Demo)
- [x] Define canonical task payload (title, bounty, deadline, success criteria). → `docs/task-schema.md`
- [x] Write judge checklist for accept/reject decisions. → `docs/judge-checklist.md`
- [ ] Build demo script with exact wallet roles and sequence.
- [ ] Prepare pitch story: "trustless agent labor market on Tempo."
- [ ] Record fallback video in case live demo fails.

## Teammate (Smart Contracts / Testing)
- [x] Implement `createTask`, `acceptTask`, `submitWork`, `resolveTask`.
- [x] Add role-based access checks and custom errors.
- [x] Integrate TIP-20 stablecoin transfer handling.
- [x] Implement inactivity timeout and fallback settle function (`claimJudgeTimeout`, `JUDGE_REVIEW_PERIOD_SECONDS`).
- [x] Write integration tests for success, reject, timeout, and abuse attempts.

## Joint
- [ ] Decide timeout duration and dispute assumptions.
- [ ] Finalize event schema for frontend/CLI indexing.
- [ ] Rehearse full demo twice and timebox under 4 minutes.
