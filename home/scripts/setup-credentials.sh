#!/usr/bin/env bash
# setup-credentials.sh — Stage 2 credential bootstrap for JamesTeague/dotfiles
#
# PURPOSE
#   Generate and register per-machine SSH and GPG keypairs after a fresh chezmoi
#   apply. This is the Stage 2 step in the two-stage bootstrap:
#
#     Stage 1 (offline-safe):  sh -c "$(curl -fsLS get.chezmoi.io)" \
#                                  -- init --apply JamesTeague/dotfiles
#     Stage 2 (prompts once):  ~/scripts/setup-credentials.sh
#
# TWO-STAGE ARCHITECTURE
#   Stage 1 runs offline, needs no credentials, configures the shell and
#   installs packages (including gh, gnupg, jq, chezmoi).  Stage 2 is
#   explicitly invoked by the operator AFTER Stage 1.  It:
#     - authenticates with GitHub via the gh device flow
#     - generates an ed25519 SSH key at ~/.ssh/personal_ed25519
#     - registers the SSH pubkey with GitHub (idempotent fingerprint-compare)
#     - [1-04b] generates an EDDSA/Ed25519 GPG key via parameter file
#     - [1-04b] registers the GPG pubkey with GitHub (idempotent key-ID-compare)
#     - [1-04b] writes signingkey to ~/.config/chezmoi/chezmoi.toml [data] section
#     - [1-04b] rewrites the chezmoi git remote to git@github-personal:...
#
# OPERATOR-INVOKED — NOT a chezmoi run_once_ script.
#   Re-runnable; idempotent by default; rotation via --rotate-* flags.
#   VaultWarden (bw) is NOT called in this script — VW is runtime-only.
#
# REFERENCES
#   docs/credential-plane.md                (two-stage flow + rotation playbook)
#   .planning/phases/01-credential-plane/1-CONTEXT.md   (architecture decisions)
#
# EXIT CODES
#   0  success (fresh or idempotent re-run)
#   1  pre-flight failure (required tool missing)
#   2  gh auth login failed / interrupted
#   3  SSH key generation or registration failed
#   4  GPG key generation or registration failed    [reserved for 1-04b]
#   5  signingkey write to chezmoi config failed    [reserved for 1-04b]
#   6  chezmoi remote rewrite or smoke test failed  [reserved for 1-04b]

set -uo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
KEY_DIR="${HOME}/.ssh"
SSH_KEY="${KEY_DIR}/personal_ed25519"
HOSTNAME_SHORT="$(hostname -s)"
TODAY="$(date +%Y%m%d)"
KEY_TITLE="${HOSTNAME_SHORT}-personal-${TODAY}"
CHEZMOI_CFG="${HOME}/.config/chezmoi/chezmoi.toml"
REQUIRED_SCOPES=("admin:public_key" "admin:gpg_key" "repo")
CHEZMOI_REMOTE_TARGET="git@github-personal:JamesTeague/dotfiles.git"
# Remote rewrite (1-04b): chezmoi git -- remote set-url origin "${CHEZMOI_REMOTE_TARGET}"

# Rotation flags (default: no rotation)
ROTATE_SSH=0
ROTATE_GPG=0

# ---------------------------------------------------------------------------
# usage
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Stage 2 credential bootstrap: generates and registers per-machine SSH and GPG
keypairs with GitHub, writes signingkey to chezmoi data, and rewrites the
chezmoi git remote to use the github-personal SSH alias.

Default behavior (no flags) is fully idempotent: if keys are already generated
and registered, the script is a no-op.

OPTIONS
  --rotate-ssh    Revoke existing local SSH key, generate a fresh ed25519 key,
                  and register it with GitHub.  Logs the old fingerprint to
                  stdout for manual removal via GitHub web UI or:
                    gh ssh-key delete <id>
  --rotate-gpg    Revoke existing local GPG key, generate a fresh Ed25519 key,
                  and register it with GitHub.  Logs the old key ID to stdout
                  for manual removal via GitHub web UI or:
                    gh gpg-key delete <id>
  --rotate-all    Equivalent to --rotate-ssh --rotate-gpg.
  -h, --help      Show this help and exit.

