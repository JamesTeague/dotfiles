---
phase: 01-credential-plane
plan: 01
subsystem: planning-harness
tags: [verification, harness, requirements, SEC-15, bash]
dependency_graph:
  requires: []
  provides:
    - .planning/phases/01-credential-plane/checks/lib.sh
    - .planning/phases/01-credential-plane/checks/quick.sh
    - .planning/phases/01-credential-plane/checks/full.sh
    - .planning/phases/01-credential-plane/checks/vm-e2e.sh
    - .planning/phases/01-credential-plane/checks/parallels-helpers.sh
    - REQUIREMENTS.md SEC-11..16 formalized
  affects:
    - Plans 1-02, 1-03, 1-04a, 1-04b, 1-05 (consumers of checks/quick.sh)
tech_stack:
  added: []
  patterns:
    - wave0-harness (lib.sh + quick.sh + full.sh pattern, established Phase 0.5)
    - assert_no_grep (new inverse-grep helper added to lib.sh for SEC-15)
    - prlctl snapshot management wrappers (parallels-helpers.sh)
key_files:
  created:
    - .planning/phases/01-credential-plane/checks/lib.sh
    - .planning/phases/01-credential-plane/checks/quick.sh
    - .planning/phases/01-credential-plane/checks/full.sh
    - .planning/phases/01-credential-plane/checks/vm-e2e.sh
    - .planning/phases/01-credential-plane/checks/parallels-helpers.sh
  modified:
    - .planning/REQUIREMENTS.md (SEC-11..16 added; coverage 69->75)
decisions:
  - "assert_no_grep added to lib.sh (not in Phase 0.5): inverse of assert_grep; pending on missing file, fail on pattern present. Load-bearing for SEC-15 VaultWarden-independence checks."
  - "SEC-15 three-clause regex locked: '\\bbw \\b|bitwardenAttachment|\\{\\{ *bitwarden' — all three clauses required in every assertion. Canonical contract for Plans 1-02..1-05."
  - "STRICT mode contract: STRICT=1 promotes PENDING->FAIL and exits non-zero. Without STRICT=1, PENDING gates do NOT produce non-zero exit (only FAIL gates do). This is the mechanism Plans 1-02..1-05 use to assert expected-RED before implementation."
  - "quick.sh SEC-05(a) uses assert_dir_missing_strict (hard FAIL, not PENDING) for generate-gpg-key.sh. That deletion is a hard invariant per Phase 1 scope, not a wave-staged removal."
  - "vm-e2e.sh graceful pend: if prlctl absent, vm-e2e.sh prints pending + exits 0. Enables structural-only flow on planner machines without Parallels."
  - "full.sh aggregates without short-circuit: quick.sh failure does NOT skip vm-e2e.sh. Both suites run; aggregate exit is non-zero if either fails."
  - "SEC-15 scan exclusions: packages.yaml (bitwarden cask + bitwarden-cli formula are install names, not template calls) and setup-credentials.sh (design comments permitted). Both excluded from the find-based tmpl scan."
metrics:
  duration_minutes: 23
  tasks_completed: 3
  files_created: 5
  files_modified: 1
  completed_date: "2026-06-28"
---

# Phase 1 Plan 01: Wave 0 Harness Summary

**One-liner:** Five-script bash harness (lib.sh + quick.sh + full.sh + vm-e2e.sh + parallels-helpers.sh) establishing Phase 1 structural gates and VM orchestration, with SEC-11..16 formalized in REQUIREMENTS.md (coverage 69 -> 75).

## What Was Done

### Task 1: Formalize SEC-11..16 in REQUIREMENTS.md

Added six new requirement rows to the "Secrets & Identity" section of REQUIREMENTS.md, placed after SEC-10 in numerical order. These requirements formalize the per-machine keygen architecture introduced by the 2026-06-04 Phase 1 pivot:

