#!/usr/bin/env bash
# Run from anywhere; uses agent-escrow/ as the tree to validate.
set -euo pipefail

AGENT_ESCROW="$(cd "$(dirname "$0")/.." && pwd)"
cd "$AGENT_ESCROW"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a git repo. Run 'git init' from your chosen project root first."
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"

echo "== Git repo root: $REPO_ROOT"
echo "== Agent escrow dir: $AGENT_ESCROW"
echo ""

fail=0

tracked_env="$(git -C "$REPO_ROOT" ls-files | grep -E '(^|/)\.env$' || true)"
if [[ -n "$tracked_env" ]]; then
  echo "FAIL: These .env files are tracked (they must be gitignored):"
  echo "$tracked_env"
  fail=1
else
  echo "OK: No tracked .env files."
fi

for rel in code/.env mpp-services/judge-service/.env; do
  f="$AGENT_ESCROW/$rel"
  if [[ -f "$f" ]]; then
    if git -C "$REPO_ROOT" check-ignore -q "$f" 2>/dev/null; then
      echo "OK: $rel is gitignored."
    else
      echo "WARN: $rel exists but is NOT ignored — fix .gitignore or location."
      fail=1
    fi
  fi
done

echo ""
echo "== Scanning STAGED files for common secret patterns (after git add)..."
staged="$(git -C "$REPO_ROOT" diff --cached --name-only 2>/dev/null || true)"
if [[ -z "$staged" ]]; then
  echo "(nothing staged — run git add, then run this script again before commit)"
else
  hit=0
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    full="$REPO_ROOT/$path"
    [[ -f "$full" ]] || continue
    if grep -q 'sk-ant-api' "$full" 2>/dev/null; then
      echo "FAIL: Anthropic-style key pattern in staged file: $path"
      hit=1
      fail=1
    fi
  done <<< "$staged"
  if [[ "$hit" -eq 0 ]]; then
    echo "OK: No sk-ant-api pattern in staged files."
  fi
fi

echo ""
if [[ "$fail" -ne 0 ]]; then
  echo "Fix issues above before pushing."
  exit 1
fi
echo "Looks safe to commit (still: review git diff --cached yourself)."
exit 0
