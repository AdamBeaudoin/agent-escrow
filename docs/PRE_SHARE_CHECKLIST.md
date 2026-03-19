# Before pushing `agent-escrow` to GitHub

## 1) Confirm nothing sensitive is tracked

```bash
cd agent-escrow   # or repo root containing this folder
git status
git ls-files | grep -E '\.env$|node_modules|/out/|/cache/'
```

Expected: **no output** from `git ls-files` for those patterns. If anything appears:

```bash
git rm -r --cached path/to/leaked-file
```

## 2) If `.env` was ever committed or pasted anywhere

- **Rotate** `MPP_SECRET_KEY` (generate a new `openssl rand -hex 32` on both services).
- **Rotate** `ANTHROPIC_API_KEY` in Anthropic’s console if it was exposed.
- **Never** commit `code/.env` (Foundry private keys).

## 3) Teammate can reproduce

- **Contracts:** `cd code && forge install` (if needed) && `forge build && forge test`
- **MPP:** `cd mpp-services/judge-service && npm ci`

## 4) Optional: strip local build artifacts

If anything slipped in before `.gitignore` was updated:

```bash
rm -rf code/cache code/out mpp-services/*/node_modules
```

Then reinstall / rebuild as above.
