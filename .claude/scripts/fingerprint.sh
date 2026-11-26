#!/usr/bin/env bash
# Content fingerprint of a PR: patch-id of (merge-base with origin/main)..<ref>.
# The same changes give the same id even after a clean rebase, so reviews survive rebases but not edits.
set -euo pipefail
ref=${1:-HEAD}
base=$(git merge-base origin/main "$ref")
git diff "$base" "$ref" | git patch-id --stable | cut -d' ' -f1
