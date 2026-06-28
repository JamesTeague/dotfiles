---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: verifying
stopped_at: Completed 01-credential-plane/1-04b-setup-credentials-gpg-signingkey-PLAN.md
last_updated: "2026-06-28T20:04:43.904Z"
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 9
  completed_plans: 8
  percent: 100
---

# Project State: chezmoi Modernization

**Last updated:** 2026-06-28

## Project Reference

**Core Value:** A new machine — any OS in the fleet — can be set up day-1 via a single `chezmoi init --apply` flow plus one explicit credential-bootstrap script, and arrive at a fully-configured, identity-signed, role-appropriate state without artisanal touch-up. Stage 1 (`chezmoi init --apply`) is auth-free against a public repo; Stage 2 (`setup-credentials.sh`) generates per-machine keys locally and registers them with the relevant services.

**Current Focus:** **Phase 1 CONTEXT captured 2026-06-04** (architecture pivoted). Next: `/gsd:plan-phase 1` against `phases/01-credential-plane/1-CONTEXT.md`.

## Current Position

**Phase:** 0-structural-refactor — COMPLETE (3/3 plans + cutover both Macs)
**Plan:** Phase 0 closed; Phase 1 not yet planned
**Status:** Both Macs cutover GREEN. chezmoi diff -x externals empty + dry-run clean on both. NODE_EXTRA_CA_CERTS migrated on Mac work. ~/bin teardown verified on both. Three follow-up commits landed (heredoc fix, cask renames, Step 7 stderr capture) — convention notes added in § 10.4.6 and § 10.4.7.
**Progress:** [██████████] 100%

## Performance Metrics

| Metric | Value |
|--------|-------|
| Phases planned | 1/6 (0.5 planned; others pending) |
| Phases complete | 1/6 (0.5) |
| Plans complete (Phase 0.5) | 6/6 |
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
| 00.5-06 exit-gate | 6 (3 auto + 3 human-verify) | 4 created (drift-reconciliation, exit-gate-report, state captures ×2, recovery script) + 2 modified (state-preview, packages.yaml line 120 hot-patch) | ~3h active across 2 sessions |
| 0-03-docs | 1 | 1 modified (docs/conventions.md +128 lines) | ~15m |
| Phase 01-credential-plane P01 | 23 | 3 tasks | 6 files |
| Phase 01-credential-plane P04a | 12 | 1 tasks | 1 files |
| Phase 01-credential-plane P03 | 22 | 2 tasks | 3 files |
| Phase 01-credential-plane P02 | 15 | 2 tasks | 2 files |
| Phase 01-credential-plane P04b | 18 | 2 tasks | 2 files |

## Accumulated Context

