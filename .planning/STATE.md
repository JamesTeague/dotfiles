---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: completed
stopped_at: "Completed `00.5-05-packages-audit-PLAN.md` 2026-05-28T03:35Z (AUD-01 + AUD-02 done; Wave 2 fully closed; Plan 06 exit-gate is the final Phase 0.5 deliverable)."
last_updated: "2026-05-28T03:35Z"
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

**Current Focus:** Phase 0.5 (Audit & Documentation) — Wave 1 fully closed (Plans 01 + 02 + 03). Wave 2 FULLY CLOSED (Plan 04 AUD-03 + Plan 05 AUD-01 + AUD-02). Plan 06 exit-gate is the final Phase 0.5 deliverable.

## Current Position

**Phase:** 00.5-audit-documentation
**Plan:** Wave 1 complete (01 + 02 + 03); Wave 2 complete (04 + 05); Plan 06 exit-gate remains
**Status:** Plan 05 landed; only Plan 06 (exit-gate) remains in Phase 0.5
**Progress:** Phase 0/6 plans done · 0.5 sub-progress 5/6 plans `█████░`

## Performance Metrics

| Metric | Value |
|--------|-------|
| Phases planned | 1/6 (0.5 planned; others pending) |
| Phases complete | 0/6 |
| Plans complete (Phase 0.5) | 5/6 |
| v1 requirements mapped | 69/69 |
| v1 requirements complete | 6/69 (SS-01, AUD-01, AUD-02, AUD-03, AUD-04, AUD-05) |
| Pitfalls mitigated in roadmap | 11 of 22 surfaced in PITFALLS.md (the critical ones); Pitfall 22 (dot_topics undocumented) resolved by Plan 02; Pitfall D (run_onchange re-fire on packages.yaml change) mitigated by Plan 05's approved-brew-bundle snapshot |

| Plan | Tasks | Files | Duration |
|------|-------|-------|----------|
| 00.5-01 wave0-harness | 3 | 5 | 5m |
| 00.5-02 docs | 4 (3 auto + 1 human-verify) | 4 | 6m active (spanned checkpoint pause) |
| 00.5-03 gitattributes-statepeek | 2 | 2 | 3m |
| 00.5-04 flameshot-removal | 3 (2 auto + 1 human-verify) | 1 source-delete + 2 planning notes; destination + 2 entryState keys (off-tree) | 25m active (spanned checkpoint pause) |
| 00.5-05 packages-audit | 3 (2 auto + 1 human-verify) | 3 (packages.yaml + candidates.md + approved-brew-bundle.txt) | 45m active (spanned checkpoint pause) |

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
- **(Plan 04)** State-only chezmoi cleanup pattern: when destination + entryState need reconciliation but other drift exists that's owned by a later plan, use `chezmoi state delete --bucket=entryState --key=<absolute-path>` per tracked entry instead of `chezmoi apply`. Avoids cross-plan side effects (Plan 04 vs Plan 06's `.zshrc` DEBUG=1 reconciliation). Teague explicitly approved this approach at Task 3 checkpoint with "approved state-only".
- **(Plan 04)** chezmoi state entries for a directory + its file are SEPARATE keys (chezmoi 2.70.4); cleanup must delete both. Enumerate via `chezmoi state get-bucket --bucket=entryState | grep -A2 <path>` before deletion.
- **(Plan 04)** RESEARCH-vs-reality delta on Pitfall C: after source delete, `chezmoi managed | grep flameshot` and `chezmoi diff -x externals | grep flameshot` were BOTH SILENT on Mac personal — predicted "orphan visible" did not manifest. Only entryState retained the orphan keys. Implication for Plan 06 exit-gate: add `chezmoi state dump | grep <path>` step for any Phase-0-deletion path, since `chezmoi managed`/`diff` are insufficient discovery surfaces for stale entryState entries.
- **(Plan 04)** Reversibility-via-baseline-notes pattern: before destructive ops on chezmoi-tracked files, capture mode/size/sha + verbatim contents into `.planning/phases/XX/<plan>-baseline.md`. Git history covers source recovery; destination state + entryState fingerprint are NOT in git and must be captured separately.
- **(Plan 04)** Empty (`--allow-empty`) git commits are valid task anchors when all operations are out-of-tree (destination filesystem + boltdb). Commit body becomes the audit trail. Pattern used for Plan 04 Task 3 to keep unrelated pre-existing working-tree changes (`config.json`, nvim plugin files) out of plan scope.
- **(Plan 05)** Decision-merge fallback protocol for human-verify checkpoint resumes: when Teague returns "approved" with explicit rule "Decision overrides Recommendation; blank Decision → Recommendation verbatim", apply the rule deterministically and capture the derivation (a) in the artifact itself (Final Commit Manifest section) AND (b) in the commit body. Avoids re-prompting on default-correct rows; preserves audit trail.
- **(Plan 05)** Hand-edit-over-yaml-roundtrip pattern: for LIGHT-scope YAML mutations (under ~15 edits) where style preservation matters (single-quoted strings, inline comments, key ordering), targeted Edit tool calls beat PyYAML/ruamel round-trip. Round-trip is the right call for bulk transforms; hand-edit is right for surgical scope. Captured for AUD-02 vs Phase 0 TAX-05 framing.
- **(Plan 05)** Upstream-formula-rename pattern: when upstream renames (python3 → python@3.14, npm → node, gpg → gnupg), edit in place (RENAME, not DELETE+ADD). Verify the canonical name is already installed on the active machine to confirm brew bundle re-fire is no-op. RENAME and MOVE can apply together (localstack-cli → localstack across blocks).
- **(Plan 05)** chezmoi apply --dry-run --verbose exits NONZERO when it hits a pre-existing interactive prompt in source (e.g., .zshrc:80 DEBUG=1). Filter dry-run output by pattern OR reconcile drift first — exit-code gating alone produces false negatives. Plan 06 input.
- **(Plan 05)** Snapshot-byte-equal verification: `chezmoi execute-template < template > /tmp/out && diff /tmp/out checks/approved-snapshot.txt` is the canonical "packages.yaml didn't accidentally change" gate. full.sh step 5 owns this. Re-snapshot when packages.yaml legitimately changes (next: Phase 0 TAX-05).

