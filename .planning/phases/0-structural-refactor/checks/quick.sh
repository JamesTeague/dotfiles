#!/usr/bin/env bash
# .planning/phases/0-structural-refactor/checks/quick.sh
#
# Per-task Phase 0 structural-refactor assertions. Runs in <5s after each task commit.
# Default mode: missing Wave-1+ artifacts are PENDING (acceptable while phase
# is in flight). Strict mode (--strict): missing artifacts FAIL.
#
# Assertions cover: TAX-01..06, TAX-08, SS-03, loud-fail guard,
# no-<no value> template-render assertions, cutover script existence.
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

if [[ -z "${REPO_ROOT}" ]]; then
  printf 'quick.sh: not in a git repo; cannot resolve REPO_ROOT\n' >&2
  exit 2
fi
cd "${REPO_ROOT}"

# ---------------------------------------------------------------------------
# Section 1: TAX-01/02 — chezmoi.toml.tmpl has role promptChoiceOnce
# ---------------------------------------------------------------------------
header "TAX-01/02 chezmoi.toml.tmpl role prompt"
assert_file home/.chezmoi.toml.tmpl
assert_grep 'promptChoiceOnce .* "role"' home/.chezmoi.toml.tmpl

# Pitfall 1 defense: no non-Once promptString in .chezmoi.toml.tmpl
if [[ -f home/.chezmoi.toml.tmpl ]]; then
  non_once=$(grep 'promptString' home/.chezmoi.toml.tmpl 2>/dev/null | grep -v 'Once' || true)
  if [[ -z "${non_once}" ]]; then
    pass "no non-Once promptString in chezmoi.toml.tmpl (Pitfall 1)"
  else
    fail "found non-Once promptString in chezmoi.toml.tmpl: ${non_once}"
  fi
fi

# ---------------------------------------------------------------------------
# Section 2: TAX-05 — packages.yaml new shape
# ---------------------------------------------------------------------------
header "TAX-05 packages.yaml restructure"
assert_file home/.chezmoidata/packages.yaml

if [[ -f home/.chezmoidata/packages.yaml ]]; then
  yaml_ok=""
  if command -v ruby >/dev/null 2>&1; then
    if ruby -ryaml -e '
      h = YAML.load_file(ARGV[0])
      raise "missing roles.dev.core"           unless h.dig("packages","roles","dev","core")
      raise "missing overlays.personal.darwin" unless h.dig("packages","overlays","personal","darwin")
      raise "missing overlays.work.darwin"     unless h.dig("packages","overlays","work","darwin")
    ' home/.chezmoidata/packages.yaml >/dev/null 2>&1; then
      yaml_ok="ruby"
    fi
  fi
  if [[ -z "${yaml_ok}" ]] && command -v python3 >/dev/null 2>&1; then
    if python3 -c "
import yaml
h = yaml.safe_load(open('home/.chezmoidata/packages.yaml'))
assert h.get('packages',{}).get('roles',{}).get('dev',{}).get('core')
assert h.get('packages',{}).get('overlays',{}).get('personal',{}).get('darwin')
assert h.get('packages',{}).get('overlays',{}).get('work',{}).get('darwin')
" >/dev/null 2>&1; then
      yaml_ok="python3+yaml"
    fi
  fi
  if [[ -n "${yaml_ok}" ]]; then
    pass "packages.yaml has new roles.dev.core + overlays shape (via ${yaml_ok})"
  elif command -v ruby >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1; then
    fail "packages.yaml does NOT have required new shape (roles.dev.core or overlays missing)"
  else
    pending "no YAML parser available (ruby or python3+yaml)"
  fi
fi

# ---------------------------------------------------------------------------
# Section 3: TAX-06 — .chezmoiignore is templated
# ---------------------------------------------------------------------------
header "TAX-06 .chezmoiignore templated"
assert_file home/.chezmoiignore
assert_grep '{{' home/.chezmoiignore
assert_grep '\.role' home/.chezmoiignore

# ---------------------------------------------------------------------------
# Section 4: Loud-fail guard — 02-install-packages.sh.tmpl
# ---------------------------------------------------------------------------
header "Loud-fail hasKey role guard"
assert_grep 'hasKey .*"role".*fail' home/.chezmoiscripts/run_onchange_before_02-install-packages.sh.tmpl

# ---------------------------------------------------------------------------
# Section 5: exact_bin teardown + private_dot_local/bin migration
# ---------------------------------------------------------------------------
header "exact_bin teardown + private_dot_local/bin migration"
assert_dir_missing_strict home/exact_bin
assert_file home/private_dot_local/bin/executable_dot.tmpl
assert_file home/private_dot_local/bin/executable_git-bare-clone
assert_file home/private_dot_local/bin/executable_git-wtf
assert_file home/private_dot_local/bin/executable_tmux-cht.sh
assert_file home/private_dot_local/bin/executable_tmux-sessionizer

# ---------------------------------------------------------------------------
# Section 6: SS-03 — flameshot config re-staged
# ---------------------------------------------------------------------------
header "SS-03 flameshot config re-staged"
assert_file home/private_dot_config/flameshot/flameshot.ini

# ---------------------------------------------------------------------------
# Section 7: SEC-05 (Phase 0 invariant) — generate-gpg-key.sh UNTOUCHED
# ---------------------------------------------------------------------------
header "SEC-05 generate-gpg-key.sh UNTOUCHED (deferred to Phase 1)"
assert_file home/scripts/generate-gpg-key.sh

# ---------------------------------------------------------------------------
# Section 8: TAX-08 — dot_topics.md (inherited from Phase 0.5)
# ---------------------------------------------------------------------------
header "TAX-08 docs/dot_topics.md"
assert_file docs/dot_topics.md

# ---------------------------------------------------------------------------
# Section 9: TAX-01 template render — role=dev in output, zero <no value>
# ---------------------------------------------------------------------------
header "TAX-01 template render (role=dev, no <no value>)"
if command -v chezmoi >/dev/null 2>&1 && [[ -f home/.chezmoi.toml.tmpl ]]; then
  render_out=$(chezmoi execute-template --init \
    --promptString name=t \
    --promptString email=t@t \
    --promptBool personal=true \
    --promptChoice role=dev \
    < home/.chezmoi.toml.tmpl 2>&1)
  if echo "${render_out}" | grep -q '^  role = "dev"$'; then
    pass "chezmoi.toml.tmpl renders role = \"dev\""
  else
    fail "chezmoi.toml.tmpl does NOT render role = \"dev\""
  fi
  no_val_count=$(echo "${render_out}" | grep -c '<no value>' || true)
  if [[ "${no_val_count}" == "0" ]]; then
    pass "zero <no value> in chezmoi.toml.tmpl render"
  else
    fail "<no value> found in chezmoi.toml.tmpl render (${no_val_count} occurrences)"
  fi
else
  pending "chezmoi not on PATH or chezmoi.toml.tmpl missing (cannot render)"
fi

# ---------------------------------------------------------------------------
# Section 10: Cutover script exists and is executable
# ---------------------------------------------------------------------------
header "Cutover script artifact"
assert_file .planning/phases/0-structural-refactor/cutover-phase-0.sh
if [[ -f .planning/phases/0-structural-refactor/cutover-phase-0.sh ]]; then
  if [[ -x .planning/phases/0-structural-refactor/cutover-phase-0.sh ]]; then
    pass "cutover-phase-0.sh is executable"
  else
    fail "cutover-phase-0.sh is NOT executable"
  fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
summary