- **SEC-11**: `setup-credentials.sh` exists, executable, operator-invoked (not a chezmoi script)
- **SEC-12**: `--rotate-ssh`, `--rotate-gpg`, `--rotate-all` flags for key rotation
- **SEC-13**: Per-machine ed25519 SSH key at `~/.ssh/personal_ed25519` via `gh ssh-key add` with idempotency
- **SEC-14**: Per-machine ed25519 GPG key via `gpg --batch --gen-key` parameter file; `signingkey` written to chezmoi.toml `[data]`
- **SEC-15**: Structural VaultWarden-independence: zero matches of canonical three-clause regex in apply-time paths
- **SEC-16**: End-to-end VM verification (signed commit + SSH auth + remote-rewrite + idempotency)

Six Phase 1 / Pending rows added to the Traceability table. Coverage count updated from 69 to 75.

### Task 2: checks/lib.sh + checks/quick.sh

**lib.sh** is adapted from Phase 0.5 `checks/lib.sh` with one new helper:

- `assert_no_grep PATTERN PATH`: inverse of `assert_grep`. Pass when grep finds no match (pattern absent = correct state). Fail when pattern present (invariant violated). Pending when file missing (separate upstream check governs). This is the mechanism for all SEC-15 VaultWarden-independence assertions.

All existing helpers preserved: `header`, `pass`, `fail`, `pending`, `assert_file`, `assert_dir_missing`, `assert_dir_missing_strict`, `assert_grep`, `assert_cmd_zero_output`, `summary`. `LIB_SH_LOADED` sentinel guard intact.

**quick.sh** implements structural gates for SEC-02/05/07/08/11/13(presence)/15:

| Section | Gate | Requirement |
|---------|------|-------------|
| 1 | `generate-gpg-key.sh` absent (hard FAIL, not PENDING) | SEC-05 (a) |
| 2 | `modify_dot_gitconfig.local` has `.signingkey`, NOT `output.*generate-gpg-key` | SEC-05 (b) |
| 3 | `private_dot_ssh/config.tmpl` exists with `Host github-personal` + `IdentitiesOnly yes` | SEC-07 |
| 4 | `packages.yaml` has `bitwarden-cli` + `PIN`; `docs/credential-plane.md` exists | SEC-02 |
| 5 | `setup-credentials.sh` contains `chezmoi git -- remote set-url origin` | SEC-08 |
| 6 | `setup-credentials.sh` exists, executable, NOT in `.chezmoiscripts/` | SEC-11 |
| 7 | `setup-credentials.sh` references `personal_ed25519` | SEC-13 (presence) |
| 8 | `find home -name '*.tmpl'` + `find home/.chezmoiscripts -name '*.sh.tmpl'`: no VW references | SEC-15 |

**STRICT mode contract:** `STRICT=1 bash quick.sh` promotes all PENDING gates to FAIL and exits non-zero. Pre-Wave-1, `generate-gpg-key.sh` triggers immediate FAIL (hard invariant via `assert_dir_missing_strict`). All other SEC-* gates produce PENDING (artifacts not yet created). Under STRICT=1 those PENDINGs become FAILs too. This is the mechanism Wave 1 implementers use: after each task commit, they run `STRICT=1 bash quick.sh` and watch gates turn from FAIL to PASS.

### Task 3: checks/full.sh + checks/vm-e2e.sh + checks/parallels-helpers.sh

**parallels-helpers.sh** — sourceable, pure function definitions, no execution at source time:

- `prl_available()` — `command -v prlctl`
- `prl_vm_name` / `prl_snapshot_name` / `vm_ssh_host` — env-overridable configuration vars
- `prl_resolve_snapshot_uuid()` — `prlctl snapshot-list --json | jq -r .[] | select(.name) | .id`; grep fallback if jq absent
- `prl_restore_snapshot()` — `snapshot-switch` then `start` (idempotent, start error ignored)
- `prl_wait_for_boot()` — SSH echo-ok probe, 60 attempts at 5s intervals (5-minute ceiling)

**vm-e2e.sh** — six-step composite orchestration:

