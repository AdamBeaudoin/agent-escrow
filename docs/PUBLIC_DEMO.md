# Public demo — fill in and share

| Item | Value |
|------|--------|
| **Repo** | `https://github.com/...` |
| **Escrow contract** | `0x…` |
| **Explorer** | `https://explore.tempo.xyz/...` |
| **TIP-20 token** | `0x20c000000000000000000000b9537d11c60e8b50` (USDC example) |
| **Worker API** | `https://…/health` · `POST …/work/submit` (MPP) |
| **Judge API** | `https://…/health` · `POST …/judge/evaluate` (MPP) |

## Try it (Tempo CLI)

```bash
tempo wallet login --network tempo
tempo request --network tempo "https://YOUR_WORKER/work/submit" \
  -X POST -H "content-type: application/json" \
  -d '{"taskId":"1","requesterAddress":"0xYourAddress","artifactUrl":"https://example.com/out","summary":"demo"}'

tempo request --network tempo "https://YOUR_JUDGE/judge/evaluate" \
  -X POST -H "content-type: application/json" \
  -d '{"taskId":"1","workRef":"ipfs://…","rubric":"default-v1"}'
```

## On-chain flow

See **`code/docs/runbook.md`** — `make demo-step1` … `demo-step4` with `ESCROW_ADDRESS` and funded role keys.
