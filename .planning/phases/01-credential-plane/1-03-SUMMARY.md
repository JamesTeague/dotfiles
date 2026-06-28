---
phase: 01-credential-plane
plan: 03
subsystem: credential-plane
tags: [ssh, bitwarden-cli, vaultwarden, documentation, SEC-02, SEC-07, SEC-15]
dependency_graph:
  requires:
    - 1-01 (quick.sh harness)
  provides:
    - home/private_dot_ssh/config.tmpl (SSH config template — SEC-07)
    - home/.chezmoidata/packages.yaml bitwarden-cli pin entry (SEC-02)
    - docs/credential-plane.md (operator reference)
  affects:
    - Plans 1-04a, 1-04b (setup-credentials.sh consumers — SSH config is the destination for keys those plans generate)
tech_stack:
  added: []
  patterns:
    - chezmoi-stat-file-presence-gate (stat helper for conditional template blocks — fallback when no data field exists)
    - hand-edit-over-yaml-roundtrip (packages.yaml single-quoted-string style preserved)
key_files:
  created:
    - home/private_dot_ssh/config.tmpl
    - docs/credential-plane.md
  modified:
    - home/.chezmoidata/packages.yaml (bitwarden-cli line added)
decisions:
  - "File-presence gating on ~/.ssh/work_ed25519 (not .employer data field): Phase 0 did not introduce an employer field — [data] in chezmoi.toml.tmpl contains only personal/name/email/role/wsl. Per 1-RESEARCH Open Question 8, chezmoi stat template helper on ~/.ssh/work_ed25519 is the fallback gate. If employer field is preferred, Phase 0 amendment required before switching."
  - "bitwarden-cli formula pin uses unversioned name + PIN comment: bitwarden-cli@<ver> does not exist as an upstream Homebrew formula. brew-extract to a local tap is the pinning ritual; it is documented in docs/credential-plane.md and executed manually per machine, not scripted."
  - "docs/credential-plane.md is the single authoritative ops reference: any change to the bw pin ceiling or rotation flag behavior must update this doc in the same commit."
metrics:
  duration_minutes: 22
  tasks_completed: 2
  files_created: 3
  files_modified: 1
  completed_date: "2026-06-28"
---

# Phase 1 Plan 03: SSH Config Template + bw Pin Summary

**One-liner:** SSH config template with file-presence-gated work-alias and bitwarden-cli VaultWarden-1.36.0 pin comment, plus 194-line operator docs covering two-stage bootstrap, rotation playbook, and stale-key cleanup.

## What Was Done

### Task 1: SSH Config Template (home/private_dot_ssh/config.tmpl)

Created `home/private_dot_ssh/config.tmpl` via the chezmoi naming convention `private_dot_ssh/` (sets 0700 directory mode on apply via the `private_` prefix; `dot_ssh` maps to `.ssh`).

**Rendered SSH config shape:**

Always-present block (every dev-role machine):

```
Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/personal_ed25519
  IdentitiesOnly yes
```

File-presence-gated block (emitted only when `~/.ssh/work_ed25519` exists on the target machine):

```
Host gitlab-bluebeam
  HostName gitlab.bluebeam.com
  User git
  IdentityFile ~/.ssh/work_ed25519
  IdentitiesOnly yes
```

The template gate uses `{{- if stat (joinPath .chezmoi.homeDir ".ssh" "work_ed25519") }}`. On this machine (Mac personal, no `~/.ssh/work_ed25519`), the rendered output contains only the `github-personal` block — verified via `chezmoi execute-template --init`.

**Divergence from CONTEXT (operator review):** CONTEXT.md sketched `gitlab-bluebeam` gated on `.employer == "bluebeam"` chezmoi data field. Phase 0 did NOT introduce an employer field — the `[data]` section in `chezmoi.toml.tmpl` contains only: `personal`, `name`, `email`, `role`, `wsl`. Per 1-RESEARCH Open Question 8 resolution, file-presence gating on `~/.ssh/work_ed25519` is the fallback mechanism. If an employer data field is preferred, Phase 0 amendment is required first. Operator-review outcome: plan proceeded with file-presence gating per plan spec; no escalation triggered.

**SEC-15 three-clause regex:** `grep -E '\bbw \b|bitwardenAttachment|\{\{ *bitwarden' home/private_dot_ssh/config.tmpl` — zero matches. No apply-time VW calls in this template.

**SEC-07 gate:** PENDING → PASS.

