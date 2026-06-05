---
phase: 1-credential-plane
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/phases/1-credential-plane/checks/lib.sh
  - .planning/phases/1-credential-plane/checks/quick.sh
  - .planning/phases/1-credential-plane/checks/full.sh
  - .planning/phases/1-credential-plane/checks/vm-e2e.sh
  - .planning/phases/1-credential-plane/checks/parallels-helpers.sh
  - .planning/REQUIREMENTS.md
autonomous: true
requirements:
  - SEC-11
  - SEC-12
  - SEC-13
  - SEC-14
  - SEC-15
  - SEC-16
must_haves:
  truths:
    - "SEC-11..16 are formalized in REQUIREMENTS.md with status: Pending and Phase 1 traceability"
    - "Running checks/quick.sh on the current source tree exits non-zero (structural gates not yet met — wave 1 implements)"
    - "checks/quick.sh runs in under 5 seconds"
    - "checks/full.sh is callable but degrades to quick-only when --no-vm flag passed"
    - "checks/vm-e2e.sh and checks/parallels-helpers.sh exist and lint clean with shellcheck"
  artifacts:
    - path: ".planning/phases/1-credential-plane/checks/lib.sh"
      provides: "Shared assertion helpers (pass/fail/pending/assert_file/assert_grep/summary)"
      contains: "LIB_SH_LOADED"
    - path: ".planning/phases/1-credential-plane/checks/quick.sh"
      provides: "Fast structural gates for SEC-02/05/07/11/13(presence)/15"
      min_lines: 60
    - path: ".planning/phases/1-credential-plane/checks/full.sh"
      provides: "Quick + VM-driven smokes (SEC-08/09/10/12/13/14/16) with --no-vm fallback"
      min_lines: 40
    - path: ".planning/phases/1-credential-plane/checks/vm-e2e.sh"
      provides: "Composite VM orchestration: snapshot restore + Stage 1 + Stage 2 + verify + idempotency"
      min_lines: 40
    - path: ".planning/phases/1-credential-plane/checks/parallels-helpers.sh"
      provides: "prlctl wrappers: availability check, snapshot UUID resolution, restore + wait-for-boot"
    - path: ".planning/REQUIREMENTS.md"
      provides: "SEC-11..16 enumerated with descriptions and traceability rows"
      contains: "SEC-16"
  key_links:
    - from: ".planning/phases/1-credential-plane/checks/quick.sh"
      to: ".planning/phases/1-credential-plane/checks/lib.sh"
      via: "source lib.sh"
      pattern: "source.*lib\\.sh"
    - from: ".planning/phases/1-credential-plane/checks/full.sh"
      to: ".planning/phases/1-credential-plane/checks/quick.sh"
      via: "invokes quick.sh first then conditional VM tests"
      pattern: "quick\\.sh"
    - from: ".planning/phases/1-credential-plane/checks/vm-e2e.sh"
      to: ".planning/phases/1-credential-plane/checks/parallels-helpers.sh"
      via: "source parallels-helpers.sh for snapshot management"
      pattern: "parallels-helpers"
---

<objective>
Establish the Phase 1 verification harness AND formalize the six new requirement IDs (SEC-11..16) the 2026-06-04 architecture pivot introduced.

Purpose: Wave 1 implementers need (a) a fast structural gate they can run after every commit to confirm their work moves SEC-* requirements from RED to GREEN, and (b) authoritative requirement rows in REQUIREMENTS.md to cite in their commit messages and SUMMARY artifacts. Without this Wave 0, Wave 1 tasks have no automated verification surface and Wave 2 has no composite VM orchestration to drive.

Output: Five harness scripts under `.planning/phases/1-credential-plane/checks/` (pattern adapted from Phase 0.5 Plan 01) plus an amendment to REQUIREMENTS.md adding SEC-11 through SEC-16 with full descriptions, research-support pointers, and Phase 1 traceability table rows.
</objective>

<execution_context>
@/Users/jteague/.claude/get-shit-done/workflows/execute-plan.md
@/Users/jteague/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/phases/1-credential-plane/1-CONTEXT.md
@.planning/phases/1-credential-plane/1-RESEARCH.md
@.planning/phases/1-credential-plane/1-VALIDATION.md
@.planning/phases/00.5-audit-documentation/checks/lib.sh
@.planning/phases/00.5-audit-documentation/checks/quick.sh

<interfaces>
<!-- Adapt from Phase 0.5 Plan 01 lib.sh — same public API. Phase 1 lib.sh exposes: -->

