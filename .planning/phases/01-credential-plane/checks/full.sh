#!/usr/bin/env bash
# .planning/phases/01-credential-plane/checks/full.sh
#
# Phase 1 full verification suite: structural gates (quick.sh) + VM-driven
# smoke tests (vm-e2e.sh). Designed for wave-merge gates and pre-/gsd:verify-work.
#
# VM smokes cover: SEC-08/09/10/12/13(keypair)/14/16 (idempotency).
# Structural gates cover: SEC-02/05/07/08/11/13(presence)/15.
#
# Usage:
#   bash full.sh               # run quick.sh + vm-e2e.sh
#   bash full.sh --no-vm       # run quick.sh only (skips VM smokes)
#   bash full.sh --strict      # pass --strict to quick.sh (PENDING -> FAIL)
#   bash full.sh --no-vm --strict  # strict structural gates, no VM
#
# Notes:
#   - full.sh aggregates: it always runs quick.sh and (unless --no-vm) vm-e2e.sh.
#     A quick.sh failure does NOT short-circuit vm-e2e.sh — both run, both are
#     reported in the final aggregate summary.
#   - VM smokes require prlctl (Parallels Desktop). If prlctl is absent,
#     vm-e2e.sh self-reports pending and exits 0 — full.sh reflects that.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Parse flags
SKIP_VM=0
STRICT_FLAG=""
for arg in "$@"; do
  case "${arg}" in
    --no-vm)   SKIP_VM=1 ;;
    --strict)  STRICT_FLAG="--strict"; export STRICT=1 ;;
    --help|-h)
      sed -n '2,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      printf 'unknown arg: %s (try --help)\n' "${arg}" >&2
      exit 2
      ;;
  esac
done

# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

# ---------------------------------------------------------------------------
# Step 1: Structural gates (quick.sh)
# ---------------------------------------------------------------------------
printf '%s== Phase 1 Full Suite ==%s\n' "${C_BOLD}" "${C_RESET}"
printf 'Running quick.sh (structural gates)...\n\n'

# Run quick.sh; capture exit code but don't abort — full.sh aggregates.
# shellcheck disable=SC2086
bash "${SCRIPT_DIR}/quick.sh" ${STRICT_FLAG}
quick_rc=$?

if [[ "${quick_rc}" -ne 0 ]]; then
  printf '\nquick.sh exited %d (structural gates failed)\n' "${quick_rc}"
else
  printf '\nquick.sh exited 0 (structural gates passed)\n'
fi

# ---------------------------------------------------------------------------
# Step 2: VM smokes (vm-e2e.sh) — skip when --no-vm passed
# ---------------------------------------------------------------------------
vm_rc=0
if [[ "${SKIP_VM}" == "1" ]]; then
  printf '\nVM smokes skipped (--no-vm)\n'
else
  printf '\nRunning vm-e2e.sh (VM smoke tests)...\n\n'
  bash "${SCRIPT_DIR}/vm-e2e.sh"
  vm_rc=$?
  if [[ "${vm_rc}" -ne 0 ]]; then
    printf '\nvm-e2e.sh exited %d (VM smokes failed)\n' "${vm_rc}"
  else
    printf '\nvm-e2e.sh exited 0 (VM smokes passed)\n'
  fi
fi

# ---------------------------------------------------------------------------
# Aggregate summary
# ---------------------------------------------------------------------------
printf '\n%s== Aggregate Result ==%s\n' "${C_BOLD}" "${C_RESET}"
printf '  quick.sh  : %s\n' "$( [[ "${quick_rc}" -eq 0 ]] && echo PASS || echo FAIL )"
if [[ "${SKIP_VM}" == "1" ]]; then
  printf '  vm-e2e.sh : SKIPPED (--no-vm)\n'
else
  printf '  vm-e2e.sh : %s\n' "$( [[ "${vm_rc}" -eq 0 ]] && echo PASS || echo FAIL )"
fi

# Exit non-zero if either suite failed
if [[ "${quick_rc}" -ne 0 ]] || [[ "${vm_rc}" -ne 0 ]]; then
  exit 1
fi
exit 0