### Open TODOs
- Phase 0.5 nearly complete. Wave 1 fully closed (Plans 01 + 02 + 03). Wave 2 fully closed (Plan 04 AUD-03 done; Plan 05 AUD-01 + AUD-02 done). Only Plan 06 (exit-gate) remains.
- **Plan 06 carries the Mac work portion of AUD-04** (CRLF-in-index pre-check + `.gitattributes` validation) — human-in-loop per Pitfall E. Cannot be autonomously verified from Mac personal.
- **Plan 06 also carries the Mac work portion of state-preview** (scriptState + entryState capture + cross-machine deltas) — human-in-loop, requires physical or SSH access.

### Blockers
- None.

### Tracked Lookups (per PROJECT.md — Teague confirms during execution)
- Social Stream Ninja install path on Windows (may be full Electron app, not browser source) — surfaces in Phase 2
- WezTerm Windows config status — does existing cross-platform config Just Work — surfaces in Phase 2
- Microsoft Office license type (M365 subscription vs perpetual) — surfaces in Phase 2

## Session Continuity

**Last action:** Completed Plan 00.5-05 (packages-audit, AUD-01 + AUD-02). 3-task plan: candidate list populated via two-signal cross-check (00.5-packages-candidates.md, bd8148b) → human-verify checkpoint approved by Teague with explicit fallback rule ("Decision overrides Recommendation; blank Decision → Recommendation verbatim") → Final Commit Manifest derived + applied (b8094e6). Manifest summary: 4 DELETE / 5 MOVE group ops (12 items) / 3 RENAME / 1 POST-CLEANUP (work.core block removed) / 61 KEEP / 2 deferred categories. Verified: YAML structurally valid (ruby YAML.load_file passes); chezmoi execute-template renders 129 lines cleanly; approved-brew-bundle.txt snapshot captured at SHA256 18007775...565a00; full.sh step 5 byte-exact diff PASS; quick.sh stays at 12 PASS / 0 PENDING / 0 FAIL; `.zshrc:80` DEBUG=1 confirmed untouched. Pitfall D mitigated: dry-run shows 02-install-packages.sh pending re-fire with new hash (1758801412...), and all 3 renamed brews (python@3.14, node, gnupg) are already installed on Mac personal — brew bundle re-fire will be no-op.

PRIOR action (preserved from previous session entry): Completed Plan 00.5-04 (flameshot-removal, AUD-03). 3-task plan: baseline capture (fd18ccd) → `git rm` source flameshot/ (5ebf307) → human-verify checkpoint approved state-only by Teague → surgical destination + entryState cleanup on Mac personal (2dd08a2, empty commit; out-of-tree ops). Empirical research delta: post-source-delete, `chezmoi managed` and `chezmoi diff -x externals` both silent on flameshot; entryState was the only orphan trace (Pitfall C surface narrower than predicted).

**Next action:** Plan 06 (exit-gate) — Mac personal `.zshrc` DEBUG=1 reconciliation + Mac work CRLF pre-check + Mac work `chezmoi diff -x externals` + Mac work state-preview capture. Final Phase 0.5 deliverable; Plan 06 inputs now include Plan 04's `chezmoi state dump | grep <path>` clean-check pattern AND Plan 05's dry-run-exit-code finding (.zshrc TTY prompt causes nonzero exit; filter by pattern OR reconcile drift first).

**Stopped at:** Completed `00.5-05-packages-audit-PLAN.md` 2026-05-28T03:35Z (AUD-01 + AUD-02 done; Wave 2 fully closed; Plan 06 exit-gate is the final Phase 0.5 deliverable).

**Open questions for next session:** None at Plan 05 level. Phase-level reminders carried forward: Mac work CRLF pre-check + Mac work `chezmoi diff -x externals` exit-gate + Mac work state-preview capture are human-in-loop Plan 06 tasks; Mac personal `.zshrc` DEBUG=1 drift reconciliation also Plan 06; for `work.darwin.*` newly-activated entries from Plan 05's moves, Plan 06 should verify Mac work `brew bundle` outcome (idempotent if installed; reviewable installs otherwise).

---
*State initialized: 2026-05-27 after roadmap creation*
*Last updated: 2026-05-28 after Plan 00.5-05 completion (AUD-01 + AUD-02 closed; Wave 2 fully closed; Plan 06 exit-gate is final Phase 0.5 deliverable)*
