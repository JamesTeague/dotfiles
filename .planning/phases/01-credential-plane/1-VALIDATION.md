---
phase: 1
slug: credential-plane
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash + chezmoi-internal templating; structural greps; live SSH/git smoke tests on VM |
| **Config file** | none — Wave 0 of Phase 1 establishes test scripts under `.planning/phases/01-credential-plane/checks/` (pattern from Phase 0.5 Plan 01) |
| **Quick run command** | `bash .planning/phases/01-credential-plane/checks/quick.sh` |
| **Full suite command** | `bash .planning/phases/01-credential-plane/checks/full.sh` |
| **Estimated runtime** | quick: < 5s · full: 5–15 min (VM-driven Stage 1+2) |

---

## Sampling Rate

- **After every task commit:** Run `bash .planning/phases/01-credential-plane/checks/quick.sh` (structural-only, fast)
- **After every plan wave:** Run `bash .planning/phases/01-credential-plane/checks/full.sh` (adds VM-driven smoke)
- **Before `/gsd:verify-work`:** Full suite must be green on VM (snapshot restored first) AND structural greps green on local source tree
- **Max feedback latency:** quick < 5s; full 5–15 min (snapshot-restore + brew install during Stage 1 dominate)

**Cadence note:** VM full-suite runs are NOT per-commit. Plans batch their VM verifications at wave merge points.

---

## Per-Task Verification Map

> Task IDs are placeholders pending PLAN.md authoring. Each row maps a phase requirement to its automated assertion. Wave 0 establishes the `checks/` harness; subsequent waves implement the behavior the checks assert.

| Req ID | Behavior | Test Type | Automated Command | File Exists | Status |
|--------|----------|-----------|-------------------|-------------|--------|
| SEC-02 | `bw` formula pinned; pin rationale documented | structural | `grep -E "bitwarden-cli.*PIN" home/.chezmoidata/packages.yaml && test -f docs/credential-plane.md` | ❌ W0 | ⬜ pending |
| SEC-05 (a) | `home/scripts/generate-gpg-key.sh` absent | structural | `! test -e home/scripts/generate-gpg-key.sh` | ❌ W0 | ⬜ pending |
| SEC-05 (b) | `modify_dot_gitconfig.local` reads `.signingkey` from chezmoi data, no `output` of deleted script | structural | `! grep -q "output.*generate-gpg-key" home/modify_dot_gitconfig.local && grep -q "\.signingkey" home/modify_dot_gitconfig.local` | ❌ W0 | ⬜ pending |
| SEC-07 | `private_dot_ssh/config.tmpl` exists with purpose-based Host aliases | structural | `grep -q "Host github-personal" home/private_dot_ssh/config.tmpl` | ❌ W0 | ⬜ pending |
| SEC-08 | After Stage 2, chezmoi remote rewritten to `git@github-personal:…` | smoke (VM) | `ssh jteague@10.211.55.4 'chezmoi git -- remote get-url origin \| grep -q "^git@github-personal:"'` | ❌ W0 | ⬜ pending |
| SEC-09 | `git commit -S --allow-empty` produces verified signature on VM | smoke (VM) | `ssh jteague@10.211.55.4 'cd /tmp/verify-repo && git commit -S --allow-empty -m phase1 && git log --show-signature -1 \| grep -E "Good signature\|gpg: Signature made"'` | ❌ W0 | ⬜ pending |
| SEC-10 | `ssh -T git@github-personal` returns GitHub welcome | smoke (VM) | `ssh jteague@10.211.55.4 'ssh -T git@github-personal 2>&1 \| grep -q "successfully authenticated"'` (`ssh -T` exits 1; grep is the assertion) | ❌ W0 | ⬜ pending |
| SEC-11 (new) | `setup-credentials.sh` present, executable, NOT a `run_once_` chezmoi script | structural | `test -x home/scripts/setup-credentials.sh && ! ls home/.chezmoiscripts/*setup-credentials* 2>/dev/null` | ❌ W0 | ⬜ pending |
| SEC-12 (new) | `--rotate-ssh` / `--rotate-gpg` / `--rotate-all` flags documented and functional | smoke (VM) | `ssh jteague@10.211.55.4 'bash ~/scripts/setup-credentials.sh --help \| grep -E "(rotate-ssh\|rotate-gpg\|rotate-all)"'` | ❌ W0 | ⬜ pending |
| SEC-13 (new) | After Stage 2, `~/.ssh/personal_ed25519` exists and is ed25519 | smoke (VM) | `ssh jteague@10.211.55.4 'test -f ~/.ssh/personal_ed25519 && ssh-keygen -lf ~/.ssh/personal_ed25519.pub \| grep -q "ED25519"'` | ❌ W0 | ⬜ pending |
| SEC-14 (new) | After Stage 2, GPG secret key present and matches chezmoi-data `.signingkey` | smoke (VM) | `ssh jteague@10.211.55.4 'KID=$(chezmoi data \| jq -r .signingkey); gpg --list-secret-keys --keyid-format LONG \| grep -q "$KID"'` | ❌ W0 | ⬜ pending |
| SEC-15 (new) | Structural VW-independence: zero `bw`/`bitwarden`/`{{ bitwarden` calls in apply-time paths | structural | `! grep -rEn "(\bbw \b\|bitwardenAttachment\|\{\{ *bitwarden)" home/ --include="*.tmpl" && ! grep -rEn "(\bbw \b\|bitwarden)" home/.chezmoiscripts/` (permitted: `packages.yaml` install names; design comments in `setup-credentials.sh`) | ❌ W0 | ⬜ pending |
| SEC-16 (new) | End-to-end VM verification: signed commit + SSH auth + remote-rewrite + idempotent re-run | smoke (VM) | composite `checks/vm-e2e.sh` orchestrates snapshot restore + Stage 1 + Stage 2 + verifications + re-run + asserts no-op | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Coverage note:** SEC-11 through SEC-16 are NEW requirements introduced by the 2026-06-04 pivot (per-machine keygen + rotation + structural VW-independence + VM-target verification). Planner enumerates these formally against `1-CONTEXT.md` and writes them to REQUIREMENTS.md.

