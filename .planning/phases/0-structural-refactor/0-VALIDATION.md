---
phase: 0
slug: structural-refactor
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-01
---

# Phase 0 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | shell harness (bash) + chezmoi CLI primitives — no test framework install |
| **Config file** | `.planning/phases/0-structural-refactor/checks/lib.sh` (Wave 0 installs) |
| **Quick run command** | `bash .planning/phases/0-structural-refactor/checks/quick.sh` |
| **Full suite command** | `bash .planning/phases/0-structural-refactor/checks/full.sh` |
| **Estimated runtime** | ~5 seconds quick / ~15 seconds full (pure CLI + template renders; no network) |

---

## Sampling Rate

- **After every task commit:** Run `bash .planning/phases/0-structural-refactor/checks/quick.sh`
- **After every plan wave:** Run `bash .planning/phases/0-structural-refactor/checks/full.sh`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~15 seconds

---

## Per-Task Verification Map

Populated by gsd-planner during plan creation. Template per task:

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 0-01-01 | 01 | 1 | TAX-* | unit | `bash checks/quick.sh` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `checks/lib.sh` — shared assertions (chezmoi-cmd, template-render, file-exists)
- [ ] `checks/quick.sh` — fast post-commit gates (template-render against fixture data, `hasKey` loud-fail guard fires, no `<no value>` in execute-template output)
- [ ] `checks/full.sh` — quick + structural assertions (packages.yaml shape, `.chezmoiignore` gates by role/os, exact_bin removed from source, 5 scripts in `private_dot_local/bin/`)
- [ ] Fixture data files: `checks/fixtures/role-dev-darwin-personal.toml`, `role-dev-darwin-work.toml`, `role-dev-linux-personal.toml` (chezmoi `execute-template --init` inputs)

---

## Manual-Only Verifications

Per CLAUDE.md "manual work = collaborative mode": cutover steps run on real machines, NOT autonomously.

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `chezmoi init --apply` on Mac personal — only `role` prompt fires | TAX-01 / SC #1 | Touches real `~/.config/chezmoi/chezmoi.toml` on a live machine | Run cutover-phase-0.sh on Mac personal; verify role persists; subsequent `chezmoi apply` does not re-prompt |
| Same on Mac work | TAX-01 / SC #1 | Mac work daily driver — Bluebeam dependencies in scope | Same as above on Mac work; verify NODE_EXTRA_CA_CERTS landed in `~/.localrc` |
| `chezmoi diff -x externals` empty on Mac personal | SS-03 / SC #4 | Diff is source-vs-destination on live machine | Post-cutover, run `chezmoi diff -x externals`; capture empty |
| `chezmoi diff -x externals` empty on Mac work | SS-03 / SC #4 | Same | Same on Mac work |
| `chezmoi apply --dry-run --verbose 2>&1 \| grep "no value"` empty on both Macs | TAX-08 / SC #3 | Render against real `~/.config/chezmoi/chezmoi.toml` | Post-cutover step in script; also captured in cutover script step 7 |
| `~/bin/` orphans cleaned + entryState bucket pruned | TAX-04 / Pitfall C | Touches per-machine chezmoistate.boltdb | Cutover script step 5 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags (shell harness is one-shot)
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