### Task 2: packages.yaml Amendment + docs/credential-plane.md

**Part A — packages.yaml:**

Added to `roles.dev.core.brews` list (single-quoted style preserved):

```yaml
- 'bitwarden-cli' # PIN: pair with VaultWarden 1.36.0 — see docs/credential-plane.md (SEC-02 / Pitfall 3)
```

Inserted after `bash-completion@2`, before `wget` (closest alphabetical position in the existing ordering). Formula name is unversioned — `bitwarden-cli@<ver>` does not exist as an upstream Homebrew formula. The PIN comment is the authoritative marker; the brew-extract ritual is the actual pinning mechanism (documented in Part B).

**Part B — docs/credential-plane.md (194 lines):**

Seven sections covering:

1. **Two-stage bootstrap** — Stage 1 (`chezmoi init --apply`, offline-safe, public repo) vs Stage 2 (`setup-credentials.sh`, interactive, one-time per machine). References CONTEXT.md locked decisions.
2. **Per-machine key model** — table of credential types (personal SSH, personal GPG, Bluebeam work SSH, application passwords) with generation method, registration target, and scope. Per-machine rationale: bounded blast radius, no rotation fanout, multiple verified keys per GitHub account supported.
3. **bw/VaultWarden compat pair** — live VW server 1.36.0; bw ceiling 2025.11.0 per vaultwarden#6729 (2025.12.0 confirmed broken against VW 1.35.2; 1.36.0 needs empirical re-verification). brew-extract procedure verbatim. When-to-bump-pin guidance.
4. **Rotation playbook** — `--rotate-ssh`, `--rotate-gpg`, `--rotate-all` flags. What each does (regenerate + register + log prior key). What rotation does NOT do (delete prior GitHub-side key — manual cleanup, see Section 5).
5. **Stale GitHub-side key cleanup** — quarterly procedure. `gh ssh-key list --json id,title,createdAt` + `gh gpg-key list`. Title convention `<hostname>-personal-<YYYYMMDD>` for identification. `gh ssh-key delete <id>` / `gh gpg-key delete <keyId>`. Explicitly MANUAL.
6. **VM verification target** — Parallels 26.5.1 arm64 at `jteague@10.211.55.4`, snapshot `vanilla-fresh-boot-pre-chezmoi`. Snapshot management rules (restore between scenarios; don't restore between fresh-install and idempotency re-run). Three verification scenarios enumerated.
7. **Pitfall mitigations** — Pitfall 3 (bw/VW drift → pin + this doc), Pitfall 6 (IdentitiesOnly missing → set in every Host block), Pitfall 10 (VW unreachable → structurally eliminated). SEC-15 gate description.

**SEC-15 three-clause structural grep:** `grep -rEn '\bbw \b|bitwardenAttachment|\{\{ *bitwarden' home/ --include='*.tmpl'` — zero matches after both tasks. No new apply-time VW calls introduced.

**SEC-02 gate:** PENDING → PASS.

## quick.sh Gate Summary

| Gate | Before | After |
|------|--------|-------|
| SEC-07 SSH config template | PENDING | PASS |
| SEC-02 bw formula pin | PENDING (2 clauses) | PASS |
| SEC-15 Structural VW-independence | PASS (no tmpl files yet scanned) | PASS (config.tmpl scanned, clean) |
| SEC-05(a) generate-gpg-key.sh deleted | FAIL (out of scope — Plan 1-02) | FAIL (unchanged — Plan 1-02) |
| SEC-05(b) modify_dot_gitconfig.local | FAIL (out of scope — Plan 1-02) | FAIL (unchanged — Plan 1-02) |

Final quick.sh: 34 PASS, 0 PENDING, 2 FAIL (both pre-existing, both Plan 1-02 scope).

## Deviations from Plan

None — plan executed exactly as written. The employer-data-field vs file-presence divergence was documented in the plan itself and carried into the Task 1 commit body for operator review; no escalation was needed.

## Self-Check

### Files Created

- [x] `home/private_dot_ssh/config.tmpl` — exists, 15 lines
- [x] `docs/credential-plane.md` — exists, 194 lines

### Files Modified

- [x] `home/.chezmoidata/packages.yaml` — bitwarden-cli line added at line 10

### Commits

- [x] `4edad12` — feat(01-03): add SSH config template with purpose-based Host aliases
- [x] `3cbddd3` — feat(01-03): add bitwarden-cli pin entry in packages.yaml + docs/credential-plane.md

## Self-Check: PASSED
