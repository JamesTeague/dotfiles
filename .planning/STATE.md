---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: completed
stopped_at: "Completed `00.5-02-docs-PLAN.md` 2026-05-28T02:35:11Z (Wave 1 fully closed)."
last_updated: "2026-05-28T02:35:11Z"
progress:
  total_phases: 6
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
---

# Project State: chezmoi Modernization

**Last updated:** 2026-05-28

## Project Reference

**Core Value:** A new machine — any OS in the fleet — can be set up day-1 via a single `chezmoi init --apply` flow (plus VaultWarden login + GitHub PAT for HTTPS clone bootstrap) and arrive at a fully-configured, identity-signed, role-appropriate state without artisanal touch-up.

**Current Focus:** Phase 0.5 (Audit & Documentation) — Wave 1 fully closed (Plans 01 + 02 + 03 complete). Wave 2 (Plans 04 flameshot-removal + 05 packages-audit) ready to launch in parallel.

## Current Position

**Phase:** 00.5-audit-documentation
**Plan:** Wave 1 complete (01 + 02 + 03) · next is Wave 2 (Plans 04 + 05 in parallel) · then Plan 06 exit-gate
**Status:** Wave 1 fully landed; Wave 2 unblocked
**Progress:** Phase 0/6 plans done · 0.5 sub-progress 3/6 plans `███░░░`

## Performance Metrics

| Metric | Value |
|--------|-------|
| Phases planned | 1/6 (0.5 planned; others pending) |
| Phases complete | 0/6 |
| Plans complete (Phase 0.5) | 3/6 |
| v1 requirements mapped | 69/69 |
| v1 requirements complete | 3/69 (SS-01, AUD-04, AUD-05) |
| Pitfalls mitigated in roadmap | 11 of 22 surfaced in PITFALLS.md (the critical ones); Pitfall 22 (dot_topics undocumented) resolved by Plan 02 |

| Plan | Tasks | Files | Duration |
|------|-------|-------|----------|
| 00.5-01 wave0-harness | 3 | 5 | 5m |
| 00.5-02 docs | 4 (3 auto + 1 human-verify) | 4 | 6m active (spanned checkpoint pause) |
| 00.5-03 gitattributes-statepeek | 2 | 2 | 3m |

## Accumulated Context