REQUIRED GITHUB SCOPES
  admin:public_key, admin:gpg_key, repo
  (Script launches 'gh auth login' automatically if scopes are missing.)

EXAMPLES
  # First-time setup
  ~/scripts/setup-credentials.sh

  # Safe re-run on an already-configured machine (no-op)
  ~/scripts/setup-credentials.sh

  # Rotate SSH key (e.g., after a suspected compromise)
  ~/scripts/setup-credentials.sh --rotate-ssh

  # Rotate both keypairs (e.g., decommissioning the old machine identity)
  ~/scripts/setup-credentials.sh --rotate-all

NOTES
  - Stale GitHub-side keys are NOT deleted automatically; the old fingerprint /
    key ID is printed so you can clean up manually.  See docs/credential-plane.md
    for the quarterly cleanup playbook.
  - VaultWarden (bw) is NOT used by this script.  Credential ops are fully local.
EOF
}

# ---------------------------------------------------------------------------
# Argument parser
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --rotate-ssh)  ROTATE_SSH=1 ;;
    --rotate-gpg)  ROTATE_GPG=1 ;;
    --rotate-all)  ROTATE_SSH=1; ROTATE_GPG=1 ;;
    -h|--help)     usage; exit 0 ;;
    *)
      printf 'Unknown argument: %s\n\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
preflight() {
  local missing=0
  local tools=(gh ssh-keygen gpg jq chezmoi)
  for tool in "${tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      printf '[preflight] MISSING: %s\n' "$tool" >&2
      case "$tool" in
        gh)        printf '  Install: brew install gh\n' >&2 ;;
        gpg)       printf '  Install: brew install gnupg\n' >&2 ;;
        jq)        printf '  Install: brew install jq\n' >&2 ;;
        chezmoi)   printf '  Install: brew install chezmoi\n' >&2 ;;
        ssh-keygen) printf '  Install: part of macOS OpenSSH (should be present)\n' >&2 ;;
      esac
      missing=1
    fi
  done
  if [[ "${missing}" == "1" ]]; then
    printf '\n[preflight] Stage 1 installs all required tools. Run:\n' >&2
    printf '  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply JamesTeague/dotfiles\n' >&2
    exit 1
  fi
}

preflight

# ---------------------------------------------------------------------------
# ensure_gh_auth — authenticate with GitHub and confirm required scopes
# ---------------------------------------------------------------------------
ensure_gh_auth() {
  printf '[auth] Checking GitHub authentication...\n'

  if gh auth status -h github.com >/dev/null 2>&1; then
    # Already authenticated — verify scopes
    local scope_output
    scope_output="$(gh auth status -h github.com 2>&1 | grep "Token scopes:")"

    local all_scopes_present=1
    for scope in "${REQUIRED_SCOPES[@]}"; do
      if ! printf '%s\n' "${scope_output}" | grep -qF "${scope}"; then
        all_scopes_present=0
        printf '[auth] Missing scope: %s\n' "${scope}"
      fi
    done

    if [[ "${all_scopes_present}" == "1" ]]; then
      printf '[auth] Already authenticated with required scopes — skipping login.\n'
      return 0
    fi

    printf '[auth] Existing token lacks required scopes. Re-authenticating...\n'
  else
    printf '[auth] Not authenticated with GitHub.\n'
  fi

  printf '[auth] Launching gh auth login (device flow).\n'
  printf '[auth] A code will be displayed — enter it at: https://github.com/login/device\n'

  local scope_str
  scope_str="$(IFS=,; printf '%s' "${REQUIRED_SCOPES[*]}")"

  if ! gh auth login \
       --hostname github.com \
       --git-protocol ssh \
       --web \
       -s "${scope_str}"; then
    printf '[auth] gh auth login failed or was interrupted.\n' >&2
    printf '[auth] Re-run this script when ready.\n' >&2
    exit 2
  fi

  printf '[auth] Authentication successful.\n'
}

