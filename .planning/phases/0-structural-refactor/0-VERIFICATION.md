---
phase: 0-structural-refactor
verified: 2026-06-03T00:00:00Z
status: human_needed
score: 13/13 automated must-haves verified
human_verification:
  - test: "Run `bash .planning/phases/0-structural-refactor/cutover-phase-0.sh` on Mac personal (answer `dev` to role prompt). Verify chezmoi init --apply completes, role persists in ~/.config/chezmoi/chezmoi.toml, no re-prompt on subsequent `chezmoi apply`."
    expected: "role = \"dev\" present in ~/.config/chezmoi/chezmoi.toml; no prompt on second apply"
    why_human: "promptChoiceOnce persistence requires an actual on-machine init run; cannot simulate with execute-template --init"
  - test: "Run `chezmoi apply --dry-run --verbose 2>&1 | grep 'no value'` on both Mac personal and Mac work after cutover."
    expected: "Empty output (zero <no value> strings) on both machines"
    why_human: "Dry-run against live machine state (real chezmoi.toml data) vs. fixture data — machine-specific paths, existing entryState, live role/personal values"
  - test: "Run `chezmoi diff -x externals` on both Mac personal and Mac work after cutover."
    expected: "Empty output on both machines (TAX-07 merge gate)"
    why_human: "Requires actual on-machine chezmoi state vs. destination filesystem; exact_bin teardown (~/bin/ removal + entryState cleanup) is part of the cutover script and cannot be verified without running it"
  - test: "On Mac personal: verify ~/bin/ is gone AND ~/.local/bin/ has the 5 utilities (dot, git-bare-clone, git-wtf, tmux-cht.sh, tmux-sessionizer). Run `ls ~/bin/ 2>/dev/null` (should fail) and `ls ~/.local/bin/`."
    expected: "~/bin/ absent; ~/.local/bin/ contains 5 executables"
    why_human: "exact_bin teardown (rm -rf ~/bin/ + state delete) is operator-driven in cutover script step 6; source-tree move alone does not remove ~/bin/ (Pitfall C confirmed on both chezmoi versions)"
  - test: "On Mac work: verify NODE_EXTRA_CA_CERTS line migrated from ~/.zshrc to ~/.localrc (cutover script step 4 autodetect)."
    expected: "~/.localrc contains NODE_EXTRA_CA_CERTS line; ~/.zshrc does not"
    why_human: "Autodetect + sed-delete is operator-driven migration in cutover script; requires Mac work machine access"
  - test: "On Mac personal: run `chezmoi init --apply` a SECOND time (role already persisted). Verify role prompt does NOT fire again."
    expected: "chezmoi init --apply completes silently on role (promptChoiceOnce returns persisted value)"
    why_human: "Once-only behavior requires a second init run on the same machine with ~/.config/chezmoi/chezmoi.toml already containing role"
---

# Phase 0: Structural Refactor Verification Report

**Phase Goal:** The `role × personal × os × wsl` taxonomy lands atomically on a branch with no functional change on currently-active Mac machines. `generate-gpg-key.sh` is DELETED (not renamed). Per-machine cutover ritual is documented.

