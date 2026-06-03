#!/usr/bin/env bash
# cutover-phase-0.sh
#
# Per-machine cutover script for Phase 0 (Structural Taxonomy Refactor).
# Run ONCE per machine after the phase-0 branch is merged to main.
#
# Usage (on Mac personal and Mac work separately):
#   cd ~/.local/share/chezmoi
#   git checkout main && git pull
#   bash .planning/phases/0-structural-refactor/cutover-phase-0.sh
#   # Answer role prompt interactively (type: dev)
#
# 8-step locked design per 0-RESEARCH.md Pattern 4 + 0-CONTEXT.md Cutover Ritual.
# set -euo pipefail: on verify-gate failure, exit non-zero — restore from snapshot.
# No auto-rollback per CLAUDE.md "manual work = collaborative mode".
#
# Requires: chezmoi >= 2.70.4 (preflight step 2 enforces; brew upgrade chezmoi if needed)

set -euo pipefail

# ---------------------------------------------------------------------------
# Step 1: Print snapshot path FIRST (before any mutation)
# ---------------------------------------------------------------------------
SNAP_DIR="${HOME}/dotfiles-cutover-snapshot-$(date +%Y%m%d-%H%M%S)"
echo "=========================================="
echo "SNAPSHOT PATH (BEFORE any mutation): ${SNAP_DIR}"
echo "If anything goes wrong, restore from here."
echo "=========================================="
echo ""
mkdir -p "${SNAP_DIR}"

