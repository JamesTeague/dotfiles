---
phase: 1
plan: 05
status: in-progress
started: 2026-06-28T21:27:03Z
vm_host: jteague@10.211.55.4
snapshot: vanilla-fresh-boot-pre-chezmoi
---

# Plan 1-05: VM Verification Results

## Pre-flight (local source tree)

**Timestamp:** 2026-06-28T21:27:03Z
**Script:** `.planning/phases/01-credential-plane/checks/quick.sh`

### quick.sh Summary

```
== SEC-05 (a) generate-gpg-key.sh deleted ==
  ✓ absent: home/scripts/generate-gpg-key.sh

== SEC-05 (b) modify_dot_gitconfig.local rewritten ==
  ✓ grep '.signingkey' present
  ✓ grep 'output.*generate-gpg-key' NOT present

== SEC-07 SSH config template ==
  ✓ home/private_dot_ssh/config.tmpl exists
  ✓ 'Host github-personal' present
  ✓ 'IdentitiesOnly yes' present

== SEC-02 bw formula pin ==
  ✓ 'bitwarden-cli' in packages.yaml
  ✓ 'PIN' in packages.yaml
  ✓ docs/credential-plane.md exists

== SEC-08 setup-credentials.sh rewrites chezmoi remote ==
  ✓ 'chezmoi git -- remote set-url origin' in setup-credentials.sh

== SEC-11 setup-credentials.sh distribution shape ==
  ✓ file exists
  ✓ executable
  ✓ NOT in .chezmoiscripts/

== SEC-13 (presence) personal_ed25519 referenced in setup-credentials.sh ==
  ✓ 'personal_ed25519' referenced

== SEC-15 Structural VaultWarden-independence ==
  ✓ 22 *.tmpl files scanned — ZERO matches for three-clause regex

== Summary ==
  PASS    : 36
  PENDING : 0
  FAIL    : 0
```

**Result: ALL SEC GATES GREEN**

### SEC-15 Explicit Phase Exit Gate

```
grep -rEn '\bbw \b|bitwardenAttachment|\{\{ *bitwarden' home/ --include='*.tmpl'
```
Result: **0 matches** (exit code 1 = no match found) — PASS

```
grep -rEn '\bbw \b|bitwarden' home/.chezmoiscripts/
```
Result: **0 matches** (exit code 1 = no match found) — PASS

**Pre-flight status: PASS — proceeding to VM scenarios.**

---

## Scenario 1: Fresh Stage 1 + Stage 2

> To be filled in by operator after VM execution.

**Snapshot UUID:** _(pending operator capture)_

### Stage 1 (chezmoi init --apply)

_(pending operator capture of stdout + duration)_

### Stage 2 (setup-credentials.sh — interactive)

_(pending operator capture of stdout + duration)_

### Post-Stage-2 Verifications

| Check | Command | Expected | Result |
|-------|---------|----------|--------|
| SEC-08 | `chezmoi git -- remote get-url origin` | `git@github-personal:JamesTeague/dotfiles.git` | _(pending)_ |
| SEC-09 | `git commit -S --allow-empty -m phase1 && git log --show-signature -1` | "Good signature" | _(pending)_ |
| SEC-10 | `ssh -T git@github-personal` | "Hi ...! You've successfully authenticated..." | _(pending)_ |
| SEC-13 | `ssh-keygen -lf ~/.ssh/personal_ed25519.pub` | ED25519 | _(pending)_ |
| SEC-14 | `chezmoi data | jq -r .signingkey` matches GPG keyring | MATCH | _(pending)_ |
| gitconfig | `grep -E "signingkey|gpgsign" ~/.gitconfig.local` | both present | _(pending)_ |

---

## Scenario 2: Idempotency re-run

> To be filled in by operator after VM execution (do NOT restore snapshot before this).

### Re-run output

_(pending operator capture)_

### Key count before/after

| Metric | Value |
|--------|-------|
| SSH key count before | _(pending)_ |
| SSH key count after | _(pending)_ |
| GPG key count before | _(pending)_ |
| GPG key count after | _(pending)_ |

**Result:** _(pending)_

---

## Scenario 3: Rotation

> To be filled in by operator after restoring snapshot, running Stage 1 + Stage 2 again, then running --rotate-all.

### Fresh Stage 1 + Stage 2 (post-restore)

_(pending operator capture)_

### --rotate-all run

_(pending operator capture of stdout — old fingerprint/key-ID log)_

### Rotation verification

| Check | Before rotation | After rotation | Match? |
|-------|-----------------|----------------|--------|
| SSH fingerprint | _(pending)_ | _(pending)_ | _(pending)_ |
| GPG key ID | _(pending)_ | _(pending)_ | _(pending)_ |

---

## Manual Verifications

> To be filled in by operator.

### Device-flow UX (Scenario 1)

| Question | Operator notes |
|----------|---------------|
| Did script display clear device-flow URL + code? | _(pending)_ |
| Did device-flow code entry succeed on first try? | _(pending)_ |
| Any UX friction observed? | _(pending)_ |

### Stale-key cleanup decision (Scenario 3)

| Question | Operator notes |
|----------|---------------|
| Old SSH fingerprint clearly logged? | _(pending)_ |
| Old GPG key ID clearly logged? | _(pending)_ |
| Cleanup procedure (`gh ssh-key delete`) straightforward? | _(pending)_ |
| Did operator delete stale keys from GitHub? | _(pending)_ |

---

## Requirement ID -> Result Map

| Req ID | Description | Scenario | Result |
|--------|-------------|----------|--------|
| SEC-08 | chezmoi remote = git@github-personal | 1 | _(pending)_ |
| SEC-09 | `git commit -S` verified signature | 1 | _(pending)_ |
| SEC-10 | `ssh -T git@github-personal` welcome | 1 | _(pending)_ |
| SEC-15 | Structural VW-independence | pre-flight | **PASS** |
| SEC-16 | End-to-end VM + idempotency no-op | 1+2 | _(pending)_ |

---

## Operator Notes

_(pending — add any friction, surprises, or follow-up items here)_