# ---------------------------------------------------------------------------
# ssh_pubkey_registered — returns 0 if the given pubkey is already on GitHub
#
# Args: $1 = path to public key file (.pub)
# ---------------------------------------------------------------------------
ssh_pubkey_registered() {
  local pubkey_file="$1"

  # Extract local fingerprint
  local local_fp
  local_fp="$(ssh-keygen -lf "${pubkey_file}" 2>/dev/null | awk '{print $2}')"
  if [[ -z "${local_fp}" ]]; then
    return 1
  fi

  # Fetch registered keys, compute fingerprints, compare
  # Each registered key is a one-liner OpenSSH pubkey string
  # NB: `gh ssh-key list` is TSV only (no --json flag) — use `gh api user/keys` instead.
  local registered_fp
  # shellcheck disable=SC2016  # $pk is intentionally inside single-quotes for while-read
  registered_fp="$(gh api user/keys --jq '.[].key' 2>/dev/null \
    | while IFS= read -r pk; do
        printf '%s\n' "${pk}" | ssh-keygen -lf - 2>/dev/null | awk '{print $2}'
      done)"

  if printf '%s\n' "${registered_fp}" | grep -qFx "${local_fp}"; then
    return 0
  fi
  return 1
}

# ---------------------------------------------------------------------------
# setup_ssh — generate and register the per-machine ed25519 SSH key
# ---------------------------------------------------------------------------
setup_ssh() {
  printf '[ssh] Setting up personal SSH key...\n'

  # Rotation: log old fingerprint + delete local files before regenerating
  if [[ "${ROTATE_SSH}" == "1" ]] && [[ -f "${SSH_KEY}" ]]; then
    printf '[ssh] --rotate-ssh: old fingerprint (log for manual GitHub cleanup):\n'
    ssh-keygen -lf "${SSH_KEY}.pub" 2>/dev/null || true
    printf '[ssh] Removing old key files: %s  %s.pub\n' "${SSH_KEY}" "${SSH_KEY}"
    rm -f "${SSH_KEY}" "${SSH_KEY}.pub"
  fi

  # Generate key if missing
  if [[ ! -f "${SSH_KEY}" ]]; then
    printf '[ssh] Generating ed25519 key at %s (title: %s)...\n' "${SSH_KEY}" "${KEY_TITLE}"
    mkdir -p "${KEY_DIR}"
    chmod 700 "${KEY_DIR}"
    if ! ssh-keygen -t ed25519 -N "" -C "${KEY_TITLE}" -f "${SSH_KEY}"; then
      printf '[ssh] ssh-keygen failed.\n' >&2
      exit 3
    fi
    chmod 600 "${SSH_KEY}"
    chmod 644 "${SSH_KEY}.pub"
    printf '[ssh] Key generated.\n'
  else
    printf '[ssh] Key already exists at %s — checking registration.\n' "${SSH_KEY}"
  fi

  # Idempotent register (cli/cli#5085: gh ssh-key add is NOT idempotent)
  if ssh_pubkey_registered "${SSH_KEY}.pub"; then
    printf '[skip] SSH key already registered with GitHub.\n'
  else
    printf '[ssh] Registering SSH pubkey with GitHub (title: %s)...\n' "${KEY_TITLE}"
    if ! gh ssh-key add "${SSH_KEY}.pub" --title "${KEY_TITLE}" --type authentication 2>/tmp/ssh-add-stderr; then
      # Defense-in-depth: treat "already in use" as success
      if grep -qi "already in use\|key is already" /tmp/ssh-add-stderr; then
        printf '[ssh] Key already in use on GitHub — treating as registered.\n'
      else
        cat /tmp/ssh-add-stderr >&2
        printf '[ssh] gh ssh-key add failed. Register manually:\n' >&2
        printf '  gh ssh-key add %s.pub --title %s --type authentication\n' "${SSH_KEY}" "${KEY_TITLE}" >&2
        exit 3
      fi
    else
      printf '[ssh] SSH key registered successfully.\n'
    fi
  fi
}