---

## Wave 0 Requirements

- [ ] `.planning/phases/01-credential-plane/checks/lib.sh` — shared helpers (color output, assertion macros). Adapt from `.planning/phases/00.5-audit-documentation/checks/lib.sh`.
- [ ] `.planning/phases/01-credential-plane/checks/quick.sh` — structural greps for SEC-02, SEC-05, SEC-07, SEC-11, SEC-13 (file existence), SEC-15.
- [ ] `.planning/phases/01-credential-plane/checks/full.sh` — quick + VM smokes for SEC-08, SEC-09, SEC-10, SEC-12, SEC-13 (key-type check), SEC-14, SEC-16.
- [ ] `.planning/phases/01-credential-plane/checks/vm-e2e.sh` — composite VM orchestration (Parallels `prlctl snapshot-switch` → Stage 1 → Stage 2 → verifications → idempotency re-run).
- [ ] `.planning/phases/01-credential-plane/checks/parallels-helpers.sh` — `prlctl`-based snapshot management (availability check, snapshot UUID resolution, restore + wait-for-boot).

*Framework install commands: none — bash + ssh + (host-side) `prlctl` are macOS-native. VM uses tooling Stage 1 itself installs.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `gh auth login` device-flow UX (one-time, interactive) | SEC-08/SEC-10 prerequisite | Device-flow code entry is interactive by design; automating it defeats the security model | Operator runs `setup-credentials.sh` on VM, enters device code at https://github.com/login/device when prompted, observes script proceeds past `gh auth status` check |
| Stale GitHub-side key cleanup after rotation | SEC-12 | Out of script scope per CONTEXT (rotation logs old fingerprint; user manually deletes via `gh ssh-key delete` if desired) | After `--rotate-ssh`, operator inspects logged old-fingerprint, runs `gh ssh-key list` + `gh ssh-key delete <id>` if desired |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags (all checks single-shot)
- [ ] Feedback latency < 5s for quick / < 15min for full
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
