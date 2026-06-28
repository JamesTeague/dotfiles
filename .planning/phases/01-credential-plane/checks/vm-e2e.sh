#!/usr/bin/env bash
# .planning/phases/01-credential-plane/checks/vm-e2e.sh
#
# Composite VM end-to-end orchestration for Phase 1 credential-plane verification.
#
# Steps:
#   1. Preflight: check prlctl availability (graceful pending if absent)
#   2. Snapshot restore: restore VM to vanilla-fresh-boot-pre-chezmoi + boot wait
#   3. Stage 1: chezmoi init --apply over SSH
#   4. Stage 2: setup-credentials.sh over SSH (interactive — operator provides device-flow code)
#   5. Verifications: SEC-08/09/10/12/13/14 assertions over SSH
#   6. SEC-16 idempotency: re-run Stage 2, assert no-op
#
# Usage:
#   bash vm-e2e.sh
#   PRL_VM_NAME=my-vm bash vm-e2e.sh    # override VM name
#   VM_SSH_HOST=user@host bash vm-e2e.sh # override SSH target
#
# Prerequisites:
#   - prlctl available (Parallels Desktop installed on host Mac)
#   - PRL_VM_NAME matches the actual VM name (default: macOS-26-vanilla)
#   - SSH key access to VM already configured (key-based, no password prompt)
#   - Snapshot "vanilla-fresh-boot-pre-chezmoi" exists on the VM

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

# shellcheck source=parallels-helpers.sh
source "${SCRIPT_DIR}/parallels-helpers.sh"

if [[ -z "${REPO_ROOT}" ]]; then
  printf 'vm-e2e.sh: not in a git repo; cannot resolve REPO_ROOT\n' >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Step 1: Preflight — prlctl availability
# ---------------------------------------------------------------------------
header "Preflight: prlctl availability"
if ! prl_available; then
  pending "prlctl not available — skipping VM e2e (install Parallels Desktop to run VM checks)"
  summary
  exit 0
fi
pass "prlctl is available"

# ---------------------------------------------------------------------------
# Step 2: Snapshot restore + boot wait
# ---------------------------------------------------------------------------
header "Snapshot restore: ${prl_snapshot_name}"
if prl_restore_snapshot; then
  pass "snapshot restore initiated: ${prl_snapshot_name}"
else
  fail "snapshot restore failed — cannot proceed with VM e2e"
  summary
  exit 1
fi

if prl_wait_for_boot; then
  pass "VM boot: SSH reachable at ${vm_ssh_host}"
else
  fail "VM boot: SSH not reachable after timeout"
  summary
  exit 1
fi

# ---------------------------------------------------------------------------
# Step 3: Stage 1 — chezmoi init --apply over SSH
# ---------------------------------------------------------------------------
header "Stage 1: chezmoi init --apply (JamesTeague/dotfiles)"
if ssh "${vm_ssh_host}" \
    'sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply JamesTeague/dotfiles'; then
  pass "Stage 1 complete: chezmoi init --apply succeeded"
else
  fail "Stage 1 failed: chezmoi init --apply returned non-zero"
  summary
  exit 1
fi

# ---------------------------------------------------------------------------
# Step 4: Stage 2 — setup-credentials.sh over SSH
# ---------------------------------------------------------------------------
header "Stage 2: setup-credentials.sh"
printf '\n'
printf '  *** OPERATOR ACTION REQUIRED ***\n'
printf '  setup-credentials.sh will prompt for GitHub device-flow authorization.\n'
printf '  When prompted, visit https://github.com/login/device and enter the code.\n'
printf '\n'

if ssh -t "${vm_ssh_host}" 'bash ~/scripts/setup-credentials.sh'; then
  pass "Stage 2 complete: setup-credentials.sh succeeded"
else
  fail "Stage 2 failed: setup-credentials.sh returned non-zero"
  summary
  exit 1
fi

# ---------------------------------------------------------------------------
# Step 5: Verifications
# ---------------------------------------------------------------------------
header "SEC-08: chezmoi remote rewritten to git@github-personal"
if ssh "${vm_ssh_host}" \
    'chezmoi git -- remote get-url origin 2>/dev/null | grep -qE "^git@github-personal:"'; then
  pass "SEC-08: chezmoi remote is git@github-personal:..."
