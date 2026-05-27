#!/usr/bin/env bash
# .planning/phases/00.5-audit-documentation/checks/quick.sh
#
# Per-task Phase 0.5 assertions. Designed to run in <5s after each task commit.
# Default mode: missing Wave-1+ artifacts are PENDING (acceptable while phase
# is in flight). Strict mode (--strict): missing artifacts FAIL — used by
# full.sh as the wave-merge gate.
#
# Usage:
#   bash quick.sh              # default — pending allowed
#   bash quick.sh --strict     # pending becomes fail

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"

# Parse args BEFORE sourcing lib so STRICT_MODE is correct at lib init.
for arg in "$@"; do
  case "${arg}" in
    --strict) export STRICT=1 ;;
    --help|-h)
      sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
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

# All assertions run from the repo root so the relative paths in the plan
# specs match what we're checking.
if [[ -z "${REPO_ROOT}" ]]; then
  printf 'quick.sh: not in a git repo; cannot resolve REPO_ROOT\n' >&2
  exit 2
fi
cd "${REPO_ROOT}"

# ---------------------------------------------------------------------------
# Section 1: AUD-04 — .gitattributes
# ---------------------------------------------------------------------------
header "AUD-04 .gitattributes"
assert_file .gitattributes
assert_grep '\*\.tmpl text eol=lf' .gitattributes

# ---------------------------------------------------------------------------
# Section 2: AUD-05 — docs
# ---------------------------------------------------------------------------
header "AUD-05 docs"
assert_file docs/conventions.md
assert_file docs/dot_topics.md
assert_grep 'chezmoiroot' docs/conventions.md
assert_grep 'dot_topics'  docs/dot_topics.md

# ---------------------------------------------------------------------------
# Section 3: AUD-03 — flameshot orphan
# ---------------------------------------------------------------------------
header "AUD-03 flameshot orphan"
assert_dir_missing home/private_dot_config/flameshot

# ---------------------------------------------------------------------------
# Section 4: AUD-01/02 — packages.yaml
# ---------------------------------------------------------------------------
header "AUD-01/02 packages.yaml"
if [[ -f home/.chezmoidata/packages.yaml ]]; then
  # Use whatever YAML parser is on-hand. Mac personal: system ruby (always
  # ships YAML stdlib). Fallback: python3+yaml (works on systems that pip3
  # installed PyYAML — not Mac personal as of 2026-05-27). If neither is
  # available we pend rather than fail (lack of parser != broken yaml).
  yaml_ok=""
  if command -v ruby >/dev/null 2>&1; then
    if ruby -ryaml -e 'YAML.load_file(ARGV[0])' home/.chezmoidata/packages.yaml >/dev/null 2>&1; then
      yaml_ok="ruby"
    fi
  fi
  if [[ -z "${yaml_ok}" ]] && command -v python3 >/dev/null 2>&1; then
    if python3 -c 'import yaml; yaml.safe_load(open("home/.chezmoidata/packages.yaml"))' >/dev/null 2>&1; then
      yaml_ok="python3+yaml"
    fi
  fi
  if [[ -n "${yaml_ok}" ]]; then
    pass "packages.yaml is valid YAML (via ${yaml_ok})"
  elif command -v ruby >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1; then
    fail "packages.yaml is NOT valid YAML"
  else
    pending "no YAML parser available (ruby or python3+yaml)"
  fi
  assert_grep 'shottr' home/.chezmoidata/packages.yaml
else
  fail "home/.chezmoidata/packages.yaml is missing"
fi

# ---------------------------------------------------------------------------
# Section 5: SS-01 — Shottr installed on Mac personal
# ---------------------------------------------------------------------------
header "SS-01 Shottr install"
if [[ "$(uname -s)" != "Darwin" ]]; then
  pending "skipped (not Darwin)"
else
  if command -v brew >/dev/null 2>&1; then
    if brew list --cask 2>/dev/null | grep -q '^shottr$'; then
      pass "shottr installed via brew --cask"
    else
      fail "shottr NOT installed via brew --cask"
    fi
  else
    pending "brew not on PATH"
  fi
fi

# ---------------------------------------------------------------------------
# Section 6: Wave 0 scaffolds
# ---------------------------------------------------------------------------
header "Wave 0 scaffolds"
assert_file .planning/phases/00.5-audit-documentation/00.5-packages-candidates.md
assert_file .planning/phases/00.5-audit-documentation/00.5-state-preview.md

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
summary
