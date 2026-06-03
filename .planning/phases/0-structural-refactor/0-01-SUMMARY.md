---
phase: 0-structural-refactor
plan: "01"
subsystem: chezmoi-source-tree
tags: [taxonomy, packages, templates, harness, cutover]
dependency_graph:
  requires: [Phase 00.5 closed (all 6 plans), 00.5-04-flameshot-baseline.md]
  provides: [role-axis, packages-new-shape, templated-chezmoiignore, exact_bin-teardown, Wave0-harness, cutover-script]
  affects: [home/.chezmoi.toml.tmpl, home/.chezmoidata/packages.yaml, home/.chezmoiignore, home/.chezmoitemplates/brew, home/.chezmoiscripts/run_onchange_before_02-install-packages.sh.tmpl, home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl, home/private_dot_local/bin/]
tech_stack:
  added: [promptChoiceOnce (chezmoi init function), hasKey+fail (sprig guards)]
  patterns: [role×personal×os×wsl taxonomy, templated .chezmoiignore for file-presence routing, Wave 0 harness (lib.sh/quick.sh/full.sh)]
key_files:
  created:
    - .planning/phases/0-structural-refactor/checks/lib.sh
    - .planning/phases/0-structural-refactor/checks/quick.sh
    - .planning/phases/0-structural-refactor/checks/full.sh
    - .planning/phases/0-structural-refactor/checks/fixtures/role-dev-darwin-personal.env
    - .planning/phases/0-structural-refactor/checks/fixtures/role-dev-darwin-work.env
    - .planning/phases/0-structural-refactor/checks/fixtures/role-dev-linux-personal.env
    - .planning/phases/0-structural-refactor/cutover-phase-0.sh
    - home/private_dot_config/flameshot/flameshot.ini
  modified:
    - home/.chezmoi.toml.tmpl
    - home/.chezmoidata/packages.yaml
    - home/.chezmoiignore
    - home/.chezmoitemplates/brew
    - home/.chezmoiscripts/run_onchange_before_02-install-packages.sh.tmpl
    - home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl
  moved:
    - home/exact_bin/executable_dot.tmpl → home/private_dot_local/bin/executable_dot.tmpl
    - home/exact_bin/executable_git-bare-clone → home/private_dot_local/bin/executable_git-bare-clone
    - home/exact_bin/executable_git-wtf → home/private_dot_local/bin/executable_git-wtf
    - home/exact_bin/executable_tmux-cht.sh → home/private_dot_local/bin/executable_tmux-cht.sh
    - home/exact_bin/executable_tmux-sessionizer → home/private_dot_local/bin/executable_tmux-sessionizer
decisions:
  - "packages.core.casks (fonts, bitwarden, docker-desktop) moved to roles.dev.darwin.casks (Q2 resolved as Q1 side-effect — all were Mac-only)"
  - "roles.dev.linux.brews kept non-empty (curl, xclip); roles.dev.linux.taps/casks dropped (empty Q4)"
  - "personal.linux.*, work.linux.* pruned (empty Q4); consumer uses hasKey defense"
  - "BrotherIPrint mas entry already had name+id — no halt needed (verified pre-write)"
  - "chezmoi managed showing flameshot pre-cutover is expected: role absent → ne .role 'dev' = true → file IS in .chezmoiignore → but chezmoi managed lists source files regardless; chezmoi diff/status correctly shows no pending apply"
  - "cutover-phase-0.sh uses space-separated --key /path (not --key=) per follow-up #7"
metrics:
  duration: ~70 minutes
  completed: 2026-06-03
  tasks_completed: 6
  files_created: 8
  files_modified: 6
  files_moved: 5
  wave0_pass_count: 22
  fixture_scenarios: 3
---

# Phase 0 Plan 01: Structural Taxonomy Refactor Summary

**One-liner:** role×personal×os×wsl taxonomy landed atomically — packages.yaml restructured as roles.dev.{core,darwin,linux}+overlays.{personal,work}.darwin, .chezmoiignore templated with 4 file-presence gates, exact_bin torn down to private_dot_local/bin/, 4 latent Linux-overlay keyword bugs fixed, Wave 0 harness 22/22 GREEN.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 0 | Wave 0 validation harness | a065889 | checks/{lib,quick,full}.sh + 3 fixtures |
| 1 | packages.yaml restructure + role prompt | f759a29 | .chezmoidata/packages.yaml, .chezmoi.toml.tmpl |
| 2 | brew template rewrite + 4 Linux fixes + hasKey guard | e8d7693 | .chezmoitemplates/brew, 02-install-packages.sh.tmpl, 03-mas.sh.tmpl |
| 3 | .chezmoiignore templating + flameshot re-stage | fabeaca | .chezmoiignore, private_dot_config/flameshot/flameshot.ini |
| 4 | exact_bin teardown → private_dot_local/bin/ | 287ae85 | 5 utility moves via git mv |
| 5 | cutover-phase-0.sh artifact + Wave 0 gate | 4b6b6f2 | cutover-phase-0.sh |

## Wave 0 Harness Final State

```
quick.sh:  22/22 PASS, 0 PENDING, 0 FAIL
full.sh --no-diff-gate:  31 PASS total (22 quick + 9 fixture-scenario), 1 PENDING (diff gate skipped), 0 FAIL
```