### Locked Decisions (from PROJECT.md + research)
- Stay on chezmoi (Nix rejected — no native Windows)
- 3-role taxonomy: `dev` / `gaming` / `lite`; `personal` is orthogonal flag (not absorbed into role)
- VaultWarden via Cloudflare tunnel — self-hosted, runtime password vault accessed via `bw` CLI. NOT used in chezmoi templates at apply time (pivoted 2026-06-04). `bitwardenSecrets` was already known not to work against VaultWarden; `bitwarden*` template functions are no longer used at all in the new architecture.
- Per-purpose SSH keys (purpose-named: `personal`, `work`; host aliases like `github-personal`, `gitlab-bluebeam`)
- **Per-machine GPG and SSH keypairs** (pivoted 2026-06-04 from canonical-GPG-in-VW). Generated locally on each machine by `setup-credentials.sh`, registered with services via `gh ssh-key add` / `gh gpg-key add`. `generate-gpg-key.sh` DELETED in Phase 1 (SC #5 carryover from Phase 0).
- Linux package management: apt + mise (NOT Linux Homebrew)
- Hybrid migration: Phase 0 refactor branch (atomic) → additive phases 1-4
- **Repo is PUBLIC** (pivoted 2026-06-04 from "going private"). With per-machine keypair architecture and no encrypted bootstrap kit, there's no longer a privacy gain from going private; public enables auth-free Stage 1 bootstrap.
- Non-standard phase numbering retained: 0.5, 0, 1, 2, 3, 4
- **No bootstrap kit** (pivoted 2026-06-04). Regenerable credentials don't need disaster-recovery encryption; kit complexity deleted from Phase 1 scope.
- PowerShell 7+ only (5.1 explicitly out of scope)
- **(Plan 1-02)** Use `get . "key"` (not `{{ .key }}` or `{{- if .key }}`) in chezmoi templates for data fields that may be absent at template-evaluation time. Go template engine errors with "map has no entry for key" before any `if` guard can evaluate — `get` returns empty string for absent keys and enables correct truthiness checks via local variable.
- **(Plan 1-02)** Deleted chezmoi-managed files require per-machine entryState cleanup post-merge; `chezmoi managed` and `chezmoi diff` are silent on stale entries (Phase 0.5 Plan 04 lesson). Cleanup for `~/scripts/generate-gpg-key.sh` documented in Task 2 commit message: `chezmoi state delete --bucket=entryState --key=/Users/jteague/scripts/generate-gpg-key.sh` + `rm -f ~/scripts/generate-gpg-key.sh`.
- **(Plan 1-02)** Stage-1 machines (after `chezmoi apply`, before `setup-credentials.sh`) have `.signingkey` absent from chezmoi.toml [data] by design; unsigned commits are the correct graceful default state — not a failure. Signing activates after Plan 1-04b's `write_signingkey()` runs.
- **(Plan 1-03)** File-presence gating on `~/.ssh/work_ed25519` (not `.employer` data field): Phase 0 did not introduce an employer field — `[data]` in `chezmoi.toml.tmpl` contains only `personal/name/email/role/wsl`. Per 1-RESEARCH Open Question 8, `stat` template helper on `~/.ssh/work_ed25519` is the fallback gate for `gitlab-bluebeam` block. If employer field is preferred, Phase 0 amendment required first.
- **(Plan 1-03)** `bitwarden-cli` formula pin uses unversioned name + PIN comment: `bitwarden-cli@<ver>` has no upstream Homebrew formula. The `brew extract` ritual is documented in `docs/credential-plane.md` and executed manually per machine; packages.yaml carries the PIN comment as the authoritative marker.

### Critical Pitfalls Baked Into Phases
- Phase 0: `promptStringOnce` everywhere + per-machine cutover ritual + `generate-gpg-key.sh` DELETED (not renamed) — DEFERRED to Phase 1 per Phase 0 CONTEXT amendments
- Phase 1: `bw` CLI version pinned against VaultWarden 1.36.0 (Pitfall 3 mitigation survives the pivot — `bw` still used for runtime password lookup); Pitfall 10 (VW unreachable bricks apply) **structurally eliminated** by removing VW from apply path; structural VW-independence check replaces runtime vault-offline drill
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
- **(Plan 06)** Capture-to-file-then-commit pattern for human-in-loop reconciliation when operator is on a different machine with limited paste budget (here: Mac work physical access, no SSH per Bluebeam policy). Redirect outputs to `.planning/.../captures/<task>.txt`, commit + push from operator machine, pull + read on planner machine. Used 3× in Plan 06.
- **(Plan 06)** Foreground-vs-redirect distinction for `chezmoi apply`: when apply may prompt (sudo, kext, package conflict), run in foreground NOT via heredoc-with-redirect (prompts disappear, look like hangs). Canonical stuck-on-tty diagnostic: `ps aux | grep ... | grep STAT` — look for `S+`.
- **(Plan 06)** Single-justified-escalation gate-pass pattern: when reconciliation requires introducing a new axis Phase 0 owns (here: employer axis for Bluebeam corporate cert), document the entry as explicit escalation in drift-reconciliation.md with justification, accept non-empty diff for THAT entry only, close via "empty OR only justified escalations" criterion. Applied for `.zshrc` NODE_EXTRA_CA_CERTS on Mac work.
- **(Plan 06)** `exact_<dir>`-as-root-cause diagnosis: when `chezmoi diff` shows destination as `deleted file mode 100755` with FULL content, file isn't in entryState — it's an `exact_` directive enforcing dir contents. `chezmoi state delete` won't help; either rename source dir OR move destination to non-`exact_`-managed location. Caught for `~/bin/start-aws-mcp.sh` on Mac work; resolved by `mv ~/bin/start-aws-mcp.sh ~/.local/bin/`.
- **(Plan 06)** zsh `--key=...` CLI flag parsing pitfall: when heredoc rendering splits `--key` from `=/path`, zsh EQUALS option treats `=/path` as a command-path lookup → `zsh: no such file or directory: --key=/...`. Workaround: space-separated `--key /path`. Surfaced on Mac work chezmoi 2.69.4; not reproduced on Mac personal 2.70.4.
- **(Plan 06)** Plan 05 reality correction: `localstack-cli` was NOT misnamed — both `localstack` (deprecated, sunset 2027-04-12) and `localstack-cli` (maintained) exist in `localstack/tap`. Plan 05's candidate review only checked the proposed-new name. Reverted in `3725e90`. Phase 0 package-audit re-pass should verify proposed renames against (a) is-new-deprecated, (b) does-old-still-exist.

### Phase 0 Decisions (from completed plans)
- **(Plan 0-01)** packages.core.casks (fonts, bitwarden, docker-desktop) → roles.dev.darwin.casks (all were Mac-only; correct OS-gated placement).
- **(Plan 0-01)** roles.dev.linux kept non-empty (curl, xclip); empty taps/casks pruned; consumer uses hasKey defense.
- **(Plan 0-01)** exact_bin → private_dot_local/bin/: 5 personal-identity utilities now at ~/.local/bin/ (first on PATH via mise).
- **(Plan 0-01)** cutover-phase-0.sh committed as artifact awaiting operator execution post-merge; NOT executed during plan.
- **(Plan 0-02)** /Applications/<App>.app file-presence guard wraps every mas install call; skip-with-echo when bundle present (resolves mas-list Apple ID invisibility pitfall).
- **(Plan 0-02)** chezmoi execute-template --init not needed for 03-mas.sh.tmpl smoke test (.chezmoidata/ always loaded; --init is only needed for .chezmoi.toml.tmpl init-time functions).
- **(Plan 0-03)** AUD-02 LIGHT inconsistencies #4+#5 (packages.yaml dead-code shape) RESOLVED by Plan 01 restructure; inconsistencies #1, #2, #3, #6 DEFERRED to Phase 1+ (rename changes destination file mode; OS-subdir layout is Phase 3).
- **(Plan 0-03)** state-forge pattern documented: legitimate ONLY when underlying reality verified by another mechanism; never blind-forge. See docs/conventions.md § 10.4.4.
- **(Plan 0-03)** LNX-05 locked decision documented: NO Linux Homebrew; Phase 3 owns apt+mise consumer. See docs/conventions.md § 10.3.

### Open TODOs
- **Phase 0.5 CLOSED.** Phase 0 source-tree work ALSO COMPLETE (3/3 plans). Next: operator-driven cutover ritual on both Macs.
- **Phase 0 cutover required** before Phase 0 can be marked complete: run `bash .planning/phases/0-structural-refactor/cutover-phase-0.sh` on Mac personal (first), then Mac work. Verify `chezmoi diff -x externals` EMPTY on both after cutover.

### Blockers
- None.

### Tracked Lookups (per PROJECT.md — Teague confirms during execution)
- Social Stream Ninja install path on Windows (may be full Electron app, not browser source) — surfaces in Phase 2
- WezTerm Windows config status — does existing cross-platform config Just Work — surfaces in Phase 2
- Microsoft Office license type (M365 subscription vs perpetual) — surfaces in Phase 2

## Session Continuity

**Last action:** Completed Plan 00.5-06 (exit-gate, AUD-04) — closing all of Phase 0.5. 6-task plan executed across 2 sessions (Task 1 on 2026-05-27 evening Mac personal drift reconciliation; Tasks 2-6 on 2026-05-29 afternoon Mac work). Mac personal exit gate verified EMPTY ✓ at SHA `8a7c6d0` (post-rebase, post-Pitfall-D apply, post-localstack-fix). Mac work exit gate PASS via single justified escalation (`.zshrc` `export NODE_EXTRA_CA_CERTS=/Users/jteague/.certs/CAcerts.pem` — Bluebeam corporate cert, escalated to Phase 0 employer-axis design). Mid-flight reconciliations on Mac work: (a) Plan 05 reality correction — `localstack` reverted to `localstack-cli` (Plan 05's MISNAMED diagnosis was backwards; `localstack` is upstream-deprecated). (b) flameshot residue cleanup (manual `rm -rf` worked; `chezmoi state delete --key=...` errored on 2.69.4 zsh — non-blocking; space-separated form worked second time). (c) `~/bin/start-aws-mcp.sh` `exact_bin` directive discovery — initial entryState-orphan hypothesis was wrong; root cause is `home/exact_bin/` strict-mode directive; resolved by `mv` to `~/.local/bin/`. 9 Phase 0 follow-ups captured across `00.5-drift-reconciliation.md` (8 + 1 from Plans 04/05 + 3 new from Plan 06 Task 5: #6 employer axis, #7 chezmoi version-skew, #8/#9 chezmoi behavior + exact_ directive).

PRIOR action: Completed Plan 00.5-05 (packages-audit, AUD-01 + AUD-02). 3-task plan with decision-merge fallback (Decision overrides Recommendation; blank → Recommendation verbatim). Manifest summary: 4 DELETE / 5 MOVE group ops (12 items) / 3 RENAME / 1 POST-CLEANUP (work.core block removed) / 61 KEEP / 2 deferred categories. Note: the `localstack-cli → localstack` RENAME was REVERTED in Plan 06 Task 5 (Plan 05's reality-correction miss; see Plan 06 commit `3725e90`).

**Next action:** Operator-driven cutover ritual on Mac personal first, then Mac work. See `.planning/phases/0-structural-refactor/cutover-phase-0.sh`. Run in collaborative mode (not autonomous) per CLAUDE.md §4. After cutover: `chezmoi diff -x externals` EMPTY on both Macs = Phase 0 merge gate PASS → mark Phase 0 complete.

**Stopped at:** Completed 01-credential-plane/1-04b-setup-credentials-gpg-signingkey-PLAN.md

**Open questions for next session:** None at Phase 0.5 level. Phase 0 should: (a) decide employer/site axis design (escalation owner), (b) decide `home/exact_bin/` rename vs `~/.local/bin/` standard for employer-local tooling, (c) standardize chezmoi version across both Macs (Mac work 2.69.4 → 2.70.4), (d) read all Phase 0 follow-ups #1-#9 in `00.5-drift-reconciliation.md` before scoping the structural refactor.

---
*State initialized: 2026-05-27 after roadmap creation*
*Last updated: 2026-05-29 after Plan 00.5-06 completion — Phase 0.5 CLOSED (all 6 plans done, all 6 requirements verified, both-Mac exit gate PASS)*
