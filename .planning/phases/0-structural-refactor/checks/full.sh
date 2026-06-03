#!/usr/bin/env bash
# .planning/phases/0-structural-refactor/checks/full.sh
#
# Full Wave 0 gate for Phase 0 structural-refactor. Runs quick.sh first (unless
# --no-quick), then adds fixture-scenario template renders (~15s total).
#
# Flags:
#   --no-diff-gate   Skip chezmoi diff -x externals (operator-driven; use in
#                    harness/CI context where machine state is unknown)
#   --no-quick       Skip quick.sh and run full-only assertions only
#   --strict         Pass --strict to quick.sh + treat pending as fail here too
#
# Usage:
#   bash full.sh                   # all checks including diff gate
#   bash full.sh --no-diff-gate    # skip diff gate (harness/CI use)
#   bash full.sh --no-quick        # skip quick.sh, run full-only
#   bash full.sh --strict --no-diff-gate   # strict mode without diff gate

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"

NO_DIFF_GATE=0
NO_QUICK=0
STRICT_FLAG=""

for arg in "$@"; do
  case "${arg}" in
    --no-diff-gate) NO_DIFF_GATE=1 ;;
    --no-quick)     NO_QUICK=1 ;;
    --strict)       STRICT_FLAG="--strict" ; export STRICT=1 ;;
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

# Source lib for full-only assertions.
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

if [[ -z "${REPO_ROOT}" ]]; then
  printf 'full.sh: not in a git repo; cannot resolve REPO_ROOT\n' >&2
  exit 2
fi
cd "${REPO_ROOT}"

# ---------------------------------------------------------------------------
# Step 1: Run quick.sh (unless --no-quick)
# ---------------------------------------------------------------------------
if [[ "${NO_QUICK}" == "0" ]]; then
  printf '\n%s=== Running quick.sh ===%s\n' "${C_BOLD:-}" "${C_RESET:-}"
  if ! bash "${SCRIPT_DIR}/quick.sh" ${STRICT_FLAG}; then
    printf '\nquick.sh FAILED — stopping full.sh\n' >&2
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# Step 2: Fixture-scenario template renders
#
# For each fixture in checks/fixtures/role-dev-*.env:
#   - Source the fixture's PROMPT_* env vars
#   - Render chezmoi.toml.tmpl
#   - Render brew template
#   - Assert zero <no value> in both
#   - Assert brew render has at least one tap/brew/cask line
# ---------------------------------------------------------------------------
header "Fixture-scenario template renders"

FIXTURE_DIR="${SCRIPT_DIR}/fixtures"
if [[ ! -d "${FIXTURE_DIR}" ]]; then
  pending "fixture directory missing: ${FIXTURE_DIR}"
else
  for fixture in "${FIXTURE_DIR}"/role-dev-*.env; do
    [[ -e "${fixture}" ]] || continue
    scenario="$(basename "${fixture}" .env)"

    # Source fixture, but only PROMPT_* vars to avoid polluting env.
    PROMPT_NAME=""
    PROMPT_EMAIL=""
    PROMPT_PERSONAL=""
    PROMPT_ROLE=""
    # shellcheck disable=SC1090
    source "${fixture}"

    tmpfile_toml="/tmp/cm-toml-render-$$-${scenario}"
    tmpfile_brew="/tmp/cm-brew-render-$$-${scenario}"

    # Render chezmoi.toml.tmpl
    if chezmoi execute-template --init \
        --promptString "name=${PROMPT_NAME}" \
        --promptString "email=${PROMPT_EMAIL}" \
        --promptBool   "personal=${PROMPT_PERSONAL}" \
        --promptChoice "role=${PROMPT_ROLE}" \
        < home/.chezmoi.toml.tmpl > "${tmpfile_toml}" 2>&1; then

      toml_no_val=$(grep -c '<no value>' "${tmpfile_toml}" || true)
      if [[ "${toml_no_val}" == "0" ]]; then
        pass "[${scenario}] chezmoi.toml.tmpl: zero <no value>"
      else
        fail "[${scenario}] chezmoi.toml.tmpl: ${toml_no_val} <no value> occurrence(s)"
      fi
    else
      fail "[${scenario}] chezmoi execute-template failed for chezmoi.toml.tmpl"
    fi

    # Render brew template
    if chezmoi execute-template \
        < home/.chezmoitemplates/brew > "${tmpfile_brew}" 2>&1; then

      brew_no_val=$(grep -c '<no value>' "${tmpfile_brew}" || true)
      if [[ "${brew_no_val}" == "0" ]]; then
        pass "[${scenario}] brew template: zero <no value>"
      else
        fail "[${scenario}] brew template: ${brew_no_val} <no value> occurrence(s)"
      fi

      brew_lines=$(grep -cE '^(tap|brew|cask) ' "${tmpfile_brew}" || true)
      if [[ "${brew_lines}" -gt "0" ]]; then
        pass "[${scenario}] brew template: ${brew_lines} tap/brew/cask line(s)"
      else
        fail "[${scenario}] brew template: no tap/brew/cask lines found"
      fi
    else
      fail "[${scenario}] chezmoi execute-template failed for brew template"
    fi

    rm -f "${tmpfile_toml}" "${tmpfile_brew}"
  done
fi

# ---------------------------------------------------------------------------
# Step 3: chezmoi diff gate (skip with --no-diff-gate)
#
# Operator-driven per machine; typically run AFTER cutover script. Use
# --no-diff-gate in harness/CI where machine destination state is unknown.
# ---------------------------------------------------------------------------
header "chezmoi diff gate (TAX-07 merge gate)"
if [[ "${NO_DIFF_GATE}" == "1" ]]; then
  pending "diff gate skipped (--no-diff-gate)"
else
  if command -v chezmoi >/dev/null 2>&1; then
    diff_out=$(chezmoi diff -x externals 2>&1)
    if [[ -z "${diff_out}" ]]; then
      pass "chezmoi diff -x externals: empty (no drift)"
    else
      fail "chezmoi diff -x externals: non-empty output"
      printf '%s\n' "${diff_out}" | sed 's/^/      | /'
    fi
  else
    pending "chezmoi not on PATH"
  fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
summary
