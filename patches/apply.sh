#!/usr/bin/env bash
# Apply Scoria's fixes to submodules (they live in other repos, so we keep them as patches).
# Safe to run repeatedly: already-applied patches are skipped.
set -euo pipefail
cd "$(dirname "$0")/.."
for p in patches/muse/*.patch; do
    [ -e "$p" ] || continue
    if git -C muse apply --reverse --check "../$p" 2>/dev/null; then
        echo "already applied: $p"
    else
        git -C muse apply "../$p"
        echo "applied: $p"
    fi
done