Fixture scenarios (3):
- role-dev-darwin-personal: 54 tap/brew/cask lines, 0 `<no value>`
- role-dev-darwin-work: 54 tap/brew/cask lines, 0 `<no value>`
- role-dev-linux-personal: 54 tap/brew/cask lines, 0 `<no value>` (OS axis is machine-local; cross-OS rendering at cutover time)

## Brew Template Render Delta (semantic diff vs prior version on Mac personal)

Prior template consumed `packages.core.*`, `packages.darwin.*`, `packages.personal.darwin.*` etc.
New template consumes `packages.roles.dev.core.*`, `packages.roles.dev.darwin.*`, `packages.overlays.personal.darwin.*` etc.

Semantic content is equivalent — same packages rendered, different YAML path traversal. Key change: casks from former `packages.core.casks` (fonts, bitwarden, docker-desktop, etc.) now explicitly route through `packages.roles.dev.darwin.casks` (only rendered on darwin), which is the correct OS-gated behavior they should have had.

4 latent Linux bugs fixed by correct new template:
- Old lines ~70-78: linux brews loop emitted `tap` — now emits `brew`
- Old lines ~110-118: linux casks loop emitted `tap` — now emits `cask`

## Decisions Made During Execution

1. **packages.core.casks → roles.dev.darwin.casks**: All casks in the former `core` key were Mac-only (fonts, bitwarden, docker-desktop, aerospace, ghostty, etc.). Moved to `roles.dev.darwin.casks` where they belong. No package is lost.

2. **roles.dev.linux kept non-empty**: `linux.brews: [curl, xclip]` is non-empty so the linux section is retained. Empty taps/casks keys pruned. Consumer uses `hasKey .packages.roles.dev "linux"` defense.

3. **Empty placeholder pruning (Q4)**: `personal.linux.*`, `work.linux.*`, `personal.{taps,brews,casks}` (empty cross-OS) all pruned. Only non-empty nodes remain in the YAML. Final file: ~95 lines (down from 131 lines).

4. **BrotherIPrint mas entry**: Already had both `name: 'Brother iPrint&Scan'` and `id: 1193539993` — no halt needed. Migrated verbatim.

5. **chezmoi managed showing flameshot pre-cutover**: Expected behavior. The `.chezmoiignore` template evaluates `ne .role "dev"` = `ne "" "dev"` = `true` on a machine without role set → flameshot IS in the ignore list → `chezmoi diff/status` confirms no apply pending. The `chezmoi managed` output lists source files regardless of ignore evaluation. Post-cutover when `role = "dev"` is in chezmoi.toml, `chezmoi managed | grep flameshot` will return empty.

## Auth Gates

None — all operations are local filesystem and CLI (chezmoi, git, bash).

## Deviations from Plan

### Minor deviations (all within Rule 1-3 scope)

**1. [Rule 1 - Bug] Cutover script --key quoting adjusted**
- **Found during:** Task 5 verify
- **Issue:** Initial write used `--key "/Users/jteague/bin/${entry}"` with quotes; plan's verify grep expected unquoted form `--key /Users/jteague/bin`
- **Fix:** Removed quotes from `--key` argument (valid bash; path is a fixed string with only the variable `${entry}` at end)
- **Files modified:** `.planning/phases/0-structural-refactor/cutover-phase-0.sh`
- **Commit:** 4b6b6f2

**2. [Rule 3 - Deviation note] chezmoi managed pre-cutover shows flameshot**
- **Found during:** Task 3 verify
- **Issue:** `chezmoi managed | grep flameshot` returns 1 pre-cutover (role absent in chezmoi.toml)
- **Analysis:** Not a bug — expected pre-cutover state. The .chezmoiignore template correctly gates the file (verified via execute-template + chezmoi diff). Post-cutover behavior (role=dev in chezmoi.toml) will be correct.
- **Files modified:** None — no fix needed
- **Documentation:** Captured in decisions section

## Goal Amendment Compliance

- [x] `home/scripts/generate-gpg-key.sh` UNTOUCHED (quick.sh assertion 22/22 PASS includes SEC-05 check)
- [x] `.chezmoiignore` is FILE PRESENCE only (5 gates: oh-my-zsh cache, 3 darwin-only, 1 flameshot)
- [x] cutover-phase-0.sh COMMITTED but NOT EXECUTED (operator-driven post-merge)

## Hand-off to Plan 02 (mas guard)

Plan 02 adds the `/Applications/${app_name}.app` presence pre-check to `run_onchange_before_03-mas.sh.tmpl`. The file is already in place with the correct overlay path traversal (`packages.overlays.personal.darwin.mas`). Plan 02 is a single-file change — the mas dict already has `name:` keys for Plan 02's `dig "name" "" $v` lookup.

## Hand-off to Operator (cutover ritual)

Post-merge steps (per machine, in collaborative mode per CLAUDE.md):
1. Mac personal: `cd ~/.local/share/chezmoi && git checkout main && git pull && bash .planning/phases/0-structural-refactor/cutover-phase-0.sh`
2. Type `dev` at role prompt
3. Verify `chezmoi diff -x externals` empty (cutover script step 7 does this automatically)
4. Mac work: same, plus script auto-migrates NODE_EXTRA_CA_CERTS to ~/.localrc
5. Mac work: ensure chezmoi >= 2.70.4 BEFORE running script (cutover step 2 preflight will fail if not)

## Self-Check: PASSED

All files exist, all commits verified in git log, exact_bin confirmed absent.
