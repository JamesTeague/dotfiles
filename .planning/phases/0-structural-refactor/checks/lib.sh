# shellcheck shell=bash
# .planning/phases/00.5-audit-documentation/checks/lib.sh
#
# Shared verification helpers for Phase 0.5 audit checks.
#
# Sourceable only (no top-level execution beyond env derivation). Calling
# convention: source from quick.sh / full.sh, then invoke helpers. STRICT_MODE
# (set by caller via STRICT=1 env var or --strict flag) flips PENDING -> FAIL.
#
# Helpers:
#   header MSG                          - colored section banner
#   pass MSG                            - green check, increments PASS_COUNT
#   fail MSG                            - red X, increments FAIL_COUNT; in
#                                         STRICT mode also exits 1
#   pending MSG                         - yellow dot, increments PENDING_COUNT
#                                         (treated as FAIL in STRICT mode)
#   assert_file PATH                    - pass/pending/(strict-fail) on file
#   assert_dir_missing PATH             - pass if absent, pending/(strict-fail)
#                                         if present (parallel to assert_file:
#                                         "this artifact should have been
#                                         removed by Wave N — strict gates the
#                                         removal, default just notes it)
#   assert_dir_missing_strict PATH      - pass if absent, FAIL if present
#                                         (use for invariants, not Wave work)
#   assert_grep PATTERN PATH            - pass if grep -q matches; fail otherwise
#                                         (real fail — pattern missing in an
#                                         existing file is broken state)
#   assert_cmd_zero_output CMD...       - run CMD, capture stdout; pass if empty
#   summary                             - print PASS/PENDING/FAIL counts;
#                                         returns 1 if FAIL_COUNT > 0

# Sentinel guard: prevent double-load side effects.
if [[ -n "${LIB_SH_LOADED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
LIB_SH_LOADED=1

# ---------------------------------------------------------------------------
# Env derivation
# ---------------------------------------------------------------------------

# REPO_ROOT: git toplevel. If git missing or not in a repo, leave empty so
# downstream checks can fail/pend gracefully rather than blowing up on `cd`.
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"

# CHEZMOI_SOURCE_ROOT: empty when chezmoi missing. Downstream checks that need
# chezmoi (template render, diff) should pending in that case.
CHEZMOI_SOURCE_ROOT="$(chezmoi source-path 2>/dev/null || true)"

# STRICT_MODE: 1 when caller exported STRICT=1 OR passed --strict (caller is
# responsible for setting STRICT=1 before sourcing this lib when --strict is
# parsed from argv).
STRICT_MODE=0
if [[ "${STRICT:-0}" == "1" ]]; then
  STRICT_MODE=1
fi

# Counters
PASS_COUNT=0
FAIL_COUNT=0
PENDING_COUNT=0

# ANSI color (skip when not a TTY)
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'
  C_GREEN=$'\033[32m'
  C_RED=$'\033[31m'
  C_YELLOW=$'\033[33m'
  C_BOLD=$'\033[1m'
else
  C_RESET=''
  C_GREEN=''
  C_RED=''
  C_YELLOW=''
  C_BOLD=''
fi

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

header() {
  local msg="$1"
  printf '\n%s== %s ==%s\n' "${C_BOLD}" "${msg}" "${C_RESET}"
}

pass() {
  local msg="$1"
  printf '  %s✓%s %s\n' "${C_GREEN}" "${C_RESET}" "${msg}"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  local msg="$1"
  printf '  %s✗%s %s\n' "${C_RED}" "${C_RESET}" "${msg}"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  if [[ "${STRICT_MODE}" == "1" ]]; then
    # In strict mode a single failure terminates the run.
    summary >&2
    exit 1
  fi
}

pending() {
  local msg="$1"
  if [[ "${STRICT_MODE}" == "1" ]]; then
    fail "PENDING in strict mode: ${msg}"
    return
  fi
  printf '  %s·%s %s%s%s\n' "${C_YELLOW}" "${C_RESET}" "${C_YELLOW}" "${msg}" "${C_RESET}"
  PENDING_COUNT=$((PENDING_COUNT + 1))
}

# ---------------------------------------------------------------------------
# Assertion helpers
# ---------------------------------------------------------------------------

assert_file() {
  local path="$1"
  if [[ -f "${path}" ]]; then
    pass "file exists: ${path}"
  else
    pending "missing file: ${path}"
  fi
}

assert_dir_missing() {
  local path="$1"
  if [[ ! -e "${path}" ]]; then
    pass "directory absent: ${path}"
  else
    # Same pending/strict semantics as assert_file: this is wave-staged work
    # ("removed by Plan 04") not a hard invariant.
    pending "directory still present (not yet removed): ${path}"
  fi
}

# Strict variant — use when "directory absent" is a HARD invariant, not
# in-flight cleanup. Not currently used in Phase 0.5 but kept for symmetry.
assert_dir_missing_strict() {
  local path="$1"
  if [[ ! -e "${path}" ]]; then
    pass "directory absent: ${path}"
  else
    fail "directory still present: ${path}"
  fi
}

assert_grep() {
  local pattern="$1"
  local path="$2"
  if [[ ! -f "${path}" ]]; then
    # File missing is pending, not fail — same as assert_file. Lets the
    # pre-existence check govern.
    pending "missing file (cannot grep): ${path}"
    return
  fi
  if grep -q -- "${pattern}" "${path}"; then
    pass "grep '${pattern}' in ${path}"
  else
    # File exists but pattern missing is real broken state.
    fail "grep '${pattern}' NOT in ${path}"
  fi
}

# Run a command, capture stdout, pass iff empty. Used for invariants framed as
# "this query should return no rows" (e.g., git ls-files filters, chezmoi diff).
assert_cmd_zero_output() {
  local out
  if ! out="$("$@" 2>&1)"; then
    fail "command failed: $*"
    return
  fi
  if [[ -z "${out}" ]]; then
    pass "zero output: $*"
  else
    fail "non-empty output from: $*"
    # Indent the offending output so it's obvious it's part of the failure.
    printf '%s\n' "${out}" | sed 's/^/      | /'
  fi
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

summary() {
  printf '\n%s== Summary ==%s\n' "${C_BOLD}" "${C_RESET}"
  printf '  %sPASS%s    : %d\n' "${C_GREEN}"  "${C_RESET}" "${PASS_COUNT}"
  printf '  %sPENDING%s : %d\n' "${C_YELLOW}" "${C_RESET}" "${PENDING_COUNT}"
  printf '  %sFAIL%s    : %d\n' "${C_RED}"    "${C_RESET}" "${FAIL_COUNT}"
  if (( FAIL_COUNT > 0 )); then
    return 1
  fi
  return 0
}