1. **Preflight**: `prl_available()` check — if absent, `pending` + exit 0 (graceful on planner machines)
2. **Snapshot restore**: `prl_restore_snapshot` + `prl_wait_for_boot`; fail-loud if either errors
3. **Stage 1**: `ssh "${vm_ssh_host}" 'sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply JamesTeague/dotfiles'`
4. **Stage 2**: `ssh -t "${vm_ssh_host}" 'bash ~/scripts/setup-credentials.sh'` with operator notice before step
5. **Verifications**: SEC-08 (remote URL), SEC-09 (signed commit), SEC-10 (ssh -T github-personal), SEC-12 (--help flags), SEC-13 (ed25519 keypair), SEC-14 (GPG key + chezmoi data match)
6. **SEC-16 idempotency**: SSH key count before re-run captured, Stage 2 re-run, count compared after

**full.sh** — aggregator:

- Parses `--no-vm` (skip VM smokes) and `--strict` (forward to quick.sh)
- Runs `quick.sh`; captures exit code but continues regardless (no short-circuit)
- Runs `vm-e2e.sh` unless `--no-vm`; captures exit code
- Prints aggregate PASS/FAIL for both suites
- Exits non-zero if either suite failed

## Canonical Contracts (Load-Bearing for Plans 1-02..1-05)

### SEC-15 Three-Clause Regex

```
\bbw \b|bitwardenAttachment|\{\{ *bitwarden
```

- Clause 1 (`\bbw \b`): catches `bw` CLI invocations (word-boundary + trailing space disambiguates from `bwrap` etc.)
- Clause 2 (`bitwardenAttachment`): catches chezmoi `bitwardenAttachment` template function
- Clause 3 (`\{\{ *bitwarden`): catches chezmoi `{{ bitwarden ... }}` template-function family

**All three clauses MUST appear in every SEC-15 grep assertion.** Dropping any clause violates the SEC-15 contract. In bash single-quoted strings: `'\bbw \b|bitwardenAttachment|\{\{ *bitwarden'`.

Excluded from scan: `packages.yaml` (install names) and `home/scripts/setup-credentials.sh` (design comments permitted).

### STRICT Mode

`STRICT=1` (env var) or `--strict` (flag) promotes PENDING rows to FAIL. Without STRICT, only hard FAIL gates produce non-zero exit. Plans 1-02..1-05 run `STRICT=1 bash quick.sh` as their "expected RED before implementation" assertion.

## Handoff to Wave 1 Plans

| Plan | What it implements | quick.sh gates it turns GREEN |
|------|--------------------|-------------------------------|
| 1-02 | `modify_dot_gitconfig.local` rewrite + `generate-gpg-key.sh` deletion | SEC-05(a) FAIL → PASS; SEC-05(b) PENDING → PASS |
| 1-03 | SSH config template (`private_dot_ssh/config.tmpl`) + `bw` pin + `docs/credential-plane.md` | SEC-07 PENDING → PASS; SEC-02 PENDING → PASS |
| 1-04a | `setup-credentials.sh` (auth + SSH sections) | SEC-08 PENDING → PASS; SEC-11 PENDING → PASS; SEC-13 PENDING → PASS |
| 1-04b | `setup-credentials.sh` (GPG + signingkey sections + rotation flags) | SEC-12 (help text) → covered by vm-e2e.sh |
| 1-05 | VM verification (executes vm-e2e.sh against fresh snapshot) | SEC-16 (vm-e2e.sh full suite) |

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check

### Files Created

- [x] `.planning/phases/01-credential-plane/checks/lib.sh` — exists
- [x] `.planning/phases/01-credential-plane/checks/quick.sh` — exists
- [x] `.planning/phases/01-credential-plane/checks/full.sh` — exists
- [x] `.planning/phases/01-credential-plane/checks/vm-e2e.sh` — exists
- [x] `.planning/phases/01-credential-plane/checks/parallels-helpers.sh` — exists

### Files Modified

- [x] `.planning/REQUIREMENTS.md` — SEC-11..16 added; traceability rows added; coverage 75

### Commits

- [x] `04ce1b8` — feat(01-01): formalize SEC-11..16 in REQUIREMENTS.md
- [x] `b4b5d2c` — feat(01-01): add checks/lib.sh and checks/quick.sh structural gates
- [x] `aa601e4` — feat(01-01): add checks/full.sh, vm-e2e.sh, parallels-helpers.sh

## Self-Check: PASSED