### Locked Decisions (from PROJECT.md + research)
- Stay on chezmoi (Nix rejected — no native Windows)
- 3-role taxonomy: `dev` / `gaming` / `lite`; `personal` is orthogonal flag (not absorbed into role)
- VaultWarden via Cloudflare tunnel + chezmoi `bitwarden*` template functions (NOT `bitwardenSecrets` — doesn't work against VaultWarden)
- Per-purpose SSH keys (personal-github + work-github minimum)
- Canonical GPG (vs per-machine generation); `generate-gpg-key.sh` to be DELETED in Phase 0
- Linux package management: apt + mise (NOT Linux Homebrew)
- Hybrid migration: Phase 0 refactor branch (atomic) → additive phases 1-4
- Repo is private (was public) — unlocks BW flexibility + encrypted bootstrap kit
- Non-standard phase numbering retained: 0.5, 0, 1, 2, 3, 4
- Bootstrap kit lives in Phase 1, NOT Phase 4
- PowerShell 7+ only (5.1 explicitly out of scope)

### Critical Pitfalls Baked Into Phases
- Phase 0: `promptStringOnce` everywhere + per-machine cutover ritual + `generate-gpg-key.sh` DELETED (not renamed)
- Phase 1: `bw` CLI version pinned against VaultWarden 1.36.0 + offline known-good binary in bootstrap kit + vault-offline drill executed before phase close
- Phase 2: pwsh 7+ prerequisite + `[interpreters.ps1]` with `-ExecutionPolicy Bypass` + elevated first-run + singular `chezmoi:template:line-ending=native` directive on every `.ps1.tmpl`
- Phase 3: explicit `appendWindowsPath` decision + SSH keys in WSL native fs (not `/mnt/c`) + canonical Gpg4win agent rule + `wsl --version` gate as first bootstrap step

### Phase 0.5 Decisions (from completed plans)
- **(Plan 01)** YAML validator preference: system ruby > python3+yaml. Mac personal has no PyYAML; ruby ships YAML stdlib on macOS. quick.sh tries ruby first, python3 fallback, pends if neither.
- **(Plan 01)** Wave 0 harness pattern: lib.sh + quick.sh + full.sh under `.planning/phases/XX/checks/`. Two-level severity (PASS/PENDING/FAIL). STRICT_MODE flips PENDING→FAIL. `assert_dir_missing` defaults to pending (wave-staged removal != broken invariant); `_strict` variant exists for hard invariants.
- **(Plan 01)** Empty placeholders in `packages.yaml` (linux.*, work.darwin.*, work.linux.*) are KEEP-recommended in the candidate scaffold — removing requires guarding the brew template's `range` loops with `hasKey`, which is Phase 0 / TAX-05 template-restructure work, not Phase 0.5.
- **(Plan 01)** full.sh accepts `--no-diff-gate` + `--no-quick` so Wave 1 plans can use the harness despite pre-existing `.zshrc` DEBUG=1 drift on Mac personal (Pitfall B in RESEARCH; Plan 06 owns reconciliation).
- **(Plan 03)** Skipped `git add --renormalize` when landing `.gitattributes` — Mac personal pre-check showed all 12 `.tmpl` files already `i/lf` in index; renormalize would be a no-op. Decision documented in Task 1 commit message and will be encoded in `docs/conventions.md` (Plan 02). Mac work pre-check remains a Plan 06 human-in-loop task (Pitfall E).
- **(Plan 03)** State-preview itemizes only the 9 entries Phase 0 will reshape (flameshot dir + ini, generate-gpg-key.sh, 6 chezmoi-side script entries) rather than enumerating all 1673 entryState entries — full enumeration is noise; Phase 0 can re-query the bucket directly for anything else.
- **(Plan 03)** Both RESEARCH surprises empirically verified on Mac personal: `generate-gpg-key.sh` is `type: file` in entryState with ZERO scriptState references (Phase 0's `run_once_` re-fire concern does NOT apply — source delete + apply is sufficient); externals `refreshPeriod = "168h"` confirmed.
- **(Plan 02)** Docs describe REALITY, not RESEARCH/CONTEXT idealization — dot_topics.md documents the OBSERVED file-type set (path/completion/aliases/config/eval/install) as a superset of the 4-type model CONTEXT cited. Attribute-prefix inconsistencies (`rust/path.zsh`, `system/path.zsh.tmpl` lacking `executable_`) FLAGGED in both docs but DELIBERATELY NOT NORMALIZED in Phase 0.5 — renaming would change destination file mode and break zero-functional-diff exit-gate. Defer to Phase 0.
- **(Plan 02)** docs/conventions.md section 2 states `.chezmoiscripts/` is "currently FLAT" and forward-references Phase 0's OS-nesting refactor — this is the load-bearing before-state baseline that Phase 0's structural change will read against.
- **(Plan 02)** Canonical "is my repo clean?" command (`chezmoi diff -x externals`) lives in docs/conventions.md section 9 — per RESEARCH Pitfall A. Plans 04, 05, 06 should cite the doc rather than repeat the rationale.
- **(Plan 02)** Human-verify checkpoint attestation pattern: on user "approved" resume, write a committed `{plan}-attestation.md` capturing resume signal + timestamp + paths reviewed + per-step spot-checks. Gives Phase 0 a grep-able evidence point that docs were reviewed against reality on a known date.

### Open TODOs
- Phase 0.5 in flight. Wave 1 fully closed (Plans 01 + 02 + 03). Wave 2 (Plans 04 + 05) ready to launch in parallel.
- **Plan 06 carries the Mac work portion of AUD-04** (CRLF-in-index pre-check + `.gitattributes` validation) — human-in-loop per Pitfall E. Cannot be autonomously verified from Mac personal.
- **Plan 06 also carries the Mac work portion of state-preview** (scriptState + entryState capture + cross-machine deltas) — human-in-loop, requires physical or SSH access.

### Blockers
- None.

### Tracked Lookups (per PROJECT.md — Teague confirms during execution)
- Social Stream Ninja install path on Windows (may be full Electron app, not browser source) — surfaces in Phase 2
- WezTerm Windows config status — does existing cross-platform config Just Work — surfaces in Phase 2
- Microsoft Office license type (M365 subscription vs perpetual) — surfaces in Phase 2

## Session Continuity

**Last action:** Completed Plan 00.5-02 (docs): `docs/conventions.md` (173 lines, 10 H2 sections) + `docs/dot_topics.md` (157 lines, 6 sections) land grounded in 8-section live-tree inspection (`00.5-02-tree-notes.md`). Attribute-prefix inconsistencies (rust/path.zsh, system/path.zsh.tmpl) FLAGGED for Phase 0 — not normalized. Teague approved both docs end-to-end via human-verify checkpoint; "approved" resume signal recorded in `00.5-02-attestation.md`. AUD-05 PASS (was PENDING in Plan 01). Pitfall 22 resolved. 4 atomic commits (a75cd43, 2636709, ba0c7c8, 26652d1).

**Next action:** Launch Wave 2 — Plans 04 (flameshot-removal, AUD-03) + 05 (packages-audit, AUD-01 + AUD-02) in parallel. Both have docs/conventions.md as input.

**Stopped at:** Completed `00.5-02-docs-PLAN.md` 2026-05-28T02:35:11Z (Wave 1 fully closed).

**Open questions for next session:** None at Plan 02 level. Phase-level reminders unchanged from Plan 03 close: Mac work CRLF pre-check + Mac work `chezmoi diff -x externals` exit-gate + Mac work state-preview capture are human-in-loop tasks Plan 06 schedules; Mac personal `.zshrc` DEBUG=1 drift reconciliation is also Plan 06.

---
*State initialized: 2026-05-27 after roadmap creation*
*Last updated: 2026-05-28 after Plan 00.5-02 completion (Wave 1 closed)*
