# Go live (share with judges / teammates)

You need **three public artifacts** for a crisp demo:

1. **Smart contract** on Tempo mainnet (verified explorer link)
2. **Worker + Judge HTTP APIs** on the public internet (HTTPS)
3. **Repo** (GitHub/GitLab) so people can read the code

---

## 1) Push the code

From your machine (adjust remote):

```bash
cd "/Users/adam/Documents/Tempo Hackathon"
git init
git add .
git commit -m "Agent Escrow + MPP services"
# Create an empty repo on GitHub, then:
git remote add origin https://github.com/<you>/<repo>.git
git branch -M main
git push -u origin main
```

Add a **LICENSE** if the hackathon requires it.

---

## 2) Deploy the escrow contract

See **`../code/docs/runbook.md`**.

1. Fill **`code/.env`** from **`code/.env.example`**
2. `cd code && source .env` (or export vars however you prefer)
3. `make deploy-mainnet` (or `make deploy-mainnet-verify`)
4. Save **`ESCROW_ADDRESS`** and the **explorer URL** (e.g. `https://explore.tempo.xyz/...`)

Put those in your demo slide / **`docs/PUBLIC_DEMO.md`** (template below).

---

## 3) Deploy MPP services (HTTPS)

Both services need the **same** `MPP_SECRET_KEY` and a real **`MPP_RECIPIENT`** (your payout wallet).

### Option A — Render (Blueprint)

1. Repo root must include **`render.yaml`** (already at workspace root: `Tempo Hackathon/render.yaml`).
2. Render → **New** → **Blueprint** → connect repo.
3. After deploy, open each service → **Environment** → set:
   - `MPP_SECRET_KEY` (same value on **worker** and **judge**)
   - `MPP_RECIPIENT`
   - Optional judge: `ANTHROPIC_API_KEY`
4. Note the public URLs, e.g. `https://agent-escrow-worker.onrender.com`

**Health checks:** `GET /health` on each service.

### Option B — Docker (Railway, Fly, VPS)

Each folder has a **`Dockerfile`**. Example (Fly):

```bash
cd agent-escrow/mpp-services/worker-service
fly launch --name your-worker --internal-port 4101  # set secrets in dashboard
```

Or from **`mpp-services/`**:

```bash
docker compose up --build
```

(on a VPS with a domain + TLS terminator like Caddy)

### Option C — Node directly

Platform sets **`PORT`** — our apps already read it. Set **`HOST=0.0.0.0`** (default in code). Run `npm install && npm start` with env vars from **`.env.example`**.

---

## 4) Point scripts / README at public URLs

```bash
export WORKER_URL="https://your-worker.example.com"
export JUDGE_URL="https://your-judge.example.com"
./agent-escrow/mpp-services/scripts/paid-requests-mainnet.sh
```

---

## 5) One-page “share sheet”

Copy **`PUBLIC_DEMO.md`**, fill in URLs and addresses, and paste into Notion / hackathon portal / PR description.

---

## Checklist

- [ ] GitHub (or similar) link works
- [ ] `ESCROW_ADDRESS` + explorer link
- [ ] Worker `GET /health` 200 on HTTPS
- [ ] Judge `GET /health` 200 on HTTPS
- [ ] Same `MPP_SECRET_KEY` on both services
- [ ] `tempo request --network tempo https://.../work/submit` succeeds from a funded wallet
- [ ] Contract demo steps 1–4 (or 5) rehearsed once on mainnet