# ---------------------------------------------------------------------------
# gpg_keyid_registered — returns 0 if the given long key ID is already on GitHub
#
# Args: $1 = long GPG key ID (16 hex chars)
# ---------------------------------------------------------------------------
gpg_keyid_registered() {
  local key_id="$1"

  # Fetch all registered key IDs and look for exact match
  # NB: `gh gpg-key list` is TSV only (no --json flag) — use `gh api user/gpg_keys` instead.
  local registered_ids
  registered_ids="$(gh api user/gpg_keys --jq '.[].key_id' 2>/dev/null || true)"

  if printf '%s\n' "${registered_ids}" | grep -qFx "${key_id}"; then
    return 0
  fi
  return 1
}

# ---------------------------------------------------------------------------
# setup_gpg — generate and register the per-machine EDDSA/Ed25519 GPG key
# ---------------------------------------------------------------------------
setup_gpg() {
  printf '[gpg] Setting up personal GPG key...\n'

  # Resolve email and name from chezmoi data
  local EMAIL NAME
  EMAIL="$(chezmoi data | jq -r '.email // empty' 2>/dev/null)"
  if [[ -z "${EMAIL}" ]]; then
    printf '[gpg] ERROR: chezmoi data .email is empty or absent. Run chezmoi init first.\n' >&2
    exit 4
  fi
  NAME="$(chezmoi data | jq -r '.name // empty' 2>/dev/null)"
  if [[ -z "${NAME}" ]]; then
    printf '[gpg] ERROR: chezmoi data .name is empty or absent. Run chezmoi init first.\n' >&2
    exit 4
  fi

  # Rotation: log existing key IDs, delete local copies
  if [[ "${ROTATE_GPG}" == "1" ]]; then
    printf '[gpg] --rotate-gpg: logging existing key IDs for manual GitHub cleanup:\n'
    local old_ids
    old_ids="$(gpg --list-secret-keys --keyid-format LONG --with-colons "${EMAIL}" 2>/dev/null \
      | awk -F: '/^sec:/ {print $5}')"
    if [[ -n "${old_ids}" ]]; then
      printf '%s\n' "${old_ids}" | while IFS= read -r oid; do
        printf '  old key ID: %s\n' "${oid}"
        # Best-effort local deletion; continue on error (agent state can lag)
        gpg --batch --yes --delete-secret-and-public-key "${oid}" 2>/dev/null || true
      done
    else
      printf '[gpg] No existing secret keys found for %s — nothing to rotate.\n' "${EMAIL}"
    fi
  fi

  # Check for an existing local key + already-registered idempotency path
  local EXISTING_KEYID
  EXISTING_KEYID="$(gpg --list-secret-keys --keyid-format LONG --with-colons "${EMAIL}" 2>/dev/null \
    | awk -F: '/^sec:/ {print $5; exit}')"

  if [[ -n "${EXISTING_KEYID}" ]] && gpg_keyid_registered "${EXISTING_KEYID}"; then
    printf '[skip] GPG key %s already exists locally and is registered with GitHub.\n' "${EXISTING_KEYID}"
    # Expose KEY_ID to write_signingkey
    KEY_ID="${EXISTING_KEYID}"
    return 0
  fi

  # Generate a new key via parameter file with %no-protection (Pitfall 1 mitigation)
  local PARAM_FILE
  PARAM_FILE="$(mktemp /tmp/gpg-param-XXXXXX)"
  cat > "${PARAM_FILE}" <<GPGEOF
%echo Generating per-machine GPG key (ed25519)
Key-Type: EDDSA
Key-Curve: Ed25519
Key-Usage: sign
Subkey-Type: ECDH
Subkey-Curve: Cv25519
Subkey-Usage: encrypt
Name-Real: ${NAME}
Name-Email: ${EMAIL}
Expire-Date: 0
%no-protection
%commit
%echo Done
GPGEOF

  printf '[gpg] Generating EDDSA/Ed25519 GPG key for %s <%s>...\n' "${NAME}" "${EMAIL}"
  if ! gpg --batch --gen-key "${PARAM_FILE}"; then
    printf '[gpg] gpg --batch --gen-key failed.\n' >&2
    rm -f "${PARAM_FILE}"
    exit 4
  fi
  rm -f "${PARAM_FILE}"

  # Re-resolve KEY_ID from colon output (machine-parseable, stable across gpg versions)
  KEY_ID="$(gpg --list-secret-keys --keyid-format LONG --with-colons "${EMAIL}" 2>/dev/null \
    | awk -F: '/^sec:/ {print $5; exit}')"

  if [[ -z "${KEY_ID}" ]]; then
    printf '[gpg] ERROR: key generated but could not resolve key ID from colon output.\n' >&2
    exit 4
  fi
  printf '[gpg] Key generated: %s\n' "${KEY_ID}"

  # Reload gpg-agent so current session sees the new key (Pitfall 8 mitigation)
  gpg-connect-agent reloadagent /bye >/dev/null 2>&1 || true

  # Idempotent register (cli/cli#5085: gh gpg-key add is NOT idempotent)
  if gpg_keyid_registered "${KEY_ID}"; then
    printf '[skip] GPG key %s already registered with GitHub.\n' "${KEY_ID}"
  else
    printf '[gpg] Registering GPG pubkey with GitHub (title: %s)...\n' "${KEY_TITLE}"
    # Armored format required per cli/cli#6528
    local gh_stderr
    gh_stderr="$(mktemp /tmp/gpg-gh-stderr-XXXXXX)"
    if ! gpg --armor --export "${KEY_ID}" | gh gpg-key add - --title "${KEY_TITLE}" 2>"${gh_stderr}"; then
      # Defense-in-depth: treat "already in use" as success
      if grep -qi "already in use\|key is already" "${gh_stderr}"; then
        printf '[gpg] Key already in use on GitHub — treating as registered.\n'
      else
        cat "${gh_stderr}" >&2
        printf '[gpg] gh gpg-key add failed. Register manually:\n' >&2
        printf '  gpg --armor --export %s | gh gpg-key add - --title %s\n' "${KEY_ID}" "${KEY_TITLE}" >&2
        rm -f "${gh_stderr}"
        exit 4
      fi
    else
      printf '[gpg] GPG key registered successfully.\n'
    fi
    rm -f "${gh_stderr}"
  fi
}

