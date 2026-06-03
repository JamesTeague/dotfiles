---
phase: 0-structural-refactor
plan: "03"
subsystem: docs
tags: [docs, conventions, AUD-02, LNX-05, TAX-08, pitfalls, employer-local]
dependency_graph:
  requires: [0-01-structural (packages restructure referenced), 0-02-mas-guard (03-mas.sh.tmpl referenced)]
  provides: [conventions-sec10-expanded, AUD-02-light-dispositions, LNX-05-documented, TAX-08-verified]
  affects: [docs/conventions.md]
tech_stack:
  added: []
  patterns: [state-forge documented, state-dump utility documented, employer-local ~/.localrc + ~/.local/bin/ pattern documented]
key_files:
  created: []
  modified:
    - docs/conventions.md
decisions:
  - "AUD-02 LIGHT inconsistencies #4 + #5 (packages.yaml dead-code shape) marked RESOLVED — Plan 01 restructure eliminated the old shape entirely"
  - "AUD-02 LIGHT inconsistencies #1, #2, #3, #6 marked DEFERRED — rename/restructure deferred to Phase 1+ (executable_ prefix changes destination file mode; OS-subdir layout is Phase 3)"
  - "state-forge pattern documented as legitimate only when underlying reality verified by another mechanism; never blind-forge"
  - "LNX-05 locked decision documented with Phase 3 as the apt+mise consumer implementation phase"
metrics:
  duration: ~15 minutes
  completed: 2026-06-03
  tasks_completed: 1
  files_modified: 1
  lines_before: 173
  lines_after: 301
  line_delta: +128
  wave0_quick_pass: 23
  wave0_fixture_pass: 9
---

# Phase 0 Plan 03: Docs (conventions § 10) Summary

**One-liner:** `docs/conventions.md` § 10 expanded from 8 lines to a full 130-line section covering Phase 0 goal amendments, employer-local pattern, LNX-05 decision, 5 follow-up pitfall/pattern notes, and AUD-02 LIGHT dispositions for all 6 inherited inconsistencies.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Expand docs/conventions.md § 10 + TAX-08 verify + Wave 0 harness | 6405eed | docs/conventions.md |

## Section Structure of Expanded § 10

```
§ 10. Phase 0 Patterns, Follow-up Pitfalls, and AUD-02 Remainder
  10.1 Phase 0 Goal Amendments
    10.1.1 generate-gpg-key.sh: DEFERRED to Phase 1
    10.1.2 .chezmoiignore: FILE PRESENCE only
  10.2 Employer-Local Pattern: ~/.localrc + ~/.local/bin/
  10.3 LNX-05 Locked Decision: NO Linux Homebrew
  10.4 Phase 0.5 Follow-up Pitfall/Pattern Notes
    10.4.1 chezmoi state dump as canonical clean-check utility (#1)
    10.4.2 chezmoi apply --dry-run --verbose exits nonzero on TTY prompts (#2)
    10.4.3 mas list Apple ID invisibility (#3)
    10.4.4 chezmoi state set (state-forge) pattern (#5)
    10.4.5 Pitfall C re-validation: source-delete does NOT auto-remove destination (#8)
  10.5 AUD-02 LIGHT Remainder (6 inherited inconsistencies)
    10.5.1 dot_topics/rust/path.zsh: missing executable_ — DEFERRED
    10.5.2 dot_topics/system/path.zsh.tmpl: missing executable_ — DEFERRED
    10.5.3 run_onchange_after_darwin-configure.sh.tmpl: no NN- prefix — DEFERRED
    10.5.4 packages.yaml personal.* top-level dead code — RESOLVED (Plan 01)
    10.5.5 packages.yaml work.core.* dead code — RESOLVED (Plan 01)
    10.5.6 .DS_Store at repo root — DEFERRED (gitignore confirmed)
```

## AUD-02 LIGHT Disposition Summary