else
  fail "SEC-08: chezmoi remote is NOT git@github-personal:..."
fi

header "SEC-09: signed commit verification"
if ssh "${vm_ssh_host}" \
    'git init /tmp/verify-repo 2>/dev/null; cd /tmp/verify-repo && git commit -S --allow-empty -m phase1 && git log --show-signature -1 2>&1 | grep -qE "Good signature|gpg: Signature made"'; then
  pass "SEC-09: git commit -S produced a verifiable GPG signature"
else
  fail "SEC-09: signed commit verification failed (no Good signature in log)"
fi

header "SEC-10: ssh -T git@github-personal authentication"
# Note: ssh -T exits 1 by design (no shell granted); assertion is grep on output.
ssh_t_out="$(ssh "${vm_ssh_host}" 'ssh -T git@github-personal 2>&1' || true)"
if printf '%s' "${ssh_t_out}" | grep -q "successfully authenticated"; then
  pass "SEC-10: ssh -T git@github-personal returned GitHub welcome"
else
  fail "SEC-10: ssh -T git@github-personal did NOT return expected greeting"
  printf '%s\n' "${ssh_t_out}" | sed 's/^/      | /'
fi

header "SEC-12: --rotate-* flags present in setup-credentials.sh --help"
help_out="$(ssh "${vm_ssh_host}" 'bash ~/scripts/setup-credentials.sh --help 2>&1' || true)"
if printf '%s' "${help_out}" | grep -q "rotate-ssh" && \
   printf '%s' "${help_out}" | grep -q "rotate-gpg" && \
   printf '%s' "${help_out}" | grep -q "rotate-all"; then
  pass "SEC-12: --rotate-ssh, --rotate-gpg, --rotate-all all present in --help output"
else
  fail "SEC-12: one or more --rotate-* flags missing from setup-credentials.sh --help"
  printf '%s\n' "${help_out}" | sed 's/^/      | /'
fi

header "SEC-13: per-machine ed25519 keypair present"
if ssh "${vm_ssh_host}" \
    'test -f ~/.ssh/personal_ed25519 && ssh-keygen -lf ~/.ssh/personal_ed25519.pub | grep -q ED25519'; then
  pass "SEC-13: ~/.ssh/personal_ed25519 exists and is ED25519"
else
  fail "SEC-13: ~/.ssh/personal_ed25519 missing or not ED25519"
fi

header "SEC-14: GPG signing key present and matches chezmoi data"
if ssh "${vm_ssh_host}" \
    'KID=$(chezmoi data | jq -r .signingkey); test -n "$KID" && test "$KID" != null && gpg --list-secret-keys --keyid-format LONG | grep -q "$KID"'; then
  pass "SEC-14: GPG signing key present; matches chezmoi data signingkey"
else
  fail "SEC-14: GPG key missing or signingkey in chezmoi data does not match"
fi

# ---------------------------------------------------------------------------
# Step 6: SEC-16 idempotency — re-run Stage 2, assert no new keys
# ---------------------------------------------------------------------------
header "SEC-16 idempotency: re-run setup-credentials.sh (must be no-op)"

# Capture SSH key count before re-run
ssh_count_before="$(ssh "${vm_ssh_host}" 'gh ssh-key list --json id --jq "length" 2>/dev/null || echo 0')"

if ssh "${vm_ssh_host}" 'bash ~/scripts/setup-credentials.sh'; then
  pass "SEC-16 re-run: exit code 0 (no-op re-run succeeded)"
else
  fail "SEC-16 re-run: setup-credentials.sh returned non-zero on second invocation"
fi

ssh_count_after="$(ssh "${vm_ssh_host}" 'gh ssh-key list --json id --jq "length" 2>/dev/null || echo 0')"
if [[ "${ssh_count_before}" == "${ssh_count_after}" ]]; then
  pass "SEC-16 idempotency: SSH key count unchanged (${ssh_count_before} keys before and after)"
else
  fail "SEC-16 idempotency: SSH key count changed from ${ssh_count_before} to ${ssh_count_after} (new key registered on re-run)"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
summary; exit $?