# ---------------------------------------------------------------------------
# write_signingkey — idempotently write signingkey to chezmoi.toml [data]
# ---------------------------------------------------------------------------
write_signingkey() {
  printf '[signingkey] Writing signingkey %s to chezmoi config...\n' "${KEY_ID}"

  if [[ ! -f "${CHEZMOI_CFG}" ]]; then
    printf '[signingkey] ERROR: %s does not exist. Run chezmoi init first.\n' "${CHEZMOI_CFG}" >&2
    exit 5
  fi

  if grep -qE '^\s*signingkey\s*=' "${CHEZMOI_CFG}"; then
    # Replace existing signingkey line (Pitfall 5 mitigation: in-place update)
    # shellcheck disable=SC2016  # single-quote is intentional: sed script, not shell expansion
    sed -i.bak "s|^[[:space:]]*signingkey[[:space:]]*=.*|  signingkey = \"${KEY_ID}\"|" "${CHEZMOI_CFG}"
    rm -f "${CHEZMOI_CFG}.bak"
    printf '[signingkey] Updated existing signingkey line.\n'
  else
    # Insert signingkey after [data] header (awk one-liner per 1-RESEARCH Example 6)
    awk -v kid="${KEY_ID}" '
      /^\[data\]/ { print; print "  signingkey = \"" kid "\""; next }
      { print }
    ' "${CHEZMOI_CFG}" > "${CHEZMOI_CFG}.new" && mv "${CHEZMOI_CFG}.new" "${CHEZMOI_CFG}"
    printf '[signingkey] Inserted signingkey under [data] section.\n'
  fi

  # Verify the write landed (post-write guard)
  local actual_key
  actual_key="$(chezmoi data | jq -r '.signingkey // empty' 2>/dev/null)"
  if [[ "${actual_key}" != "${KEY_ID}" ]]; then
    printf '[signingkey] ERROR: post-write verify failed. Expected: %s  Got: %s\n' "${KEY_ID}" "${actual_key}" >&2
    exit 5
  fi
  printf '[signingkey] Verified: chezmoi data .signingkey = %s\n' "${KEY_ID}"

  # Trigger immediate re-render of gitconfig.local (best-effort; next apply also covers this)
  if chezmoi apply "${HOME}/.gitconfig.local" 2>/dev/null; then
    printf '[signingkey] gitconfig.local re-rendered.\n'
  else
    printf '[signingkey] Warning: chezmoi apply ~/.gitconfig.local non-zero (will fix on next apply).\n'
  fi
}