```bash
# Public functions (caller-facing):
header MSG                 # colored section banner
pass MSG                   # green check + PASS_COUNT++
fail MSG                   # red X + FAIL_COUNT++ (strict mode: exit 1)
pending MSG                # yellow dot + PENDING_COUNT++ (strict mode: fail)
assert_file PATH           # pass if exists; pending otherwise
assert_dir_missing PATH    # pass if absent; pending if present (wave-staged)
assert_dir_missing_strict PATH  # pass if absent; FAIL if present (hard invariant)
assert_grep PATTERN PATH   # pass on grep -q match; fail if file exists but pattern absent
assert_no_grep PATTERN PATH  # NEW for Phase 1 — pass on grep -q NOT match; used for SEC-15
assert_cmd_zero_output CMD # pass iff stdout empty
summary                    # final counts; return 1 if FAIL_COUNT > 0

# Env (derived at source time):
REPO_ROOT          # git toplevel
CHEZMOI_SOURCE_ROOT  # chezmoi source-path
STRICT_MODE        # 1 if STRICT=1 in env

# Counters: PASS_COUNT FAIL_COUNT PENDING_COUNT
```

REQUIREMENTS.md row shape (existing pattern from Phase 0.5 entries):
```markdown
- [ ] **SEC-NN**: <description>
```
And in Traceability table:
```markdown
| SEC-NN | Phase 1 | Pending |
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Formalize SEC-11..16 in REQUIREMENTS.md</name>
  <files>.planning/REQUIREMENTS.md</files>
  <action>
Amend REQUIREMENTS.md to add six new requirement IDs introduced by the 2026-06-04 Phase 1 architecture pivot. Place them in the `### Secrets & Identity` section after the existing SEC-10 entry, preserving the SUPERSEDED annotations on SEC-01/03/04/06 and BOOT-01..05.

Add these six rows verbatim (using the standard `- [ ] **ID**: <description>` format):

