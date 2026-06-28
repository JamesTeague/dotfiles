---
phase: 01-credential-plane
plan: 05
type: execute
wave: 4
depends_on:
  - "1-02"
  - "1-03"
  - "1-04a"
  - "1-04b"
files_modified:
  - .planning/phases/01-credential-plane/1-05-vm-results.md
autonomous: false
requirements:
  - SEC-08
  - SEC-09
  - SEC-10
  - SEC-15
  - SEC-16
must_haves:
  truths:
    - "Parallels VM at jteague@10.211.55.4 restored to snapshot vanilla-fresh-boot-pre-chezmoi"
    - "Stage 1 (chezmoi init --apply against the public dotfiles repo) completes successfully on the fresh VM without auth prompts"
    - "Operator runs Stage 2 (setup-credentials.sh) on the VM and enters the device-flow code at github.com/login/device"
    - "Post-Stage-2: git commit -S --allow-empty produces a signature verified via git log --show-signature (SEC-09)"
    - "Post-Stage-2: ssh -T git@github-personal returns the GitHub welcome message (SEC-10)"
    - "Post-Stage-2: chezmoi git -- remote get-url origin reports git@github-personal:JamesTeague/dotfiles.git (SEC-08)"
    - "Second run of setup-credentials.sh on the SAME (un-restored) VM is a no-op: no new keys registered, exit 0 (idempotency arm of SEC-16)"
    - "Snapshot restored, then setup-credentials.sh --rotate-all run: new keys generated, registered, prior fingerprint logged for cleanup (rotation arm of SEC-12)"
    - "Structural VW-independence grep on the merged source tree returns zero matches in apply-time paths (SEC-15 phase exit gate)"
    - "Operator manually confirms gh ssh-key list shows the registered key and gh gpg-key list shows the registered GPG key (manual-only verifications per VALIDATION.md)"
  artifacts:
    - path: ".planning/phases/01-credential-plane/1-05-vm-results.md"
      provides: "VM verification attestation: snapshot UUID + step-by-step pass/fail log + screenshots-or-stdout-captures + operator notes"
      min_lines: 60
  key_links:
    - from: ".planning/phases/01-credential-plane/checks/vm-e2e.sh"
      to: "VM at jteague@10.211.55.4"
      via: "prlctl + ssh"
      pattern: "10\\.211\\.55\\.4"
    - from: ".planning/phases/01-credential-plane/1-05-vm-results.md"
      to: "SEC-08/09/10/15/16 traceability"
      via: "explicit Requirement-ID -> Result mapping table"
      pattern: "SEC-(08|09|10|15|16)"
---

<objective>
Execute the end-to-end VM verification drill that proves Phase 1 actually works on a fresh machine. This is the phase exit gate — until this plan completes GREEN, Phase 1 is not done regardless of source-tree state.

Purpose: Mac personal and Mac work cannot serve as fresh-install verification targets — they already have keys, gpg state, and chezmoi-tracked entryState (1-CONTEXT.md decision: "first phase where a VM target is part of the verification plan"). The Parallels VM at `jteague@10.211.55.4` with snapshot `vanilla-fresh-boot-pre-chezmoi` is the only environment where the full Stage 1 + Stage 2 chain can be tested without contaminating the operator's daily-driver machines.

This plan has a `checkpoint:human-verify` task because (a) Stage 2 requires the operator to enter a device-flow code in a browser, which is interactive by design, and (b) the operator owns approval of the rotation behavior + manual stale-key cleanup outcome. The harness (`checks/vm-e2e.sh`) automates everything that CAN be automated; the checkpoint covers what cannot.

Output: One attestation file `.planning/phases/01-credential-plane/1-05-vm-results.md` capturing snapshot UUID, step-by-step results, stdout captures from each verification, operator notes, and explicit pass/fail status for SEC-08/09/10/15/16.
</objective>

<execution_context>
@/Users/jteague/.claude/get-shit-done/workflows/execute-plan.md
@/Users/jteague/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/phases/01-credential-plane/1-CONTEXT.md
@.planning/phases/01-credential-plane/1-VALIDATION.md
@.planning/phases/01-credential-plane/checks/vm-e2e.sh
@.planning/phases/01-credential-plane/checks/parallels-helpers.sh
@docs/credential-plane.md

