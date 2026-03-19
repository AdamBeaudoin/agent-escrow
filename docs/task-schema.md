# Canonical task payload (off-chain)

On-chain, the contract stores a **`metadataHash`** (`bytes32`) for the task definition. Off-chain, publish a JSON document (IPFS, gist, or team API) and set:

```text
TASK_METADATA_HASH = keccak256(utf8Bytes(canonicalJson))
```

Use **canonical JSON** (stable key order, no trailing spaces) so the hash is reproducible.

## Schema (v1)

```json
{
  "version": 1,
  "title": "Short human title",
  "summary": "One paragraph scope",
  "deliverables": ["bullet", "list"],
  "acceptanceCriteria": ["testable", "conditions"],
  "rubricId": "default-v1",
  "deadline": "2026-03-22T23:59:59Z",
  "bounty": {
    "token": "0x20c000000000000000000000b9537d11c60e8b50",
    "amountRaw": "1000000",
    "decimals": 6,
    "symbol": "USDC"
  },
  "roles": {
    "requester": "0x...",
    "worker": "0x...",
    "judge": "0x..."
  },
  "judgeReviewPeriodSeconds": 86400
}
```

## Field notes

| Field | Purpose |
|--------|---------|
| `version` | Bump when breaking schema changes |
| `acceptanceCriteria` | Judge checks these against `workRef` content |
| `rubricId` | Points to rubric text (e.g. `docs/judge-checklist.md` section) |
| `judgeReviewPeriodSeconds` | **Should match** `JUDGE_REVIEW_PERIOD_SECONDS` used in `createTask` |
| `deadline` | Social / off-chain cutoff; on-chain timeout is `judgeReviewPeriod` after **submit** |

## MPP alignment

- Worker service can echo `taskId` + artifact URL; hash the **full task spec** above for `metadataHash`.
- Judge service can take `workRef` + `rubricId` from this JSON.