**Goal amendments applied (from 0-CONTEXT.md — supersede original SC):**
1. SC #5 (delete generate-gpg-key.sh) DEFERRED to Phase 1 — script is load-bearing via `home/modify_dot_gitconfig.local:6`. Phase 0 must PRESERVE it.
2. SC #2 (.chezmoiignore single gating point) reframed to FILE PRESENCE only.
3. ADD `.localrc` + `~/.local/bin/` employer-local pattern docs (resolves 0.5 follow-ups #6 + #9).

**Verified:** 2026-06-03
**Status:** human_needed — all 13 automated must-haves pass; 6 items require operator-driven cutover execution
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `role` is `promptChoiceOnce` with dev/gaming/lite options, default dev | VERIFIED | `grep promptChoiceOnce home/.chezmoi.toml.tmpl` → `{{ $role := promptChoiceOnce . "role" "Machine role" (list "dev" "gaming" "lite") "dev" }}` |
| 2 | All prompts in `.chezmoi.toml.tmpl` remain `*Once` variants | VERIFIED | `grep promptString home/.chezmoi.toml.tmpl | grep -v Once` returns empty |
| 3 | `packages.yaml` has new `roles.{dev}.<os>` + `overlays.{personal,work}.<os>` shape | VERIFIED | Ruby structural check: `roles.dev.core: PRESENT`, `overlays.personal.darwin: PRESENT`, `overlays.work.darwin: PRESENT` |
| 4 | `brew` template consumes new packages shape with `hasKey` guards | VERIFIED | `grep .packages.roles home/.chezmoitemplates/brew` shows `roles.dev.core.taps`, `roles.dev.darwin`, `roles.dev.linux` traversals with `hasKey` at every overlay path |
| 5 | `02-install-packages.sh.tmpl` has loud-fail `hasKey "role"` guard | VERIFIED | `grep 'hasKey.*role.*fail' home/.chezmoiscripts/run_onchange_before_02-install-packages.sh.tmpl` → `{{ if not (hasKey . "role") }}{{ fail "Role not set. Run: chezmoi init --apply" }}{{ end }}` |
| 6 | `.chezmoiignore` is templated and gates aerospace + flameshot + darwin-configure + 03-mas by os/role/wsl | VERIFIED | Contains 4 `{{` blocks; gates `aerospace`, `flameshot`, `darwin-configure`, `03-mas`; preserves `.oh-my-zsh/cache/**` |
| 7 | `home/exact_bin/` DELETED; 5 utilities at `home/private_dot_local/bin/` | VERIFIED | `test ! -d home/exact_bin` passes; all 5 `executable_*` files confirmed present at `home/private_dot_local/bin/` |
| 8 | `home/private_dot_config/flameshot/flameshot.ini` restored from 0.5 baseline | VERIFIED | File present; gated by `.chezmoiignore` linux+not-wsl+dev gate |
| 9 | `home/scripts/generate-gpg-key.sh` PRESERVED (goal amendment #1) | VERIFIED | `test -f home/scripts/generate-gpg-key.sh` passes; `home/modify_dot_gitconfig.local` still references it via `$scriptPath` |
| 10 | `cutover-phase-0.sh` committed as executable artifact | VERIFIED | Present at `.planning/phases/0-structural-refactor/cutover-phase-0.sh`; executable; `set -euo pipefail`; space-separated `--key /path` form used (follow-up #7) |
| 11 | `03-mas.sh.tmpl` has `/Applications/<App>.app` pre-check guard | VERIFIED | Contains `dig "name"`, `dig "id"`, `/Applications/${app_name}.app`, `Skipping mas install`; `{{ if .personal }}` body guard; outer darwin/wsl gate in `.chezmoiignore` |
| 12 | `docs/conventions.md` § 10 contains all required patterns | VERIFIED | `.localrc` + `~/.local/bin/` pattern: PRESENT; NO Linux Homebrew / LNX-05: PRESENT; `generate-gpg-key.sh` deferred: PRESENT; FILE PRESENCE reframe: PRESENT; follow-ups #1/#2/#3/#5/#8 (state dump, dry-run nonzero, mas list, state-forge, Pitfall C): PRESENT |
| 13 | `docs/dot_topics.md` exists with `dot_topics` convention (TAX-08) | VERIFIED | File present; `grep -q "dot_topics" docs/dot_topics.md` passes |

**Score:** 13/13 automated truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `home/.chezmoi.toml.tmpl` | `promptChoiceOnce` for role; `*Once` for all prompts | VERIFIED | 17 lines; contains `promptChoiceOnce`; no non-`Once` `promptString` |
| `home/.chezmoidata/packages.yaml` | `packages.roles.dev.{core,darwin,linux}` + `packages.overlays.{personal,work}.darwin` | VERIFIED | 119 lines; Ruby structural check passes; `mas` entries have `name:` + `id:` keys |
| `home/.chezmoiignore` | Templated; 5 gates (oh-my-zsh cache, 3 darwin, 1 flameshot) | VERIFIED | 14 lines; `{{` present; all 5 gate targets confirmed |
| `home/.chezmoitemplates/brew` | Consumes new shape; `hasKey` guards; 4 Linux bug fixes | VERIFIED | 112 lines; traverses `.packages.roles` and `.packages.overlays`; `hasKey` at every overlay; Linux loops emit `brew`/`cask` keywords correctly |
| `home/.chezmoiscripts/run_onchange_before_02-install-packages.sh.tmpl` | `hasKey "role"` loud-fail guard; `{{ template "brew" . }}` include | VERIFIED | 26 lines; guard and template include both present |
| `home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl` | `/Applications/` pre-check; `dig "name"`/`dig "id"`; `{{ if .personal }}`; no darwin/wsl gate in body | VERIFIED | 11 lines; all required patterns present; no `.chezmoi.os.*darwin` in body |
| `home/private_dot_local/bin/` (5 utilities) | `executable_dot.tmpl`, `executable_git-bare-clone`, `executable_git-wtf`, `executable_tmux-cht.sh`, `executable_tmux-sessionizer` | VERIFIED | All 5 files present with `executable_` prefix preserved |
| `home/private_dot_config/flameshot/flameshot.ini` | Restored verbatim from 0.5 baseline | VERIFIED | Present; gated by `.chezmoiignore` on darwin (chezmoi managed shows 0 flameshot entries) |
| `home/scripts/generate-gpg-key.sh` | MUST EXIST (Phase 0 amendment #1) | VERIFIED | Present; `home/modify_dot_gitconfig.local` references it as load-bearing modify-template |
| `.planning/phases/0-structural-refactor/cutover-phase-0.sh` | Executable; 8-step sequence; `set -euo pipefail`; space-separated `--key /path` | VERIFIED | Executable; all structural checks pass; `--key=` form absent (follow-up #7 compliance) |
| `docs/conventions.md` | § 10 with LNX-05, `.localrc` pattern, goal amendments, 5 follow-up notes | VERIFIED | All required content confirmed by grep |
| `docs/dot_topics.md` | TAX-08 inherited from Phase 0.5 | VERIFIED | Present with `dot_topics` convention text |
| `.planning/phases/0-structural-refactor/checks/{lib,quick,full}.sh` | Wave 0 harness; 23/23 PASS on quick.sh | VERIFIED | `quick.sh`: 23 PASS, 0 FAIL; `full.sh --no-diff-gate`: 9 PASS, 0 FAIL, 1 PENDING (diff gate intentionally skipped) |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `02-install-packages.sh.tmpl` | `home/.chezmoitemplates/brew` | `{{ template "brew" . }}` include | WIRED | `grep 'template "brew"' home/.chezmoiscripts/run_onchange_before_02-install-packages.sh.tmpl` confirms include |
| `home/.chezmoitemplates/brew` | `home/.chezmoidata/packages.yaml` | `.packages.roles.dev.*` + `.packages.overlays.{personal,work}.*` path traversal | WIRED | `grep .packages.roles home/.chezmoitemplates/brew` shows full traversal; `hasKey` guards at every overlay |
| `home/.chezmoi.toml.tmpl` | `.chezmoiignore` + `02-install-packages` + `03-mas` | `.role` data key set by `promptChoiceOnce` | WIRED | `.role` referenced in `.chezmoiignore` (`ne .role "dev"`); `hasKey . "role"` guard in `02-install-packages`; `{{ if .personal }}` in `03-mas` (presence guaranteed by `.chezmoiignore` darwin gate) |
| `home/.chezmoiignore` | `flameshot/`, `aerospace/`, `darwin-configure`, `03-mas` | Templated conditional-include gates evaluated on every apply | WIRED | All 4 gated paths confirmed present in `.chezmoiignore` body |
| `03-mas.sh.tmpl` | `packages.yaml (.packages.overlays.personal.darwin.mas)` | `{{ range $k, $v := .packages.overlays.personal.darwin.mas }}` | WIRED | Confirmed; mas entries in packages.yaml have `name:` + `id:` keys required by `dig` calls |
| `03-mas.sh.tmpl` | `/Applications/${app_name}.app` filesystem check | `[ ! -d ... ]` bash test as `mas install` precondition | WIRED | `/Applications/` pre-check present; `dig "name" "" $v | quote` resolves to app bundle name |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| TAX-01 | 0-01 | `role` prompt via `promptStringOnce` (amended: `promptChoiceOnce`) | SATISFIED | `promptChoiceOnce` present in `home/.chezmoi.toml.tmpl`; Wave 0 harness check #2 PASS |
| TAX-02 | 0-01 | `personal` flag orthogonal to `role` | SATISFIED | `personal` and `role` are independent `*Once` prompts; `overlays.{personal,work}` shape separates them |
| TAX-03 | 0-01 | OS auto-detected via `.chezmoi.os` | SATISFIED | Inherited chezmoi built-in; confirmed used in `.chezmoiignore` and `brew` template gates |
| TAX-04 | 0-01 | WSL auto-detected via `.wsl` flag | SATISFIED | `$wsl` computed from `kernel.osrelease` containing "microsoft" in `home/.chezmoi.toml.tmpl`; used in `.chezmoiignore` flameshot gate |
| TAX-05 | 0-01, 0-02 | `packages.yaml` restructured to `roles.<role>.<os>` + `overlays.personal.<os>` + `overlays.work.<os>` | SATISFIED | Ruby structural check PASS; brew template consumer rewritten against new shape |
| TAX-06 | 0-01 | `.chezmoiignore` templated; single file-presence gating point | SATISFIED | File is templated (4 `{{` blocks); gates aerospace, flameshot, darwin-configure, 03-mas by os/role/wsl |
| TAX-07 | 0-01 | Zero functional diff on active Macs after structural refactor | NEEDS HUMAN | Source-tree work complete and harness GREEN; actual `chezmoi diff -x externals` requires on-machine cutover execution (operator-driven per `cutover-phase-0.sh`) |
| TAX-08 | 0-03 | `docs/dot_topics.md` convention documented | SATISFIED | `docs/dot_topics.md` present; contains `dot_topics` convention (inherited from Phase 0.5 Plan 02) |
| SEC-05 | 0-01 | `generate-gpg-key.sh` PRESERVED in Phase 0 (deletion deferred to Phase 1) | SATISFIED | Script present; harness check #13 asserts its presence; `home/modify_dot_gitconfig.local` still load-bearing |
| LNX-05 | 0-03 | NO Linux Homebrew documented as explicit decision | SATISFIED | `docs/conventions.md` § 10.3 documents locked decision; apt + mise cited as the Linux consumer |
| SS-03 | 0-01 | `flameshot/flameshot.ini` preserved in source, gated to `role=dev + os=linux` | SATISFIED | File present at `home/private_dot_config/flameshot/flameshot.ini`; `.chezmoiignore` gate confirms darwin machines do NOT manage it |

**Note on TAX-07:** The requirement is satisfiable by the source-tree work done (packages.yaml semantic equivalence confirmed by brew template rendering 54 tap/brew/cask lines across all 3 fixture scenarios). The merge-gate verification (`chezmoi diff -x externals` empty on both Macs) is deferred to the operator-driven cutover per `0-VALIDATION.md` and `CLAUDE.md` "manual work = collaborative mode."

---

### Anti-Patterns Found

No blockers detected. The following were checked and are clean:

| File | Pattern Checked | Result |
|------|----------------|--------|
| `home/.chezmoiscripts/run_onchange_before_02-install-packages.sh.tmpl` | TODO/PLACEHOLDER/empty return | None found |
| `home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl` | Bare `mas install` without guard | None — all installs wrapped in `/Applications/` check |
| `home/.chezmoidata/packages.yaml` | Move-history comments | None remaining (Q3 applied); only load-bearing `localstack-cli` warning retained |
| `home/.chezmoitemplates/brew` | Linux loops emitting wrong keyword (`tap` instead of `brew`/`cask`) | None — 4 Linux-overlay bugs fixed in rewrite; correct keywords emitted |
| `home/.chezmoi.toml.tmpl` | Non-`*Once` `promptString` | None found (Pitfall 1 defense confirmed) |
| `cutover-phase-0.sh` | `--key=/path` form (zsh parsing pitfall) | None — space-separated `--key /path` form used throughout |

---

### Human Verification Required

#### 1. Per-machine `chezmoi init --apply` role prompt behavior (TAX-01 + TAX-07)

**Test:** On both Mac personal and Mac work, run `bash .planning/phases/0-structural-refactor/cutover-phase-0.sh` per the cutover ritual. Answer `dev` when prompted for role.

**Expected:** `promptChoiceOnce` fires exactly once per machine; subsequent `chezmoi apply` runs do not re-prompt. `~/.config/chezmoi/chezmoi.toml` contains `role = "dev"`.

**Why human:** `promptChoiceOnce` persistence requires an actual on-machine init run with a live chezmoi config path. Cannot be verified with `execute-template --init` (which does not write to the config file).

#### 2. `chezmoi diff -x externals` empty on both Macs (TAX-07 merge gate / SC #4)

**Test:** After cutover on each machine, run `chezmoi diff -x externals`.

**Expected:** Empty output on both Mac personal and Mac work.

**Why human:** Requires live machine state (actual destination filesystem + chezmoi entryState + real chezmoi.toml data). The `cutover-phase-0.sh` script runs this as step 7 and fails loud if non-empty.

#### 3. `chezmoi apply --dry-run --verbose | grep "no value"` empty (SC #3)

**Test:** After cutover on each machine, run `chezmoi apply --dry-run --verbose 2>&1 | grep "no value"`.

**Expected:** Empty output on both machines.

**Why human:** Requires live chezmoi.toml data (real name, email, role, personal). Fixture-based render confirmed zero `<no value>` but live machine data is the authoritative check.

#### 4. `~/bin/` removed + `~/.local/bin/` populated after exact_bin teardown

**Test:** After cutover step 6 (`rm -rf ~/bin/` + 5× state delete), verify `ls ~/bin/ 2>/dev/null` fails AND `ls ~/.local/bin/` shows the 5 utilities.

**Expected:** `~/bin/` absent; `~/.local/bin/` contains `dot`, `git-bare-clone`, `git-wtf`, `tmux-cht.sh`, `tmux-sessionizer`.

**Why human:** `~/bin/` teardown is operator-driven (Pitfall C: source-delete does NOT auto-remove destination on either chezmoi version). Cutover script step 6 is the mechanism.

#### 5. Mac work: NODE_EXTRA_CA_CERTS migrated from `~/.zshrc` to `~/.localrc`

**Test:** On Mac work after cutover step 4, verify `grep NODE_EXTRA_CA_CERTS ~/.zshrc` returns empty AND `grep NODE_EXTRA_CA_CERTS ~/.localrc` shows the export line.

**Expected:** Line absent from `~/.zshrc`; present in `~/.localrc`.

**Why human:** Mac work-specific migration; requires Mac work machine access. Cutover script step 4 autodetects via `grep -q NODE_EXTRA_CA_CERTS ~/.zshrc` and runs the sed-delete + append if found.

#### 6. Mac work: chezmoi version preflight (≥ 2.70.4 required)

**Test:** Before running cutover on Mac work, run `chezmoi --version`. If below 2.70.4, run `brew upgrade chezmoi` first.

**Expected:** Cutover script step 2 preflight passes.

**Why human:** Mac work was on chezmoi 2.69.4 at context-capture time (2026-05-31); operator must upgrade before cutover script will proceed.

---

### Gaps Summary

No automated gaps. All 13 source-tree must-haves verified. The remaining open items are exclusively operator-driven cutover actions:

- The cutover script (`cutover-phase-0.sh`) is committed and executable. It implements the locked 8-step sequence verified here.
- Wave 0 harness: `quick.sh` 23/23 PASS, `full.sh --no-diff-gate` 9/9 PASS + 1 PENDING (diff gate intentionally skipped as operator-driven).
- All 11 requirement IDs in scope (TAX-01..08, SEC-05, LNX-05, SS-03) are covered by at least one plan's `requirements:` frontmatter.
- TAX-07 is the only requirement that cannot be fully satisfied without cutover execution on both active Macs.

**Recommended next action:** Run `bash .planning/phases/0-structural-refactor/cutover-phase-0.sh` on Mac personal first, then Mac work, in collaborative mode per CLAUDE.md. Phase 0 source-tree work is complete.

---

_Verified: 2026-06-03_
_Verifier: Claude (gsd-verifier)_
