#!/usr/bin/env bash
# Compact PR diff for reviewers. Usage: review-diff.sh [since-sha]
#   no arg   -> full PR diff vs merge-base with origin/main
#   since    -> only what changed since that commit (incremental re-review)
# Prints FINGERPRINT (content hash of the whole PR, stable across clean rebases), HEAD, stat, diff.
# Lockfiles and generated files are left out to save tokens; they still count in the fingerprint.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
branch=$(git branch --show-current)
[ -n "$branch" ] || { echo "ERROR: detached HEAD, so check out the PR branch (gh pr checkout <n>)"; exit 1; }
git fetch -q origin main "$branch"
[ -z "$(git status --porcelain --untracked-files=no)" ] || { echo "ERROR: uncommitted changes, so commit and push first"; exit 1; }
[ "$(git rev-parse HEAD)" = "$(git rev-parse "origin/$branch")" ] || { echo "ERROR: local HEAD != origin/$branch, so push first"; exit 1; }
base=$(git merge-base origin/main HEAD)
from=${1:-$base}
echo "FINGERPRINT: $("$(dirname "$0")/fingerprint.sh" HEAD)"
echo "HEAD: $(git rev-parse HEAD)"
echo "SCOPE: $([ -n "${1:-}" ] && echo "incremental since ${1:0:7}" || echo "full PR")"
EXCL=(':!package-lock.json' ':!drizzle/meta/**' ':!*.svg' ':!*.ico' ':!*.png')
git diff --stat=100 "$from" HEAD
echo "---"
diff=$(git diff -U2 "$from" HEAD -- . "${EXCL[@]}")
printf '%s\n' "$diff" | head -n 1500 || true
[ "$(printf '%s\n' "$diff" | wc -l)" -le 1500 ] || echo "[TRUNCATED at 1500 lines; read remaining files directly]"