<interfaces>
Verification target details (from 1-CONTEXT.md and 1-RESEARCH.md):
- Host: jteague@10.211.55.4
- Parallels VM snapshot name: `vanilla-fresh-boot-pre-chezmoi`
- Operating system on VM: macOS 26.5.1 arm64
- Pre-condition: SSH from planner Mac to VM works (key already set up during 2026-06-04 discussion session)

Harness scripts (from Plan 1-01):
- `checks/vm-e2e.sh` — composite orchestrator that wraps everything below
- `checks/parallels-helpers.sh` — prlctl wrappers
- `checks/quick.sh` — local structural grep gate (runs LOCALLY before the VM dance)

Phase 1 expected end state on VM:
- ~/.ssh/personal_ed25519 + .pub (ed25519, empty passphrase, comment matches `<host>-personal-<date>`)
- GPG secret key matching email in chezmoi data (EDDSA/Ed25519, empty passphrase)
- ~/.config/chezmoi/chezmoi.toml [data] section contains `signingkey = "<long-key-id>"`
- Rendered ~/.gitconfig.local contains `signingkey = ...` and `[commit] gpgsign = true`
- Rendered ~/.ssh/config contains Host github-personal block
- `chezmoi git -- remote get-url origin` returns `git@github-personal:JamesTeague/dotfiles.git`

Manual-only verifications (from VALIDATION.md — cannot be automated):
1. Device-flow UX during gh auth login (operator types code at github.com/login/device)
2. Stale GitHub-side key cleanup after rotation (operator decides whether to delete prior fingerprint via gh ssh-key delete)

Scenarios to verify, in order (per 1-RESEARCH.md Pitfall 9 snapshot management):
1. Fresh Stage 1 + Stage 2 (snapshot restored beforehand)
2. Idempotency re-run on the same (un-restored) VM — must be no-op
3. Snapshot restored again, then --rotate-all — new keys generated, prior fingerprints logged for cleanup
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Run local structural quick.sh + SEC-15 grep gate before touching VM</name>
  <files>.planning/phases/01-credential-plane/1-05-vm-results.md</files>
  <action>
Pre-flight: confirm the local source tree is in the expected end state before spending VM cycles.

1. From the repo root: `bash .planning/phases/01-credential-plane/checks/quick.sh`. Expected: exit 0, ALL SEC gates GREEN (SEC-02, SEC-05a, SEC-05b, SEC-07, SEC-11, SEC-13-presence, SEC-15). If any FAIL: stop, fix in the appropriate Wave 2 plan, do NOT proceed.

2. Explicit SEC-15 phase exit gate (slightly broader than quick.sh runs):
   - `grep -rEn "\\bbw \\b|bitwardenAttachment|\\{\\{ *bitwarden" home/ --include='*.tmpl'` → MUST return zero matches
   - `grep -rEn "\\bbw \\b|bitwarden" home/.chezmoiscripts/` → MUST return zero matches
   - Permitted exceptions (do NOT count as failures):
     - `home/.chezmoidata/packages.yaml` lines referencing `bitwarden` (cask) or `bitwarden-cli` (formula) — install names, not template calls
     - Design-comment lines in `home/scripts/setup-credentials.sh` that mention VW (e.g., `# VW is runtime-only; this script does not touch it`)

3. Initialize `.planning/phases/01-credential-plane/1-05-vm-results.md` with:
   - YAML frontmatter: `phase: 1, plan: 05, status: in-progress, started: <ISO timestamp>, vm_host: jteague@10.211.55.4, snapshot: vanilla-fresh-boot-pre-chezmoi`
   - Section: "Pre-flight (local source tree)" — paste the quick.sh summary line and the SEC-15 grep results (or "no matches")
   - Empty sections (to be filled by Task 2): "Scenario 1: Fresh Stage 1 + Stage 2", "Scenario 2: Idempotency re-run", "Scenario 3: Rotation", "Manual Verifications", "Requirement ID -> Result Map"

