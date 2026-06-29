---
phase: 01-credential-plane
plan: 05
subsystem: vm-verification
tags: [vm-e2e, bootstrap, device-flow, idempotency, rotation, SEC-08, SEC-09, SEC-10, SEC-12, SEC-15, SEC-16]
dependency_graph:
  requires:
    - 1-01 (quick.sh harness — pre-flight SEC gates)
    - 1-02 (modify_dot_gitconfig.local rewritten — signingkey rendering)
    - 1-03 (SSH config template — github-personal host alias)
    - 1-04a (setup-credentials.sh skeleton — auth + SSH half)
    - 1-04b (setup-credentials.sh — GPG + signingkey + remote-rewrite)
  provides:
    - .planning/phases/01-credential-plane/1-05-vm-results.md (verification attestation)
    - 6 source fixes for Stage 1 / Stage 2 design gaps (committed to master)
  affects:
    - Phase 1 exit gate (all 12 active SEC requirements GREEN)
    - 2 deferred follow-ups (CLT bootstrap docs, Stage 1 init-cmd revision)
tech_stack:
  added: []
  patterns:
    - chezmoi.toml pre-write workaround (TTY-less promptOnce bypass)
    - softwareupdate -i for headless CLT install (touch-file trick)
    - brew trust --tap (Homebrew 4.7+ non-interactive bundle prerequisite)
    - defaults read MobileMeAccounts guard (App Store sign-in detection)
    - gh api user/keys + user/gpg_keys (TSV-only subcommand workaround)
    - fingerprint + two-pass GPG delete (--delete-secret-keys then --delete-keys)
    - fix-in-place + commit pattern during verification (each finding atomic)
key_files:
  created:
    - .planning/phases/01-credential-plane/1-05-vm-results.md (236 lines)
  modified:
    - home/.chezmoidata/packages.yaml (drop kindle, add gh)
    - home/.chezmoiscripts/run_onchange_before_02-install-packages.sh.tmpl (brew trust --tap)
    - home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl (App Store sign-in guard)
    - home/scripts/setup-credentials.sh (gh api migration + GPG rotation delete fix)
decisions:
  - "VM verification scenarios re-executed from freshly-restored snapshot after prior session crashed mid-Scenario-1"
  - "Workaround for Stage 1 TTY/promptOnce limitation: pre-write ~/.config/chezmoi/chezmoi.toml with [data] block before init (Once functions read existing values silently)"
  - "Scenario 2 idempotency root cause was gh ssh-key list --json / gh gpg-key list --json — neither subcommand supports --json (TSV-only); 2>/dev/null swallowed the unknown-flag error. Migrated to gh api user/keys / user/gpg_keys."
  - "Scenario 3 GPG rotation root cause was gpg --batch --yes --delete-secret-and-public-key <SHORTID> silently failing — modern GPG refuses secret-key deletion via short-id even in batch mode. Fix uses long fingerprint + two-pass delete."
  - "Fix-in-place + commit pattern (vs. log-and-defer) was the right call given 6 of 8 findings had clean source fixes; the 2 deferred (CLT bootstrap, Stage 1 init-cmd) are docs/script work that warrants discussion-phase scoping."
  - "Scenario 3 partial PASS (mechanics only, no fresh-snapshot rerun) accepted as sufficient for Phase 1 exit gate; full rerun deferred since current VM state has all 6 source fixes baked in — future Scenario 3 reruns can skip the brew install phase if the VM is re-snapshotted in current state."
metrics:
  duration_minutes: ~120 (this session; prior crashed session contributed ~140 min including kindle finding)
  tasks_completed: 2
  files_created: 1
  files_modified: 4
  source_fix_commits: 6
  findings_total: 8
  findings_fixed_in_source: 6
  findings_deferred: 2
  completed_date: "2026-06-28"
---

# Phase 1 Plan 05: VM Verification Summary

**One-liner:** End-to-end Stage 1 + Stage 2 verification on a vanilla Parallels macOS VM surfaced 8 Phase 1 design gaps; 6 fixed in source during the session (kindle cask, tap trust, missing gh formula, mas App Store guard, gh-api migration for idempotency check, GPG rotation fingerprint delete), 2 deferred to follow-up (CLT bootstrap, Stage 1 init-cmd revision); all 12 active SEC requirements GREEN at session close.

## What Was Done

### Pre-flight (Task 1)

Already complete from the prior (crashed) session — `84baa19 chore(01-05):
initialize vm-results artifact + pre-flight PASS`. All 36 SEC gates GREEN
locally; SEC-15 explicit grep clean. quick.sh re-verified GREEN at session
close.

### VM Scenarios (Task 2 checkpoint:human-verify)

**Scenario 1: Fresh Stage 1 + Stage 2** — GREEN end-to-end. Brew install
+ casks completed, mas block skipped cleanly, device-flow auth succeeded,
SSH + GPG keys generated + registered, chezmoi signingkey written,
gitconfig.local re-rendered, remote rewritten to `git@github-personal`.
All 6 SEC verifications PASS.

