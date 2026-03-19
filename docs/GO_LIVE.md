# Go live (share with judges / teammates)

You need **three public artifacts** for a crisp demo:

1. **Smart contract** on Tempo mainnet (verified explorer link)
2. **Judge HTTP API** on the public internet (HTTPS)
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

The judge service needs `MPP_SECRET_KEY` and a real **`MPP_RECIPIENT`** (your payout wallet).

### Option A — Render (Blueprint)

1. Repo root must include **`render.yaml`** (already at workspace root: `Tempo Hackathon/render.yaml`).
2. Render → **New** → **Blueprint** → connect repo.
3. After deploy, open the judge service → **Environment** → set:
   - `MPP_SECRET_KEY`
   - `MPP_RECIPIENT`
   - `ANTHROPIC_API_KEY` (optional — heuristic fallback works without it)
   - `JUDGE_PRIVATE_KEY` + `ESCROW_ADDRESS` (for auto-settlement)
4. Note the public URL, e.g. `https://agent-escrow-judge.onrender.com`

**Health checks:** `GET /health` on each service.

### Option B — Docker (Railway, Fly, VPS)

Each folder has a **`Dockerfile`**. Example (Fly):

```bash
cd agent-escrow/mpp-services/judge-service
fly launch --name your-judge --internal-port 4102  # set secrets in dashboard
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
- [ ] Judge `GET /health` 200 on HTTPS
- [ ] `MPP_SECRET_KEY` set on judge service
- [ ] Contract demo steps 1–4 (or 5) rehearsed once on mainnet