# ---------------------------------------------------------------------------
# rewrite_remote — rewrite chezmoi git remote to use github-personal SSH alias
#
# MUST be the last step in main(), AFTER smoke-testing ssh -T github-personal.
# ---------------------------------------------------------------------------
rewrite_remote() {
  printf '[remote] Smoke-testing SSH auth via github-personal alias...\n'

  # ssh -T exits 1 by design; check the grep exit (PIPESTATUS[1]) not ssh exit
  # StrictHostKeyChecking=accept-new avoids interactive prompt on first connect
  # (Pitfall 7: remote rewrite before key registered would brick chezmoi git operations)
  local ssh_output
  ssh_output="$(ssh -o StrictHostKeyChecking=accept-new -T git@github-personal 2>&1 || true)"
  if ! printf '%s\n' "${ssh_output}" | grep -q "successfully authenticated"; then
    printf '[remote] ERROR: SSH auth via github-personal failed. Output:\n' >&2
    printf '%s\n' "${ssh_output}" >&2
    printf '[remote] Remote rewrite skipped. Ensure ~/.ssh/config has Host github-personal and key is registered.\n' >&2
    exit 6
  fi
  printf '[remote] SSH auth confirmed.\n'

  # Idempotent remote rewrite
  local CUR
  CUR="$(chezmoi git -- remote get-url origin 2>/dev/null || true)"
  if [[ "${CUR}" == "${CHEZMOI_REMOTE_TARGET}" ]]; then
    printf '[skip] chezmoi remote already set to %s\n' "${CHEZMOI_REMOTE_TARGET}"
  else
    printf '[remote] Rewriting chezmoi remote: %s → %s\n' "${CUR}" "${CHEZMOI_REMOTE_TARGET}"
    if ! chezmoi git -- remote set-url origin "${CHEZMOI_REMOTE_TARGET}"; then
      printf '[remote] ERROR: chezmoi git -- remote set-url failed.\n' >&2
      exit 6
    fi
    printf '[remote] Remote rewritten successfully.\n'
  fi
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  printf '=%.0s' {1..60}; printf '\n'
  printf 'setup-credentials.sh — Stage 2 bootstrap\n'
  printf 'Host: %s   Date: %s\n' "${HOSTNAME_SHORT}" "${TODAY}"
  printf '=%.0s' {1..60}; printf '\n'

  ensure_gh_auth
  setup_ssh
  setup_gpg
  write_signingkey
  rewrite_remote
  printf 'Stage 2 complete. Verify: git commit -S --allow-empty -m verify && git log --show-signature -1\n'
  exit 0
}

main "$@"
