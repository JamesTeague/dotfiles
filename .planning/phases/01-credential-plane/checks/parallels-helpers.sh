# shellcheck shell=bash
# .planning/phases/01-credential-plane/checks/parallels-helpers.sh
#
# Sourceable Parallels VM management helpers for Phase 1 VM e2e verification.
# Pure function definitions — no execution at source time.
#
# Public API:
#   prl_available()           - return 0 if prlctl is on PATH
#   prl_resolve_snapshot_uuid - print UUID for the configured snapshot name
#   prl_restore_snapshot()    - restore VM to the named snapshot + start
#   prl_wait_for_boot()       - poll SSH until VM is reachable (max 5 min)
#
# Configuration via env vars (all have defaults):
#   PRL_VM_NAME     - VM name in Parallels (default: macOS-26-vanilla)
#   PRL_SNAPSHOT    - Snapshot name to restore (default: vanilla-fresh-boot-pre-chezmoi)
#   VM_SSH_HOST     - SSH target for verification steps (default: jteague@10.211.55.4)
#
# Operator note: PRL_VM_NAME MUST match the actual VM name in Parallels Desktop.
# Run 'prlctl list -a' to see available VMs and confirm the name before running vm-e2e.sh.

# Sentinel guard
if [[ -n "${PARALLELS_HELPERS_LOADED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
PARALLELS_HELPERS_LOADED=1

# ---------------------------------------------------------------------------
# Configuration (env-overridable)
# ---------------------------------------------------------------------------

prl_vm_name="${PRL_VM_NAME:-macOS-26-vanilla}"
prl_snapshot_name="${PRL_SNAPSHOT:-vanilla-fresh-boot-pre-chezmoi}"
vm_ssh_host="${VM_SSH_HOST:-jteague@10.211.55.4}"

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

# prl_available: return 0 if prlctl is on PATH, 1 otherwise.
prl_available() {
  command -v prlctl >/dev/null 2>&1
}

# prl_resolve_snapshot_uuid: print the UUID for the configured snapshot name.
# Tries jq first; falls back to grep-based extraction if jq is not available.
# Prints the UUID to stdout. Returns 1 if not found.
prl_resolve_snapshot_uuid() {
  local raw_list
  raw_list="$(prlctl snapshot-list "${prl_vm_name}" --json 2>/dev/null)" || {
    printf 'prl_resolve_snapshot_uuid: prlctl snapshot-list failed\n' >&2
    return 1
  }

  local uuid
  if command -v jq >/dev/null 2>&1; then
    uuid="$(printf '%s' "${raw_list}" | jq -r --arg n "${prl_snapshot_name}" '.[] | select(.name==$n) | .id' 2>/dev/null)"
  else
    # Fallback: grep for the snapshot name then extract the uuid field nearby.
    # JSON shape: [{"uuid":"{...}","name":"...", ...}, ...]
    uuid="$(printf '%s' "${raw_list}" \
      | grep -A2 "\"name\".*${prl_snapshot_name}" \
      | grep '"id"' \
      | sed 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"
  fi

  if [[ -z "${uuid}" ]]; then
    printf 'prl_resolve_snapshot_uuid: snapshot "%s" not found in VM "%s"\n' \
      "${prl_snapshot_name}" "${prl_vm_name}" >&2
    return 1
  fi
  printf '%s' "${uuid}"
}

# prl_restore_snapshot: restore the VM to the named snapshot, then start it.
# Idempotent: start is best-effort (VM may already be starting from restore).
prl_restore_snapshot() {
  local uuid
  uuid="$(prl_resolve_snapshot_uuid)" || return 1

  printf 'Restoring snapshot "%s" (uuid: %s) on VM "%s"...\n' \
    "${prl_snapshot_name}" "${uuid}" "${prl_vm_name}"
  prlctl snapshot-switch "${prl_vm_name}" --id "${uuid}" || {
    printf 'prl_restore_snapshot: snapshot-switch failed\n' >&2
    return 1
  }

  # Start VM (idempotent — ignore error if already starting/running)
  prlctl start "${prl_vm_name}" 2>/dev/null || true
  printf 'Snapshot restored. Waiting for VM to boot...\n'
}

# prl_wait_for_boot: poll SSH until the VM is reachable or 5 minutes pass.
# Uses a simple echo-ok probe; retries up to 60 times at 5s intervals (300s).
prl_wait_for_boot() {
  local max_attempts=60
  local sleep_sec=5
  local attempt=0

  printf 'Polling %s for SSH readiness (max %ds)...\n' \
    "${vm_ssh_host}" "$((max_attempts * sleep_sec))"

  while (( attempt < max_attempts )); do
    attempt=$((attempt + 1))
    if ssh \
        -o ConnectTimeout=5 \
        -o StrictHostKeyChecking=no \
        -o BatchMode=yes \
        "${vm_ssh_host}" echo ok 2>/dev/null; then
      printf 'VM is reachable after %ds.\n' "$((attempt * sleep_sec))"
      return 0
    fi
    printf '  attempt %d/%d — not yet reachable; sleeping %ds\n' \
      "${attempt}" "${max_attempts}" "${sleep_sec}"
    sleep "${sleep_sec}"
  done

  printf 'prl_wait_for_boot: VM did not become reachable after %ds\n' \
    "$((max_attempts * sleep_sec))" >&2
  return 1
}
