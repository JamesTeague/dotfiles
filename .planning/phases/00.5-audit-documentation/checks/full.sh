#!/usr/bin/env bash
# .planning/phases/00.5-audit-documentation/checks/full.sh
#
# Wave-merge gate for Phase 0.5. Steps:
#   1. quick.sh --strict          (PENDING -> FAIL)
#   2. git LF index invariant     (no .tmpl files stored CRLF/mixed)
#   3. chezmoi diff -x externals  (zero output)
#   4. chezmoi execute-template   (renders the brew bundle script)
#   5. diff against approved snapshot (if present; pending if not)
#
# Flags:
#   --no-diff-gate   skip step 3 (Wave 1 use — pre-existing source drift is
#                    Plan 06's territory, not a Wave 1 blocker)
#   --no-quick       skip step 1 (debugging chezmoi-side in isolation)
#
# Exits 0 iff every section passes.
#
# NOTE (Pitfall B): RIGHT NOW on Mac personal, `chezmoi diff -x externals`
# shows a real DEBUG=1 drift in .zshrc that Plan 06 will reconcile. full.sh
# WILL fail step 3 on Mac personal until then — correct behavior, the gate is
# load-bearing.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"

RUN_QUICK=1
RUN_DIFF_GATE=1
for arg in "$@"; do
  case "${arg}" in
    --no-quick)     RUN_QUICK=0 ;;
    --no-diff-gate) RUN_DIFF_GATE=0 ;;
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

# Source lib for our own header/pass/fail/summary in the wrapper sections.
# (Note: this is a DIFFERENT process from quick.sh — counters here are local
# to full.sh's wrapper checks. Step 1 inherits quick.sh's own summary.)
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

if [[ -z "${REPO_ROOT}" ]]; then
  printf 'full.sh: not in a git repo; cannot resolve REPO_ROOT\n' >&2
  exit 2
fi
cd "${REPO_ROOT}"

# ---------------------------------------------------------------------------
# Step 1: quick.sh --strict
# ---------------------------------------------------------------------------
if (( RUN_QUICK )); then
  header "[1/5] quick.sh --strict"
  if bash "${SCRIPT_DIR}/quick.sh" --strict; then
    pass "quick.sh strict mode passed"
  else
    fail "quick.sh strict mode failed"
  fi
else
  header "[1/5] quick.sh --strict  (SKIPPED via --no-quick)"
fi

# ---------------------------------------------------------------------------
# Step 2: git LF invariant on .tmpl files
# ---------------------------------------------------------------------------
header "[2/5] git LF invariant on home/**/*.tmpl"
# Anything not 'i/lf' is wrong (crlf, mixed, -text on a .tmpl file all qualify).
assert_cmd_zero_output bash -c "git ls-files --eol -- 'home/**/*.tmpl' | grep -v 'i/lf' || true"

# ---------------------------------------------------------------------------
# Step 3: chezmoi diff -x externals
# ---------------------------------------------------------------------------
if (( RUN_DIFF_GATE )); then
  header "[3/5] chezmoi diff -x externals"
  if command -v chezmoi >/dev/null 2>&1; then
    assert_cmd_zero_output chezmoi diff -x externals
  else
    pending "chezmoi not on PATH"
  fi
else
  header "[3/5] chezmoi diff -x externals  (SKIPPED via --no-diff-gate)"
fi

# ---------------------------------------------------------------------------
# Step 4: chezmoi execute-template renders the brew bundle script
# ---------------------------------------------------------------------------
header "[4/5] chezmoi execute-template (brew bundle render)"
BREW_TMPL="home/.chezmoiscripts/run_onchange_before_02-install-packages.sh.tmpl"
RENDERED="/tmp/00.5-rendered-brew.txt"
if [[ ! -f "${BREW_TMPL}" ]]; then
  fail "missing template: ${BREW_TMPL}"
elif ! command -v chezmoi >/dev/null 2>&1; then
  pending "chezmoi not on PATH (cannot render)"
else
  if chezmoi execute-template < "${BREW_TMPL}" > "${RENDERED}" 2>/dev/null; then
    pass "rendered to ${RENDERED}"
  else
    fail "chezmoi execute-template failed on ${BREW_TMPL}"
  fi
fi

# ---------------------------------------------------------------------------
# Step 5: diff against approved snapshot (if exists)
# ---------------------------------------------------------------------------
header "[5/5] approved brew bundle snapshot diff"
APPROVED="${SCRIPT_DIR}/approved-brew-bundle.txt"
if [[ -f "${APPROVED}" && -f "${RENDERED}" ]]; then
  assert_cmd_zero_output diff "${RENDERED}" "${APPROVED}"
elif [[ ! -f "${APPROVED}" ]]; then
  pending "approved snapshot not yet generated (Plan 05 creates it)"
else
  pending "rendered output missing (step 4 did not run)"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
summary