| # | Inconsistency | Phase 0 Status |
|---|---------------|----------------|
| 1 | `dot_topics/rust/path.zsh` missing `executable_` | DEFERRED — Phase 1+ |
| 2 | `dot_topics/system/path.zsh.tmpl` missing `executable_` | DEFERRED — Phase 1+ |
| 3 | `darwin-configure.sh.tmpl` missing `NN-` prefix | DEFERRED — Phase 3 (OS-subdir layout) |
| 4 | `packages.yaml` `personal.*` top-level dead code | RESOLVED — Plan 01 restructure |
| 5 | `packages.yaml` `work.core.*` dead code | RESOLVED — Plan 01 restructure |
| 6 | `.DS_Store` at repo root | DEFERRED — confirmed in .gitignore |

## Line Count Delta

- Before: 173 lines
- After: 301 lines
- Delta: +128 lines (well under the 500-line limit per CLAUDE.md)

## Cross-References Made to Plans 01 + 02 Files

- `home/.chezmoidata/packages.yaml` — LNX-05 shape reference; AUD-02 RESOLVED dispositions
- `home/.chezmoiignore` — § 10.1.2 file-presence gates enumeration
- `home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl` — § 10.4.3 `/Applications/` guard reference
- `home/.chezmoitemplates/brew` — § 10.3 LNX-05 consumer reference
- `.planning/phases/0-structural-refactor/cutover-phase-0.sh` — § 10.2 Mac work cutover reference

## TAX-08 Verification

`test -f docs/dot_topics.md && grep -q "dot_topics" docs/dot_topics.md` — PASSED.

`docs/dot_topics.md` exists with the `dot_topics/<tool>` convention text, inherited from Phase 0.5 Plan 02. No new content added; verify-by-inspection only.

## Wave 0 Harness Final State (Post-Plan-03)

```
quick.sh:  23/23 PASS, 0 PENDING, 0 FAIL
full.sh --no-diff-gate:  32 PASS total (23 quick + 9 fixture-scenario), 1 PENDING (diff gate skipped), 0 FAIL
```

Docs-only change (`docs/` is outside `.chezmoiroot = home/`) — no source tree state change. Harness stable from Plan 02 baseline.

## Deviations from Plan

### Minor deviations (all within Rule 1-3 scope)

**1. [Rule 1 - Bug] Typo fixed in example path**
- **Found during:** content write
- **Issue:** Draft had `~/. chezmoiscripts/03-mas.sh` (stray space between `~/` and `.chezmoiscripts`)
- **Fix:** Corrected to `~/.chezmoiscripts/03-mas.sh` in a follow-up edit before the single task commit
- **Files modified:** docs/conventions.md
- **Commit:** 6405eed (same task commit — caught before staging)

## Hand-off to Phase Close

Phase 0 source-tree work is DONE. All three plans committed:

| Plan | Commit | Description |
|------|--------|-------------|
| 0-01 structural | 4b6b6f2 (final) | role×personal×os×wsl taxonomy, packages.yaml, cutover script |
| 0-02 mas guard | 85f288b | /Applications/<App>.app presence guard |
| 0-03 docs | 6405eed | conventions § 10 expansion |

**Next: operator-driven cutover ritual** (runs AFTER merge gate passes, in collaborative mode per CLAUDE.md §4):

1. `cd ~/.local/share/chezmoi && git checkout master && git pull`
2. `bash .planning/phases/0-structural-refactor/cutover-phase-0.sh`
3. Answer `dev` at role prompt
4. Verify `chezmoi diff -x externals` empty (cutover script step 7)
5. Run Mac work second; script auto-migrates `NODE_EXTRA_CA_CERTS` to `~/.localrc`
6. Ensure chezmoi ≥ 2.70.4 on Mac work BEFORE running (cutover step 2 preflight)

Cutover script: `.planning/phases/0-structural-refactor/cutover-phase-0.sh`

## Auth Gates

None — all operations are local filesystem and CLI.

## Self-Check: PASSED

- docs/conventions.md: FOUND (301 lines)
- docs/dot_topics.md: FOUND (TAX-08 confirmed)
- .planning/phases/0-structural-refactor/0-03-SUMMARY.md: FOUND
- commit 6405eed: FOUND in git log
