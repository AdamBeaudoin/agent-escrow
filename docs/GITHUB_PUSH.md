# Push to GitHub (public repo) — step by step, no secrets

Use this when the repo will be **public**. Anyone could scrape committed API keys or abuse billing.

## What must never be on GitHub

| Secret | Where it lives locally | On GitHub |
|--------|-------------------------|-----------|
| `ANTHROPIC_API_KEY` (Claude) | `judge-service/.env` only | **Never** — empty in `.env.example` is fine |
| `MPP_SECRET_KEY` | both service `.env` | **Never** |
| Foundry private keys | `code/.env` | **Never** |
| `MPP_RECIPIENT` | your wallet — OK to *document* as placeholder in `.env.example` | Real address optional; not a password |

**Judge service without Claude:** leave `ANTHROPIC_API_KEY` unset locally or empty — the app uses the **heuristic fallback** (already in code). Teammates do the same unless they add their **own** key locally.

---

## 1) Strip Claude from anything you might commit (paranoid mode)

You do **not** need to delete keys from disk forever — only ensure Git never sees them.

1. Open **`mpp-services/judge-service/.env`**
2. **Delete the value** for `ANTHROPIC_API_KEY` (leave the line as `ANTHROPIC_API_KEY=` or remove the line).
3. Save.

(Optional) Do the same on your machine before a demo if you’re worried about screen sharing — keys stay in a password manager, not in files.

---

## 2) Decide your Git root

**Option A — push only `agent-escrow/`** (simplest for teammates)

```bash
cd "/Users/adam/Documents/Tempo Hackathon/agent-escrow"
```

**Option B — push whole `Tempo Hackathon`**

```bash
cd "/Users/adam/Documents/Tempo Hackathon"
```

Use the same folder for all steps below.

---

## 3) Initialize Git (first time only)

```bash
git init
git branch -M main
```

---

## 4) Verify `.gitignore` is doing its job

From **`agent-escrow/`** (or ensure `agent-escrow/.gitignore` is in the tree you commit):

- It must list `code/.env`, both `mpp-services/**/.env`, `node_modules`, `code/cache`, `code/out`.

Smoke test:

```bash
# From repo root; adjust path if your root is agent-escrow:
git check-ignore -v agent-escrow/mpp-services/worker-service/.env 2>/dev/null || \
  git check-ignore -v mpp-services/worker-service/.env
```

You should see a line showing the file is **ignored**.

---

## 5) Pre-flight: nothing sensitive staged

```bash
git status
```

Confirm you do **not** see `.env` files as “new file” or “modified” **to be added**. If `.env` appears as **untracked**, that’s OK **only if** `git check-ignore` says they’re ignored (then `git add .` won’t add them).

**Hard check — no `.env` in the index:**

```bash
git ls-files | grep -E '(^|/)\.env$' || true
```

Expected: **no output** (only `*.env.example` may appear — that’s OK).

**Scan what you’re about to commit for obvious API key prefixes:**

```bash
git add .
git diff --cached --name-only | xargs grep -l 'sk-ant-api' 2>/dev/null || true
```

Expected: **no output**. If a path prints, **unstage and fix** that file (`git reset HEAD <file>`), remove the secret, re-add.

```bash
git diff --cached | grep -E 'PRIVATE_KEY=[0-9a-fA-F]{20,}' && echo "STOP: private key pattern in diff" || true
```

If it prints “STOP”, fix before committing.

---

## 6) Commit and push

```bash
git commit -m "Agent Escrow: contracts, MPP services, docs"
```

Create an empty repo on GitHub (public), then:

```bash
git remote add origin https://github.com/<YOU>/<REPO>.git
git push -u origin main
```

---

## 7) After a public push

- **Claude / Anthropic:** if a key was **ever** in a committed file, **rotate** it in the Anthropic console.
- **MPP:** if `MPP_SECRET_KEY` was ever committed, generate a new one (`openssl rand -hex 32`) everywhere you use it.
- Teammates: `cp .env.example .env` and fill **their own** secrets locally (or use `bootstrap-mainnet.sh` + manual edits).

---

## Optional helper script

From `agent-escrow/`:

```bash
./scripts/verify-safe-for-push.sh
```

Run it **after** `git add`, **before** `git commit`.