# ---------------------------------------------------------------------------
# Step 2: Preflight — require chezmoi >= 2.70.4
# ---------------------------------------------------------------------------
echo "[Step 2] Preflight: checking chezmoi version..."
chezmoi_ver_raw=$(chezmoi --version 2>&1 | head -1)
chezmoi_ver=$(echo "${chezmoi_ver_raw}" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
required="2.70.4"

if [[ -z "${chezmoi_ver}" ]]; then
  echo "FATAL: could not parse chezmoi version from: ${chezmoi_ver_raw}" >&2
  exit 1
fi

# sort -V handles version comparison; if required sorts before actual, actual >= required
if [ "$(printf '%s\n%s\n' "${required}" "${chezmoi_ver}" | sort -V | head -n1)" != "${required}" ]; then
  echo "FATAL: chezmoi ${chezmoi_ver} < required ${required}." >&2
  echo "       Run: brew upgrade chezmoi" >&2
  exit 1
fi
echo "  chezmoi ${chezmoi_ver} >= ${required}: OK"

# ---------------------------------------------------------------------------
# Step 3: Targeted snapshot (5 key paths + ~/bin/)
# ---------------------------------------------------------------------------
echo ""
echo "[Step 3] Snapshot: capturing 5 paths + ~/bin/ to ${SNAP_DIR}..."
for f in \
  "${HOME}/.config/chezmoi/chezmoi.toml" \
  "${HOME}/.zshrc" \
  "${HOME}/.localrc" \
  "${HOME}/.gitconfig.local" \
; do
  if [[ -e "${f}" ]]; then
    cp -a "${f}" "${SNAP_DIR}/"
    echo "  captured: ${f}"
  fi
done
if [[ -d "${HOME}/bin" ]]; then
  cp -a "${HOME}/bin" "${SNAP_DIR}/bin"
  echo "  captured: ~/bin/ ($(ls "${HOME}/bin/" | wc -l | tr -d ' ') files)"
else
  echo "  ~/bin/ not present (nothing to capture)"
fi
echo "  Snapshot complete."

# ---------------------------------------------------------------------------
# Step 4: Pre-pull migration — Mac work autodetect (NODE_EXTRA_CA_CERTS)
# ---------------------------------------------------------------------------
echo ""
echo "[Step 4] Mac work autodetect: checking for NODE_EXTRA_CA_CERTS in ~/.zshrc..."
if grep -q NODE_EXTRA_CA_CERTS "${HOME}/.zshrc" 2>/dev/null; then
  line=$(grep NODE_EXTRA_CA_CERTS "${HOME}/.zshrc")
  echo "  Detected Mac work: found NODE_EXTRA_CA_CERTS in ~/.zshrc"
  echo "  Migrating to ~/.localrc..."
  echo "${line}" >> "${HOME}/.localrc"
  sed -i.bak "/NODE_EXTRA_CA_CERTS/d" "${HOME}/.zshrc"
  echo "  Migrated NODE_EXTRA_CA_CERTS to ~/.localrc (backup: ~/.zshrc.bak)"
else
  echo "  NODE_EXTRA_CA_CERTS not in ~/.zshrc — nothing to migrate (Mac personal or already migrated)"
fi

# ---------------------------------------------------------------------------
# Step 5: chezmoi init --apply (interactive role prompt)
# ---------------------------------------------------------------------------
echo ""
echo "[Step 5] Running chezmoi init --apply..."
echo "  You will be prompted for 'role' (type: dev, gaming, or lite)."
echo "  Existing personal/name/email prompts are skipped (Once semantics)."
echo ""
chezmoi init --apply

# ---------------------------------------------------------------------------
# Step 6: exact_bin teardown
# ---------------------------------------------------------------------------
echo ""
echo "[Step 6] exact_bin teardown: removing ~/bin/ and cleaning entryState..."
if [[ -d "${HOME}/bin" ]]; then
  rm -rf "${HOME}/bin/"
  echo "  Removed ~/bin/"
else
  echo "  ~/bin/ not present (nothing to remove)"
fi
# Clean up stale entryState entries for the 5 moved utilities.
# Uses space-separated --key /path form (not --key=/path) per follow-up #7:
# --key=/path triggers zsh EQUALS-option parsing pitfall on chezmoi 2.69.4.
for entry in dot git-bare-clone git-wtf tmux-cht.sh tmux-sessionizer; do
  chezmoi state delete --bucket=entryState --key /Users/jteague/bin/${entry} 2>/dev/null || true
  echo "  entryState cleanup: /Users/jteague/bin/${entry} (ok if key absent)"
done

# ---------------------------------------------------------------------------
# Step 7: Verify SC #4 — chezmoi diff -x externals empty
# ---------------------------------------------------------------------------
echo ""
echo "[Step 7] Verifying chezmoi diff -x externals is empty..."
diff_out=$(chezmoi diff -x externals 2>&1 || true)
if [[ -n "${diff_out}" ]]; then
  echo "FAIL: chezmoi diff -x externals is NOT empty." >&2
  echo "      Restore from: ${SNAP_DIR}" >&2
  echo "      Diff output:" >&2
  echo "${diff_out}" | sed 's/^/  | /' >&2
  exit 2
fi
echo "  chezmoi diff -x externals: EMPTY (clean)"

# ---------------------------------------------------------------------------
# Step 8: Verify SC #3 — no <no value> in dry-run output
# ---------------------------------------------------------------------------
echo ""
echo "[Step 8] Verifying no '<no value>' in chezmoi apply --dry-run --verbose output..."
# Note: chezmoi apply --dry-run --verbose exits nonzero on interactive TTY prompts
# (Phase 0.5 Plan 05 Pitfall). Capture output; check content, not exit code.
if chezmoi apply --dry-run --verbose 2>&1 | grep "no value"; then
  echo "FAIL: '<no value>' surfaced in dry-run output." >&2
  echo "      This indicates a missing template key." >&2
  echo "      Restore from: ${SNAP_DIR}" >&2
  exit 3
fi
echo "  no '<no value>' in dry-run output: CLEAN"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "Cutover complete!"
echo "Snapshot retained at: ${SNAP_DIR}"
echo "(Keep for 30 days, then rm -rf '${SNAP_DIR}')"
echo "=========================================="
