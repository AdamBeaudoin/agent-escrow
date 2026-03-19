# Where are the `.env` files?

Dotfiles are easy to miss in the file tree. There are **two** local secrets files (none are committed; see `../.gitignore`):

| What | Path |
|------|------|
| **Foundry / escrow** | `agent-escrow/code/.env` |
| **MPP judge** | `agent-escrow/mpp-services/judge-service/.env` |

**Templates** (safe to commit): same folders, named **`.env.example`**.

**Nearby files:** each service folder has `server.js` + `package.json` (MPP) or `Makefile` + `foundry.toml` (code).

**Bootstrap:** `agent-escrow/mpp-services/scripts/bootstrap-mainnet.sh` sets up the judge service `.env` file.
