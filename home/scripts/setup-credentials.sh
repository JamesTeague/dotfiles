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
  local registered_fp
  # shellcheck disable=SC2016  # $pk is intentionally inside single-quotes for while-read
  registered_fp="$(gh ssh-key list --json key --jq '.[].key' 2>/dev/null \
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
# main
# ---------------------------------------------------------------------------
main() {
  printf '=%.0s' {1..60}; printf '\n'
  printf 'setup-credentials.sh — Stage 2 bootstrap\n'
  printf 'Host: %s   Date: %s\n' "${HOSTNAME_SHORT}" "${TODAY}"
  printf '=%.0s' {1..60}; printf '\n'

  ensure_gh_auth
  setup_ssh
  # TODO(1-04b): setup_gpg
  # TODO(1-04b): write_signingkey
  # TODO(1-04b): rewrite_remote
  printf 'Stage 2 complete. Verify: git commit -S --allow-empty -m verify && git log --show-signature -1\n'
  exit 0
}

main "$@"