If pre-flight fails, the artifact records the failure and the plan stops — no VM work attempted.
  </action>
  <verify>
    <automated>cd /Users/jteague/.local/share/chezmoi && bash .planning/phases/01-credential-plane/checks/quick.sh > /tmp/preflight-quick.log 2>&1; rc=$?; test "$rc" -eq 0 && test -f .planning/phases/01-credential-plane/1-05-vm-results.md && grep -q "Pre-flight" .planning/phases/01-credential-plane/1-05-vm-results.md && grep -q "Scenario 1" .planning/phases/01-credential-plane/1-05-vm-results.md && grep -q "Requirement ID" .planning/phases/01-credential-plane/1-05-vm-results.md && ! grep -rEn "\\bbw \\b|bitwardenAttachment|\\{\\{ *bitwarden" home/ --include='*.tmpl'</automated>
  </verify>
  <done>checks/quick.sh exits 0 with all SEC gates GREEN locally; SEC-15 grep clean; 1-05-vm-results.md initialized with pre-flight section populated and empty scenario sections ready for fill-in.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 2: Operator-driven VM e2e verification (Scenarios 1, 2, 3 + manual checks)</name>
  <files>.planning/phases/01-credential-plane/1-05-vm-results.md</files>
  <action>This is a checkpoint:human-verify task. Operator executes the scenarios documented under &lt;how-to-verify&gt; below, captures stdout + notes for each scenario into 1-05-vm-results.md, and resumes the plan with the documented signal once all SEC gates show PASS in the Requirement ID -&gt; Result Map. Claude executor MUST NOT attempt to run the VM scenarios autonomously — Stage 2 requires interactive device-flow code entry and the operator owns rotation + manual stale-cleanup decisions.</action>
  <verify><automated>cd /Users/jteague/.local/share/chezmoi && grep -q "^status: complete" .planning/phases/01-credential-plane/1-05-vm-results.md && grep -E "SEC-(08|09|10|15|16).*PASS" .planning/phases/01-credential-plane/1-05-vm-results.md | wc -l | tr -d ' ' | grep -qE "^[5-9]$|^[1-9][0-9]+$"</automated></verify>
  <done>1-05-vm-results.md frontmatter status=complete; Requirement ID -&gt; Result Map shows PASS for SEC-08, SEC-09, SEC-10, SEC-15, SEC-16; operator approval recorded in resume signal.</done>
  <what-built>
    Plans 1-02, 1-03, 1-04a, 1-04b landed: modify_dot_gitconfig.local rewritten, generate-gpg-key.sh deleted, SSH config template added, bitwarden-cli pin documented, setup-credentials.sh authored. The local structural harness (Task 1 above) reports GREEN. Now we need to prove the end-to-end chain works on a fresh machine — the Parallels VM is the only viable target.
  </what-built>
  <how-to-verify>
**Operator steps (execute from the planner Mac with VM running):**

### Scenario 1: Fresh Stage 1 + Stage 2

1. **Restore snapshot** (from planner Mac):
   ```bash
   bash .planning/phases/01-credential-plane/checks/parallels-helpers.sh  # source helpers
   # If PRL_VM_NAME env var not set, prlctl list -a will show the VM name; export PRL_VM_NAME=...
   prl_restore_snapshot
   prl_wait_for_boot  # blocks until SSH responds; up to 5 minutes
   ```
   Record snapshot UUID in 1-05-vm-results.md "Scenario 1" section.

2. **Stage 1** (over SSH):
   ```bash
   ssh jteague@10.211.55.4 'sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply JamesTeague/dotfiles'
   ```
   Expected: exit 0; no auth prompts; brew installs gh, gnupg, jq, chezmoi, bitwarden-cli (and others). Record full stdout in results doc.

3. **Stage 2** (interactive — operator enters device-flow code):
   ```bash
   ssh -t jteague@10.211.55.4 'bash ~/scripts/setup-credentials.sh'
   ```
   When the script prints the device-flow URL + code, navigate in a browser to https://github.com/login/device and enter the code. Authorize the requested scopes (admin:public_key, admin:gpg_key, repo).
   Expected: script completes with "Stage 2 complete" banner. Record stdout + duration.

4. **Verifications** (each over SSH; record stdout):
   - SEC-08: `ssh jteague@10.211.55.4 'chezmoi git -- remote get-url origin'` returns `git@github-personal:JamesTeague/dotfiles.git`
   - SEC-09: `ssh jteague@10.211.55.4 'mkdir -p /tmp/v && cd /tmp/v && git init -q && git commit -S --allow-empty -m phase1 && git log --show-signature -1'` — output contains "Good signature" (or "gpg: Signature made" if older GnuPG)
   - SEC-10: `ssh jteague@10.211.55.4 'ssh -T git@github-personal'` returns "Hi <username>! You've successfully authenticated..."
   - SSH key shape: `ssh jteague@10.211.55.4 'ssh-keygen -lf ~/.ssh/personal_ed25519.pub'` reports ED25519
   - GPG key matches signingkey: `ssh jteague@10.211.55.4 'KID=$(chezmoi data | jq -r .signingkey); gpg --list-secret-keys --keyid-format LONG | grep -q "$KID" && echo MATCH'` prints MATCH
   - Rendered gitconfig: `ssh jteague@10.211.55.4 'grep -E "signingkey|gpgsign" ~/.gitconfig.local'` shows both

