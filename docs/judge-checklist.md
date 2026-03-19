# Judge checklist (`rubricId: default-v1`)

Use this for live demo narration or LLM judge prompts. On-chain, the judge only signs **`approve`** + **`resolutionMemo`**; this list is the **reasoning** behind that call.

## Before evaluation

- [ ] Confirm `taskId` matches the escrow task and **`metadataHash`** matches the published task JSON.
- [ ] Open **`workRef`** (IPFS, URL, or commit) and verify it is the worker’s submission for this task.

## Approval (`approve = true`)

All must be true:

- [ ] **Scope**: Deliverables cover what `summary` and `acceptanceCriteria` asked for.
- [ ] **Quality**: Output is usable (no placeholder-only content unless explicitly allowed).
- [ ] **Integrity**: Artifact is coherent with the stated `taskId` / metadata (no obvious wrong task).

**Memo examples:** `"accept: criteria 1–3 satisfied"`, `"accept: integration tests pass per CI link"`.

## Rejection (`approve = false`)

Reject if any of the following:

- [ ] Missing required deliverables or failed acceptance criteria.
- [ ] Broken links, empty artifact, or unrelated content.
- [ ] Cheating / wrong task submission.

**Memo examples:** `"reject: missing API tests"`, `"reject: workRef 404"`.

## Timeout path

If you **cannot** evaluate before the on-chain review window ends, the **requester** may call `claimJudgeTimeout` and reclaim funds. Prefer resolving explicitly (`approve` true/false) whenever possible.

## LLM judge (optional)

Point the judge service at this file or paste the criteria into the `rubric` field of the `/judge/evaluate` request. The LLM returns JSON `{ "approve": bool, "resolutionMemo": string, "reasoning": string }`. The `resolutionMemo` is passed to on-chain `resolveTask`.