- [ ] **SEC-11**: `home/scripts/setup-credentials.sh` exists, is executable, and is operator-invoked (NOT a `run_once_` chezmoi script). Distributes via `chezmoi apply` to `~/scripts/setup-credentials.sh`.
- [ ] **SEC-12**: `setup-credentials.sh` exposes `--rotate-ssh`, `--rotate-gpg`, and `--rotate-all` flags that regenerate the targeted local keypair, re-register it with GitHub, and log the prior fingerprint/key-ID for manual stale-cleanup. Default invocation does NOT rotate.
- [ ] **SEC-13**: Per-machine SSH key generated with `ssh-keygen -t ed25519 -N "" -C "<hostname>-personal-<YYYYMMDD>"` at `~/.ssh/personal_ed25519`, registered via `gh ssh-key add` with idempotent fingerprint-compare-before-add (cli/cli#5085 mitigation).
- [ ] **SEC-14**: Per-machine GPG key generated via `gpg --batch --gen-key` with parameter file using `Key-Type: EDDSA` + `Key-Curve: Ed25519` + `%no-protection`; registered via `gh gpg-key add` with idempotent key-ID-compare-before-add. Long key ID written to `~/.config/chezmoi/chezmoi.toml` `[data]` section as `signingkey`.
- [ ] **SEC-15**: Structural VaultWarden-independence verified: `grep -rEn '\bbw \b|bitwardenAttachment|\{\{ *bitwarden' home/ --include='*.tmpl'` returns zero matches; `grep -rEn '\bbw \b|bitwarden' home/.chezmoiscripts/` returns zero matches. Permitted exceptions: `packages.yaml` install names (`bitwarden` cask, `bitwarden-cli` formula) and design-comment lines in `setup-credentials.sh`.
- [ ] **SEC-16**: End-to-end verification on Parallels VM (snapshot `vanilla-fresh-boot-pre-chezmoi` at jteague@10.211.55.4): Stage 1 (`chezmoi init --apply`) + Stage 2 (`setup-credentials.sh`) produces a verified-signed commit (`git log --show-signature` shows "Good signature") AND `ssh -T git@github-personal` returns the GitHub welcome message AND `chezmoi git -- remote get-url origin` reports `git@github-personal:...` AND re-running `setup-credentials.sh` is a no-op.

Then append six rows to the `## Traceability` table, in numerical order with status `Pending`:

```
| SEC-11 | Phase 1 | Pending |
| SEC-12 | Phase 1 | Pending |
| SEC-13 | Phase 1 | Pending |
| SEC-14 | Phase 1 | Pending |
| SEC-15 | Phase 1 | Pending |
| SEC-16 | Phase 1 | Pending |
```

Update the **Last amended** date in the file header to `2026-06-04 (Phase 1 architecture pivot — see SUPERSEDED annotations in Secrets & Identity and Bootstrap Kit sections; SEC-11..16 added for per-machine keygen architecture)`.

Update the `**Coverage:**` line at file bottom: `v1 requirements: 75 total` (69 + 6), `Mapped to phases: 75`, `Unmapped: 0`.

Do NOT touch the SUPERSEDED rows or any other section.
  </action>
  <verify>
    <automated>grep -c "^- \[ \] \*\*SEC-1[1-6]\*\*:" /Users/jteague/.local/share/chezmoi/.planning/REQUIREMENTS.md | grep -q "^6$" && grep -E "^\| SEC-1[1-6] \| Phase 1 \| Pending \|" /Users/jteague/.local/share/chezmoi/.planning/REQUIREMENTS.md | wc -l | tr -d ' ' | grep -q "^6$"</automated>
  </verify>
  <done>All six SEC-11..16 rows present in Secrets & Identity section with Phase-1 pivot context; six matching rows in Traceability table; coverage counts updated; SUPERSEDED rows untouched.</done>
</task>

<task type="auto">
  <name>Task 2: Author checks/lib.sh + checks/quick.sh (structural gates)</name>
  <files>.planning/phases/1-credential-plane/checks/lib.sh, .planning/phases/1-credential-plane/checks/quick.sh</files>
  <action>
Copy `.planning/phases/00.5-audit-documentation/checks/lib.sh` as the starting point for Phase 1's `lib.sh`, then ADD one new helper `assert_no_grep PATTERN PATH` (pass when `grep -q PATTERN PATH` finds NOTHING; fail if pattern present; pending if file missing — used by SEC-15 to assert VW-free templates). Keep the LIB_SH_LOADED sentinel guard intact.

Write `checks/quick.sh` as an executable bash script with `#!/usr/bin/env bash`, `set -uo pipefail`, sourcing `lib.sh` from the same dir via `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` + `source "${SCRIPT_DIR}/lib.sh"`. STRICT_MODE flag parsing (`--strict` → `export STRICT=1` before source).

Implement these structural gates (each in a header-banner section). All paths are relative to `${REPO_ROOT}`:

1. **SEC-05 (a) — generate-gpg-key.sh DELETED**:
   `assert_dir_missing_strict "${REPO_ROOT}/home/scripts/generate-gpg-key.sh"` (hard invariant once Plan 1-02 lands)

2. **SEC-05 (b) — modify_dot_gitconfig.local rewritten**:
   `assert_grep "\.signingkey" "${REPO_ROOT}/home/modify_dot_gitconfig.local"`
   `assert_no_grep "output.*generate-gpg-key" "${REPO_ROOT}/home/modify_dot_gitconfig.local"`

3. **SEC-07 — SSH config template with purpose aliases**:
   `assert_file "${REPO_ROOT}/home/private_dot_ssh/config.tmpl"`
   `assert_grep "Host github-personal" "${REPO_ROOT}/home/private_dot_ssh/config.tmpl"`
   `assert_grep "IdentitiesOnly yes" "${REPO_ROOT}/home/private_dot_ssh/config.tmpl"`

4. **SEC-02 — bw formula pin documented**:
   `assert_grep "bitwarden-cli" "${REPO_ROOT}/home/.chezmoidata/packages.yaml"`
   `assert_grep "PIN" "${REPO_ROOT}/home/.chezmoidata/packages.yaml"` (the comment marker)
   `assert_file "${REPO_ROOT}/docs/credential-plane.md"`

5. **SEC-11 — setup-credentials.sh exists, executable, NOT a chezmoi script**:
   `assert_file "${REPO_ROOT}/home/scripts/setup-credentials.sh"`
   Then a custom check: `if [[ -x "${REPO_ROOT}/home/scripts/setup-credentials.sh" ]]; then pass "executable: setup-credentials.sh"; else fail "not executable: setup-credentials.sh"; fi`
   And: `assert_cmd_zero_output bash -c "ls ${REPO_ROOT}/home/.chezmoiscripts/*setup-credentials* 2>/dev/null || true"` (must produce zero output — script is NOT in .chezmoiscripts/)

6. **SEC-13 (presence only) — ed25519 key path referenced**:
   `assert_grep "personal_ed25519" "${REPO_ROOT}/home/scripts/setup-credentials.sh"`

7. **SEC-15 — Structural VW-independence**:
   For each `.tmpl` file under `${REPO_ROOT}/home/` (use `find ... -name '*.tmpl'`), run `assert_no_grep '\bbw \b|bitwardenAttachment|\{\{ *bitwarden' "$f"`. For each script under `${REPO_ROOT}/home/.chezmoiscripts/` (find -name '*.sh.tmpl'), same. Permitted exceptions: this check explicitly does NOT scan `packages.yaml` (install names) or `home/scripts/setup-credentials.sh` (design comments).

End with `summary; exit $?`.

`chmod +x checks/lib.sh checks/quick.sh`.

The expected runtime on the current source tree (before Wave 1 lands): mostly PENDING / FAIL rows because none of the artifacts exist yet. That's correct — quick.sh is the gate that turns GREEN as Wave 1 implementers land their work.
  </action>
  <verify>
    <automated>cd /Users/jteague/.local/share/chezmoi && bash -n .planning/phases/1-credential-plane/checks/lib.sh && bash -n .planning/phases/1-credential-plane/checks/quick.sh && test -x .planning/phases/1-credential-plane/checks/quick.sh && bash .planning/phases/1-credential-plane/checks/quick.sh; rc=$?; test "$rc" -ne 0 || (echo "quick.sh unexpectedly GREEN before wave 1" && exit 1)</automated>
  </verify>
  <done>lib.sh and quick.sh syntactically valid bash; quick.sh executable; runs against current tree and exits non-zero (Wave 1 has not yet landed); all SEC-02/05/07/11/13(presence)/15 gates present with header banners.</done>
</task>

<task type="auto">
  <name>Task 3: Author checks/full.sh + checks/vm-e2e.sh + checks/parallels-helpers.sh</name>
  <files>.planning/phases/1-credential-plane/checks/full.sh, .planning/phases/1-credential-plane/checks/vm-e2e.sh, .planning/phases/1-credential-plane/checks/parallels-helpers.sh</files>
  <action>
Write three bash scripts. All `#!/usr/bin/env bash` + `set -uo pipefail`. All executable.

**`checks/full.sh`** — orchestrator. Parses flags `--no-vm` (skip VM smokes) and `--strict` (forward to quick.sh). Sources `lib.sh`. Steps:

1. Run `bash "${SCRIPT_DIR}/quick.sh" ${STRICT_FLAG:-}`. Capture exit code. If non-zero AND `--no-vm` not passed, still continue to VM smokes (full.sh aggregates; don't short-circuit). Track quick failure for final summary.
2. If `--no-vm` was passed: print "VM smokes skipped (--no-vm)" and exit with quick.sh's exit code.
3. Otherwise invoke `bash "${SCRIPT_DIR}/vm-e2e.sh"`. Capture exit code.
4. Final summary: print PASS/FAIL aggregate and exit non-zero if either quick OR vm-e2e failed.

**`checks/parallels-helpers.sh`** — sourceable. Public functions:

- `prl_available()` — `command -v prlctl >/dev/null 2>&1`
- `prl_vm_name="${PRL_VM_NAME:-macOS-26-vanilla}"` — VM name env-overridable; documented default placeholder (operator MUST set `PRL_VM_NAME` before running vm-e2e.sh)
- `prl_snapshot_name="${PRL_SNAPSHOT:-vanilla-fresh-boot-pre-chezmoi}"`
- `prl_resolve_snapshot_uuid()` — `prlctl snapshot-list "$prl_vm_name" --json | jq -r --arg n "$prl_snapshot_name" '.[] | select(.name==$n) | .id'` (graceful fallback to grep if jq fails)
- `prl_restore_snapshot()` — `prlctl snapshot-switch "$prl_vm_name" --id "$(prl_resolve_snapshot_uuid)"` then `prlctl start "$prl_vm_name" 2>/dev/null || true` (idempotent re-start)
- `prl_wait_for_boot()` — poll `ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no jteague@10.211.55.4 echo ok` up to 60 times with 5s sleep; fail after 5 minutes
- `vm_ssh_host="${VM_SSH_HOST:-jteague@10.211.55.4}"` — SSH target env-overridable

Do NOT execute these at source time; pure function definitions.

**`checks/vm-e2e.sh`** — composite VM orchestration. Sources `lib.sh` AND `parallels-helpers.sh`. Steps with header banners:

1. **Preflight**: `if ! prl_available; then pending "prlctl not available — skipping VM e2e"; summary; exit 0; fi` (so the harness still passes on dev machines without Parallels — VM gates are operator-driven from the host Mac).
2. **Snapshot restore**: `prl_restore_snapshot` then `prl_wait_for_boot`. Fail loud if either step errors.
3. **Stage 1 invocation** (over SSH): `ssh "${vm_ssh_host}" 'sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply JamesTeague/dotfiles'`. Use `pass`/`fail` based on exit code.
4. **Stage 2 invocation**: `ssh "${vm_ssh_host}" 'bash ~/scripts/setup-credentials.sh'`. Operator note printed BEFORE this step: "Interactive — operator must enter device-flow code at https://github.com/login/device when prompted."
5. **Verifications** (each its own `pass`/`fail`):
   - SEC-08: `ssh "${vm_ssh_host}" 'chezmoi git -- remote get-url origin'` matches `^git@github-personal:`
   - SEC-09: `ssh "${vm_ssh_host}" 'git init /tmp/verify-repo 2>/dev/null; cd /tmp/verify-repo && git commit -S --allow-empty -m phase1 && git log --show-signature -1 2>&1 | grep -E "Good signature|gpg: Signature made"'`
   - SEC-10: `ssh "${vm_ssh_host}" 'ssh -T git@github-personal 2>&1 | grep -q "successfully authenticated"'` (note: `ssh -T` exits 1 by design — the grep is the assertion; check `${PIPESTATUS[1]}` not `$?`)
   - SEC-12: `ssh "${vm_ssh_host}" 'bash ~/scripts/setup-credentials.sh --help'` output contains all of `rotate-ssh`, `rotate-gpg`, `rotate-all`
   - SEC-13 (keypair check): `ssh "${vm_ssh_host}" 'test -f ~/.ssh/personal_ed25519 && ssh-keygen -lf ~/.ssh/personal_ed25519.pub | grep -q ED25519'`
   - SEC-14: `ssh "${vm_ssh_host}" 'KID=$(chezmoi data | jq -r .signingkey); test -n "$KID" && test "$KID" != null && gpg --list-secret-keys --keyid-format LONG | grep -q "$KID"'`
   - SEC-16 (idempotency re-run): re-invoke Stage 2 a second time; assert no new keys registered (`gh ssh-key list` count unchanged) and exit code 0.

End with `summary; exit $?`.

The script MUST tolerate `prlctl` absence (so quick.sh + full.sh --no-vm flow remains usable on planner workstations) and MUST NOT delete or modify any host-side state outside of the VM.
  </action>
  <verify>
    <automated>cd /Users/jteague/.local/share/chezmoi && bash -n .planning/phases/1-credential-plane/checks/full.sh && bash -n .planning/phases/1-credential-plane/checks/vm-e2e.sh && bash -n .planning/phases/1-credential-plane/checks/parallels-helpers.sh && test -x .planning/phases/1-credential-plane/checks/full.sh && test -x .planning/phases/1-credential-plane/checks/vm-e2e.sh && bash .planning/phases/1-credential-plane/checks/full.sh --no-vm; rc=$?; test "$rc" -ne 0 || (echo "full.sh --no-vm unexpectedly GREEN before wave 1" && exit 1)</automated>
  </verify>
  <done>All three scripts syntactically valid; full.sh + vm-e2e.sh executable; `full.sh --no-vm` runs quick.sh and reports non-zero (Wave 1 not yet landed); vm-e2e.sh gracefully reports pending on machines without prlctl.</done>
</task>

</tasks>

<verification>
After all three tasks:
- `grep -c "^- \[ \] \*\*SEC-1[1-6]\*\*:" .planning/REQUIREMENTS.md` returns 6
- `bash .planning/phases/1-credential-plane/checks/quick.sh` exits non-zero with structural FAIL/PENDING rows for SEC-02/05/07/11/13(presence)/15 (these go GREEN as Wave 1 lands)
- `bash .planning/phases/1-credential-plane/checks/full.sh --no-vm` runs end-to-end, aggregates quick output, exits non-zero
- All five scripts pass `bash -n` syntax check
</verification>

<success_criteria>
- REQUIREMENTS.md amended with SEC-11..16 + traceability rows + coverage updated (75 total)
- Five harness scripts exist under `.planning/phases/1-credential-plane/checks/` (lib.sh, quick.sh, full.sh, vm-e2e.sh, parallels-helpers.sh)
- quick.sh runs in under 5 seconds; full.sh --no-vm runs in under 10 seconds
- vm-e2e.sh degrades gracefully (pending, exit 0) when prlctl is not installed
- All structural gates for SEC-02/05/07/11/13(presence)/15 implemented and FAIL-or-PENDING on the current source tree (Wave 1 turns them GREEN)
</success_criteria>

<output>
After completion, create `.planning/phases/1-credential-plane/1-01-SUMMARY.md` covering: harness scripts added, lib.sh delta from Phase 0.5 (new `assert_no_grep` helper), SEC-11..16 row content as committed, VM gating model (`--no-vm` fallback + prlctl-absent pending), and explicit handoff to Wave 1 plans (1-02, 1-03, 1-04) listing which `checks/quick.sh` gates each is expected to turn GREEN.
</output>