### Scenario 2: Idempotency re-run (do NOT restore snapshot)

1. `ssh jteague@10.211.55.4 'bash ~/scripts/setup-credentials.sh'` — expected: skip logs for SSH already registered, GPG already registered, signingkey already in chezmoi data; exit 0.
2. Confirm no new GitHub-side keys: `gh ssh-key list --json title | jq '. | length'` (from operator's authed session) should be same count as after Scenario 1.
3. Record stdout + key count in results doc.

### Scenario 3: Rotation (restore snapshot first)

1. `prl_restore_snapshot && prl_wait_for_boot` again.
2. Re-run Stage 1.
3. `ssh -t jteague@10.211.55.4 'bash ~/scripts/setup-credentials.sh'` — fresh Stage 2.
4. Note the new SSH fingerprint + GPG key ID.
5. `ssh -t jteague@10.211.55.4 'bash ~/scripts/setup-credentials.sh --rotate-all'` — expected: prior fingerprint + key ID logged to stdout for cleanup; new key generated + registered; exit 0.
6. Confirm new fingerprint ≠ Scenario-3-step-3 fingerprint.
7. **Manual cleanup decision**: operator inspects the logged prior fingerprint and decides whether to `gh ssh-key delete <id>` / `gh gpg-key delete <id>`. Record the decision in "Manual Verifications" section.

### Manual Verifications

1. **Device-flow UX (Scenario 1)**: Did the script provide clear instructions? Did the device-flow code entry succeed? Any UX friction → log as Phase 2 follow-up.
2. **Stale-key cleanup (Scenario 3)**: After rotation, was the prior fingerprint clearly logged? Was the manual cleanup procedure (gh ssh-key delete) straightforward? Any friction → log as Phase 1 docs improvement.

### Completion criteria

All three scenarios complete; SEC-08/09/10/15/16 all PASS in the Requirement ID -> Result Map section; 1-05-vm-results.md status updated to `complete`.
  </how-to-verify>
  <resume-signal>Type "approved" when 1-05-vm-results.md is fully populated and all SEC-08/09/10/15/16 gates show PASS. If any scenario fails, describe what failed and which Wave 2 plan owns the fix (1-02, 1-03, 1-04a, or 1-04b).</resume-signal>
</task>

</tasks>

<verification>
After the checkpoint resumes with "approved":
- `.planning/phases/01-credential-plane/1-05-vm-results.md` has `status: complete` in frontmatter and a populated Requirement ID -> Result Map with PASS for SEC-08/09/10/15/16
- All three scenario sections contain captured stdout + operator notes
- Manual Verifications section documents device-flow UX outcome + stale-key cleanup decision
- `bash .planning/phases/01-credential-plane/checks/quick.sh` exits 0 (local structural state unchanged from Task 1)
</verification>

<success_criteria>
- Phase 1 exit gate: all 12 active requirements (SEC-02, SEC-05, SEC-07, SEC-08, SEC-09, SEC-10, SEC-11, SEC-12, SEC-13, SEC-14, SEC-15, SEC-16) are GREEN
- Idempotency proven on un-restored VM (Scenario 2)
- Rotation proven on freshly-restored + bootstrapped VM (Scenario 3)
- Structural VW-independence verified end-to-end (SEC-15 grep + no VW calls during Stage 1 apply)
- Operator notes captured for any device-flow / stale-cleanup friction → fed into docs/credential-plane.md as Phase 1 polish if needed
</success_criteria>

<output>
After the checkpoint approves, create `.planning/phases/01-credential-plane/1-05-SUMMARY.md` covering: scenario-by-scenario pass/fail, full Requirement ID -> Result Map for all 12 active SEC requirements, snapshot UUID + duration of each scenario, operator-surfaced friction (if any), manual-cleanup decisions, and final phase status (Phase 1 COMPLETE if all PASS).
</output>