**Scenario 2: Idempotency** — GREEN after fix #7 (commit `e0ec7b9`).
Initial run regenerated GPG key due to broken `--json` flag usage; fixed
+ pollution cleaned + re-run produced true no-op (skip messages for both
SSH and GPG; key counts unchanged).

**Scenario 3: Rotation** — PARTIAL GREEN. Initial `--rotate-all` rotated
SSH cleanly but GPG was no-op (idempotency-skip race vs. silent-failing
local delete). Fixed (commit `6b7c518`) and retested: both fingerprints
changed, chezmoi signingkey updated to new GPG key, old IDs/fingerprints
printed for manual cleanup. Full fresh-snapshot rerun deferred.

## Findings (source fixes)

| Finding | Commit | One-liner |
|---|---|---|
| #1 kindle cask defunct | `4703baa` | Drop from packages.yaml — Amazon Kindle is web-app sufficient. |
| #4 untrusted taps refused in non-interactive bundle | `064ba57` | Pre-call `brew trust --tap` for lazygit, lazydocker, nikitabobko. |
| #5 gh formula missing | `841f685` | Add `gh` to roles.dev.core.brews — script comment already claimed it. |
| #6 mas hangs on no-App-Store-signin | `2e2eb60` | Guard with `defaults read MobileMeAccounts Accounts \| grep -q AccountID` + skip with operator message. |
| #7 gh --json flag doesn't exist for key list subcommands | `e0ec7b9` | Migrate to `gh api user/keys` / `gh api user/gpg_keys` (support --jq). |
| #8 GPG rotation local delete broken | `6b7c518` | Use long fingerprint + two-pass delete (`--delete-secret-keys` then `--delete-keys`). |

## Findings (deferred follow-ups)

| Finding | Owner | Why deferred |
|---|---|---|
| #2 vanilla macOS has no CLT | new Stage 0 doc + optional bootstrap-clt.sh | Docs scope decision — `softwareupdate -i` recipe works but warrants discussion-phase framing (Stage 0 vs. Stage 1 ownership, where in docs to land). |
| #3 Stage 1 TTY/promptOnce barrier | template + plan revision | Real-machine UX is interactive prompts (correct). Headless verification needs either `ssh -t` + manual answer or the pre-write workaround documented. Worth a small discuss-phase. |

## Pitfalls Avoided (in re-verification design)

1. **Recovery without losing prior work** — prior session crashed mid-
   Scenario-1; kindle commit (`4703baa`) was the only signal. Confirmed
   via STATE.md + git log forensics before restoring snapshot. No
   contention with stale state.
2. **Operator overhead minimized** — baked passwordless sudoers into the
   new snapshot at session start so all SSH-driven commands could
   proceed without password prompts.
3. **Scenario 2 pollution caught + cleaned** — broken idempotency on
   initial Scenario 2 run registered a dup GPG key (`92168368EB6C0C68`).
   Cleaned from GitHub (`gh gpg-key delete <key-id-text>`) + locally
   (`gpg --batch --yes --delete-secret-keys <fingerprint>`) + chezmoi.toml
   restored via sed before re-running fixed script.

## Lessons Learned

1. **`gh` subcommand flag coverage is uneven** — `gh ssh-key list` and
   `gh gpg-key list` are TSV-only; `gh api` always supports `--jq`. Default
   to `gh api` for any scriptable / structured-output workflow.
2. **`gpg --batch --yes --delete-secret-and-public-key <SHORTID>` silently
   fails** in modern GPG. Always use long fingerprints for batch delete,
   and use the two-pass form (`--delete-secret-keys` then `--delete-keys`).
3. **`2>/dev/null` on a query whose output drives a control-flow decision
   is dangerous.** Both Finding #7 (gh --json) and #8 (gpg delete) hid
   silent failures under `2>/dev/null` + `|| true`. Worth a code-review
   pass on all such patterns in the script.
4. **VM verification can be a fix-in-place loop, not just a discover-and-
   defer audit** — the atomic commit pattern (1 finding → 1 fix → 1
   commit → re-trigger → next finding) kept context tight and the
   verification artifact accurately attested to the LATEST commit.
5. **`promptStringOnce`/`promptBoolOnce` chezmoi data fields can be
   pre-populated via `~/.config/chezmoi/chezmoi.toml`** — useful for
   headless verification harnesses that can't drive a TTY.

## Verification

- `1-05-vm-results.md` frontmatter `status: complete`
- Requirement ID → Result Map: 12/12 active SEC requirements PASS
- SEC-08/09/10/15/16 PASS lines: 8 (plan's auto-verify required ≥5)
- Local `bash .planning/phases/01-credential-plane/checks/quick.sh` exits 0
  (36 PASS, 0 PENDING, 0 FAIL)

## Phase 1 Exit Status

**Phase 1 (credential-plane) ready for closure** pending:
1. Operator approval of Scenario 3 partial-pass framing.
2. Optional: full Scenario 3 rerun against a freshly-restored snapshot
   (current VM state has all 6 source fixes baked in — re-snapshot here
   to make future reruns skip the brew install phase).
3. Two deferred follow-ups (#2 CLT bootstrap, #3 Stage 1 init-cmd) get
   their own discussion-phase scoping before Phase 1 is marked closed.
