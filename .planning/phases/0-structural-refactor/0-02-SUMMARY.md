---
phase: 0-structural-refactor
plan: "02"
subsystem: chezmoi-source-tree
tags: [mas, guard, pitfall-fix, applications-check]
dependency_graph:
  requires: [0-01-structural (packages.overlays.personal.darwin.mas path shape + name/id keys)]
  provides: [mas-install-guard, /Applications/-presence-check, skip-echo-on-already-installed]
  affects: [home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl]
tech_stack:
  added: [dig (sprig) for name/id key lookup, bash conditional [[ ! -d ]] presence check]
  patterns: [/Applications/<App>.app file-presence guard around mas install]
key_files:
  created: []
  modified:
    - home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl
    - .planning/phases/0-structural-refactor/checks/quick.sh
decisions:
  - "Sub-task 1A precondition passed on first run — Plan 01 Task 1 Sub-task 1B correctly populated all name: keys (BrotherIPrint entry verified: name='Brother iPrint&Scan', id=1193539993)"
  - "chezmoi execute-template --init not needed for 03-mas.sh.tmpl smoke test — .chezmoidata/ is always loaded; --init is only needed for .chezmoi.toml.tmpl which processes promptStringOnce/promptChoiceOnce init-time functions"
  - "Added assert_grep '/Applications/' to quick.sh Section 11 per plan recommendation — harness now 23/23 PASS instead of 22/22"
  - "Expected re-fire on cutover: content SHA of 03-mas.sh.tmpl changed → run_onchange re-fires once on chezmoi init --apply post-merge; every entry skips (apps already present at /Applications/); intentional and documented"
metrics:
  duration: ~10 minutes
  completed: 2026-06-03
  tasks_completed: 1
  files_modified: 2
  wave0_quick_pass: 23
  wave0_fixture_pass: 9
---

# Phase 0 Plan 02: mas Guard Summary

**One-liner:** /Applications/<App>.app presence guard wraps every mas install call — skip-with-echo when app bundle exists; install only when absent (resolves Phase 0.5 follow-up #4 + Pitfall mas-list-Apple-ID-invisibility).

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Add /Applications/<App>.app guard around mas install | 85f288b | run_onchange_before_03-mas.sh.tmpl, checks/quick.sh |

## Before / After diff of 03-mas.sh.tmpl

**Before (Plan 01 state, ~6 lines):**
```go-template
#!/bin/bash
{{ if .personal -}}
  {{ range $k, $v := .packages.overlays.personal.darwin.mas }}
/opt/homebrew/bin/mas install {{ dig "id" "" $v }}
  {{ end -}}
{{ end -}}
```

**After (Plan 02, ~11 lines in source):**
```go-template
#!/bin/bash
{{ if .personal -}}
  {{ range $k, $v := .packages.overlays.personal.darwin.mas }}
    app_name={{ dig "name" "" $v | quote }}
    if [ ! -d "/Applications/${app_name}.app" ]; then
      /opt/homebrew/bin/mas install {{ dig "id" "" $v }}
    else
      echo "Skipping mas install: ${app_name}.app already present"
    fi
  {{ end -}}
{{ end -}}
```

Line count grew from ~6 to ~11 source lines (~5 rendered lines per mas entry instead of 1).

## Sub-task 1A: Precondition Assertion Result

**PASSED on first run.** No halt needed. Plan 01 Task 1 Sub-task 1B correctly populated all `name:` and `id:` keys in the mas dict:

```
BrotherIPrint: name="Brother iPrint&Scan", id=1193539993
```

`dig "name" "" $v` lookup is safe — no empty-string fallback path will be triggered.

## Rendered Example: Brother iPrint&Scan

Rendered output on darwin+personal=true (from `chezmoi execute-template`):

```bash
#!/bin/bash

    app_name="Brother iPrint&Scan"
    if [ ! -d "/Applications/${app_name}.app" ]; then
      /opt/homebrew/bin/mas install 1193539993
    else
      echo "Skipping mas install: Brother iPrint&Scan.app already present"
    fi
```

**Runtime behavior at cutover (Mac personal):**

Since `Brother iPrint&Scan.app` is already installed at `/Applications/Brother iPrint&Scan.app`, the runtime output will be:

```
Skipping mas install: Brother iPrint&Scan.app already present
```

No actual `mas install` call, no sudo prompt, no Spotlight re-index. This is the exact fix for the Pitfall mas-list-Apple-ID-invisibility case — Brother iPrint was installed under a different Apple ID and is invisible to `mas list`, but the app bundle IS present at `/Applications/`.

## Expected Re-fire on Cutover (Pitfall 2 — content SHA change)

`03-mas.sh.tmpl` content SHA changed in this commit. `run_onchange_before_03-mas` will re-fire once on `chezmoi init --apply` post-merge on each Mac.

**Expected behavior:**
- Mac personal: Script runs → iterates mas entries → every entry finds bundle at `/Applications/` → emits `Skipping mas install: <App>.app already present` → no installs, no prompts, no Spotlight re-index.
- Mac work: `{{ if .personal }}` evaluates false (work machine is not personal) → script body is effectively empty → no-op. Correct.

This re-fire is intentional and harmless. Capture in cutover log when running `cutover-phase-0.sh`.

## Wave 0 Harness Final State (Post-Plan-02)

```
quick.sh:  23/23 PASS, 0 PENDING, 0 FAIL  (up from 22/22 — Section 11 added)
full.sh --no-diff-gate:  32 PASS total (23 quick + 9 fixture-scenario), 1 PENDING (diff gate skipped), 0 FAIL
```

New assertion (Section 11 in quick.sh):
```bash
assert_grep '/Applications/' home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl
```

## Deviations from Plan

### Minor deviations (all within Rule 1-3 scope)

**1. [Rule 1 - Clarification] chezmoi execute-template --init not needed for smoke test**
- **Found during:** Sub-task 1C
- **Issue:** Plan's Sub-task 1C smoke test used `--init --promptString name=t ...` flags, which produced `map has no entry for key "packages"` error. The `--init` flag is only needed when the template itself calls `promptStringOnce` / `promptChoiceOnce` / `promptBoolOnce` (init-time functions). `03-mas.sh.tmpl` uses `.packages.*` data which comes from `.chezmoidata/packages.yaml` — always available without `--init`.
- **Fix:** Used `chezmoi execute-template < home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl` (no init flags). Rendered correctly.
- **Files modified:** None — smoke test command corrected in execution; template is fine.

## Auth Gates

None — all operations are local filesystem and CLI (chezmoi, git, bash, ruby).

## Hand-off to Plan 03 (docs)

Plan 03 updates `docs/conventions.md` § 10 with:
- AUD-02 LIGHT remainder (6 inherited inconsistencies from Phase 0.5 context)
- Goal amendments (#1 generate-gpg-key.sh deferred to Phase 1; #2 .chezmoiignore file-presence reframe; employer axis .localrc pattern)
- Phase 0.5 follow-up pitfall notes (#1, #2, #3, #5, #8)
- `.localrc` + `~/.local/bin/` employer-local pattern documentation
- LNX-05 locked decision (no Linux Homebrew)

Phase 0 structural change (Plan 01) + mas guard (Plan 02) are now complete. Plan 03 is the final piece before the merge gate run.

## Self-Check: PASSED
