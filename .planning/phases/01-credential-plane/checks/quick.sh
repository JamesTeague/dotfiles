#!/usr/bin/env bash
# .planning/phases/01-credential-plane/checks/quick.sh
#
# Fast structural gates for Phase 1 credential-plane requirements.
# Designed to run in <5s after each task commit.
#
# Default mode: missing Wave-1+ artifacts are PENDING (acceptable while phase
# is in flight). Strict mode (--strict / STRICT=1): PENDING becomes FAIL and
# produces non-zero exit. Use STRICT=1 to assert "expected RED pre-Wave-1".
#
# Gates covered:
#   SEC-02   bw/bitwarden-cli formula pin documented
#   SEC-05   generate-gpg-key.sh deleted; modify_dot_gitconfig.local rewritten
#   SEC-07   SSH config template with purpose-based Host aliases
#   SEC-08   setup-credentials.sh contains canonical remote-rewrite call
#   SEC-11   setup-credentials.sh exists, executable, NOT in .chezmoiscripts/
#   SEC-13   personal_ed25519 path referenced in setup-credentials.sh (presence)
#   SEC-15   Structural VaultWarden-independence (three-clause regex over *.tmpl)
#
# Usage:
#   bash quick.sh              # default — pending allowed
#   bash quick.sh --strict     # pending becomes fail (STRICT mode)
#   STRICT=1 bash quick.sh     # same via env var

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Parse args BEFORE sourcing lib so STRICT_MODE is correct at lib init.
for arg in "$@"; do
  case "${arg}" in
    --strict) export STRICT=1 ;;
    --help|-h)
      sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
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

# All assertions run from the repo root so relative paths in plan specs match.
if [[ -z "${REPO_ROOT}" ]]; then
  printf 'quick.sh: not in a git repo; cannot resolve REPO_ROOT\n' >&2
  exit 2
fi
cd "${REPO_ROOT}"

# ---------------------------------------------------------------------------
# Section 1: SEC-05 (a) — generate-gpg-key.sh DELETED (hard invariant)
# ---------------------------------------------------------------------------
header "SEC-05 (a) generate-gpg-key.sh deleted"
# Hard invariant once Plan 1-02 lands: this file must not exist.
assert_dir_missing_strict "${REPO_ROOT}/home/scripts/generate-gpg-key.sh"

# ---------------------------------------------------------------------------
# Section 2: SEC-05 (b) — modify_dot_gitconfig.local rewritten
# ---------------------------------------------------------------------------
header "SEC-05 (b) modify_dot_gitconfig.local rewritten"
assert_grep '\.signingkey' "${REPO_ROOT}/home/modify_dot_gitconfig.local"
assert_no_grep 'output.*generate-gpg-key' "${REPO_ROOT}/home/modify_dot_gitconfig.local"

# ---------------------------------------------------------------------------
# Section 3: SEC-07 — SSH config template with purpose aliases
# ---------------------------------------------------------------------------
header "SEC-07 SSH config template"
assert_file "${REPO_ROOT}/home/private_dot_ssh/config.tmpl"
assert_grep 'Host github-personal' "${REPO_ROOT}/home/private_dot_ssh/config.tmpl"
assert_grep 'IdentitiesOnly yes' "${REPO_ROOT}/home/private_dot_ssh/config.tmpl"

# ---------------------------------------------------------------------------
# Section 4: SEC-02 — bw formula pin documented
# ---------------------------------------------------------------------------
header "SEC-02 bw formula pin"
assert_grep 'bitwarden-cli' "${REPO_ROOT}/home/.chezmoidata/packages.yaml"
assert_grep 'PIN' "${REPO_ROOT}/home/.chezmoidata/packages.yaml"
assert_file "${REPO_ROOT}/docs/credential-plane.md"

# ---------------------------------------------------------------------------
# Section 5: SEC-08 — setup-credentials.sh rewrites chezmoi remote
# ---------------------------------------------------------------------------
header "SEC-08 setup-credentials.sh rewrites chezmoi remote"
assert_grep 'chezmoi git -- remote set-url origin' "${REPO_ROOT}/home/scripts/setup-credentials.sh"

# ---------------------------------------------------------------------------
# Section 6: SEC-11 — setup-credentials.sh exists, executable, NOT a chezmoi script
# ---------------------------------------------------------------------------
header "SEC-11 setup-credentials.sh distribution shape"
assert_file "${REPO_ROOT}/home/scripts/setup-credentials.sh"
if [[ -f "${REPO_ROOT}/home/scripts/setup-credentials.sh" ]]; then
  if [[ -x "${REPO_ROOT}/home/scripts/setup-credentials.sh" ]]; then
    pass "executable: home/scripts/setup-credentials.sh"
  else
    fail "not executable: home/scripts/setup-credentials.sh"
  fi
fi
# Must NOT exist in .chezmoiscripts/ (operator-invoked, not auto-run by chezmoi)
assert_cmd_zero_output bash -c "ls ${REPO_ROOT}/home/.chezmoiscripts/*setup-credentials* 2>/dev/null || true"

# ---------------------------------------------------------------------------
# Section 7: SEC-13 (presence) — ed25519 key path referenced in script
# ---------------------------------------------------------------------------
header "SEC-13 (presence) personal_ed25519 referenced in setup-credentials.sh"
assert_grep 'personal_ed25519' "${REPO_ROOT}/home/scripts/setup-credentials.sh"

# ---------------------------------------------------------------------------
# Section 8: SEC-15 — Structural VaultWarden-independence
#
# Canonical three-clause regex (load-bearing contract for Plans 1-02..1-05):
#   \bbw \b|bitwardenAttachment|\{\{ *bitwarden
#
# In single-quoted bash: '\bbw \b|bitwardenAttachment|\{\{ *bitwarden'
# All three clauses MUST be present. Dropping any clause violates SEC-15.
#
# Permitted exceptions NOT scanned here:
#   - home/.chezmoidata/packages.yaml (bitwarden cask + bitwarden-cli formula
#     are package install names, not template calls)
#   - home/scripts/setup-credentials.sh (design comments about bw may appear;
#     the script itself is Stage-2, not apply-time)
# ---------------------------------------------------------------------------
header "SEC-15 Structural VaultWarden-independence"

SEC15_REGEX='\bbw \b|bitwardenAttachment|\{\{ *bitwarden'

# Check all *.tmpl files under home/ (excluding packages.yaml and setup-credentials.sh)
tmpl_files_found=0
while IFS= read -r -d '' tmplfile; do
  # Skip packages.yaml (install names are OK)
  [[ "${tmplfile}" == *"packages.yaml"* ]] && continue
  # Skip setup-credentials.sh (design comments permitted)
  [[ "${tmplfile}" == *"setup-credentials.sh"* ]] && continue
  tmpl_files_found=1
  assert_no_grep "${SEC15_REGEX}" "${tmplfile}"
done < <(find "${REPO_ROOT}/home" -name '*.tmpl' -print0 2>/dev/null)

# Also check scripts under .chezmoiscripts/ (same three-clause regex)
while IFS= read -r -d '' scriptfile; do
  tmpl_files_found=1
  assert_no_grep "${SEC15_REGEX}" "${scriptfile}"
done < <(find "${REPO_ROOT}/home/.chezmoiscripts" -name '*.sh.tmpl' -print0 2>/dev/null)

if [[ "${tmpl_files_found}" == "0" ]]; then
  # No *.tmpl files found yet (pre-Wave-1 state is fine — scan finds nothing to assert)
  pass "SEC-15 structural check: no *.tmpl files found under home/ to scan (pre-Wave-1 state)"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
summary; exit $?
