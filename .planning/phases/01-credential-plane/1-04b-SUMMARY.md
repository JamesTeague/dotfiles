---
phase: 01-credential-plane
plan: 04b
subsystem: credential-bootstrap
tags: [bash, gpg, gh-cli, idempotency, SEC-08, SEC-12, SEC-14, stage2-bootstrap]
dependency_graph:
  requires:
    - 1-04a (setup-credentials.sh skeleton — auth + SSH half)
    - 1-01 (quick.sh harness — SEC-08/11/13 gates)
  provides:
    - home/scripts/setup-credentials.sh (complete: auth + SSH + GPG + signingkey + remote-rewrite)
    - .planning/phases/01-credential-plane/1-04b-script-review.md (audit trail attestation)
  affects:
    - 1-05 (VM verification depends on complete script from 1-04a + 1-04b)
    - 1-02 (gitconfig template already rewritten — write_signingkey() populates the .signingkey chezmoi data field at runtime)
tech_stack:
  added: []
  patterns:
    - parameter-file GPG keygen (Key-Type EDDSA / Key-Curve Ed25519 / %no-protection)
    - key-ID-compare-before-add (cli/cli#5085 GPG idempotency workaround)
    - post-write-verify (chezmoi data .signingkey cross-check after write)
    - smoke-before-rewrite (ssh -T before remote set-url)
    - gpg-connect-agent reloadagent (Pitfall 8 mitigation — best-effort)
key_files:
  created:
    - .planning/phases/01-credential-plane/1-04b-script-review.md
  modified:
    - home/scripts/setup-credentials.sh
decisions:
  - "KEY_ID exposed as a function-scoped variable from setup_gpg() to write_signingkey() via shared shell scope (no env export needed — same process)"
  - "write_signingkey() re-triggers chezmoi apply ~/.gitconfig.local immediately; non-zero is a warning not exit (next apply also renders it)"
  - "rewrite_remote() smoke-tests SSH via grep on ssh output rather than checking ssh exit code (ssh -T exits 1 by design)"
  - "gpg_keyid_registered() uses gh gpg-key list --json keyId (not full key content) — key IDs are the canonical match surface for GPG registration idempotency"
  - "Rotation paths log old IDs/fingerprints but do NOT auto-delete from GitHub; manual cleanup documented in docs/credential-plane.md"
metrics:
  duration_minutes: 18
  tasks_completed: 2
  files_created: 1
  files_modified: 1
  completed_date: "2026-06-28"
---

# Phase 1 Plan 04b: setup-credentials GPG + signingkey + remote-rewrite Summary

**One-liner:** Appended EDDSA/Ed25519 GPG keygen via parameter file with %no-protection (Pitfall 1), idempotent gh gpg-key registration (cli/cli#5085), signingkey write to chezmoi.toml [data], and SSH-smoke-first remote rewrite to `git@github-personal:...`, completing the 515-line setup-credentials.sh.

## What Was Done

### Task 1: Append GPG/signingkey/remote-rewrite functions + complete main()

Added four new function bodies to `home/scripts/setup-credentials.sh` (built by Plan 1-04a) and replaced the three `TODO(1-04b)` marker lines in `main()` with actual function calls.

**Script statistics (final):**

| Metric | Value |
|--------|-------|
| Total lines | 515 (was 304 after 1-04a) |
| Functions | 10: usage, preflight, ensure_gh_auth, ssh_pubkey_registered, setup_ssh, gpg_keyid_registered, setup_gpg, write_signingkey, rewrite_remote, main |
| Exit codes | 0-6 (all 7 codes used; 0=success, 1=preflight/arg, 2=gh-auth, 3=SSH, 4=GPG, 5=signingkey, 6=remote) |
| bash -n | PASS |
| shellcheck | Not installed on this machine; script written to shellcheck-clean conventions |
| min_lines requirement | 250 — PASS (515) |

**New function bodies:**

1. **`gpg_keyid_registered()` (lines 291-303):** Takes a long GPG key ID (16 hex chars). Fetches registered key IDs via `gh gpg-key list --json keyId --jq '.[].keyId'` and does exact-match grep. Returns 0 if registered, 1 if not. This is the cli/cli#5085 mitigation for GPG (parallel to the fingerprint-compare for SSH).

2. **`setup_gpg()` (lines 307-418):** Resolves EMAIL and NAME from `chezmoi data | jq`. Handles `--rotate-gpg`: logs existing key IDs, calls `gpg --batch --yes --delete-secret-and-public-key` for each (best-effort). Idempotency check: if existing local key + already registered → set KEY_ID and return. Otherwise: writes parameter file to tempfile via heredoc (`Key-Type: EDDSA`, `Key-Curve: Ed25519`, `Key-Usage: sign`, `Subkey-Type: ECDH`, `Subkey-Curve: Cv25519`, `Subkey-Usage: encrypt`, `%no-protection`, `%commit`), runs `gpg --batch --gen-key`, resolves KEY_ID via colon output awk, calls `gpg-connect-agent reloadagent /bye` (Pitfall 8), then idempotent registration via `gpg --armor --export | gh gpg-key add -` (armored format per cli/cli#6528).

3. **`write_signingkey()` (lines 421-460):** Guards on `CHEZMOI_CFG` existence (exit 5 if absent). If signingkey line already present: `sed -i.bak` replace + `rm .bak`. If absent: awk-insert after `[data]` header (per 1-RESEARCH Example 6). Post-write verify: `chezmoi data | jq -r '.signingkey // empty'` must equal KEY_ID or exit 5. Triggers `chezmoi apply ~/.gitconfig.local` immediately (best-effort; warning not exit on failure).

4. **`rewrite_remote()` (lines 466-497):** SSH smoke test FIRST (Pitfall 7): `ssh -o StrictHostKeyChecking=accept-new -T git@github-personal 2>&1` piped to grep for "successfully authenticated" — uses the grep result, not ssh's exit code (ssh -T exits 1 by design). Exit 6 if auth fails. Gets current remote, compares to `CHEZMOI_REMOTE_TARGET`; if already correct → skip. Otherwise: `chezmoi git -- remote set-url origin "${CHEZMOI_REMOTE_TARGET}"`.

**main() TODO marker replacement:**

```bash
# BEFORE (1-04a state):
  # TODO(1-04b): setup_gpg
  # TODO(1-04b): write_signingkey
  # TODO(1-04b): rewrite_remote

# AFTER (1-04b state):
  setup_gpg
  write_signingkey
  rewrite_remote
```

`rewrite_remote` is the LAST function call in main(), after the success banner is the only subsequent line.

### Task 2: Write 1-04b-script-review.md attestation

Created `.planning/phases/01-credential-plane/1-04b-script-review.md` as the audit trail for the Phase 1 load-bearing artifact.

**Document sections:**
- Script statistics (515 lines, 10 functions, exit codes 0-6)
- Function inventory table with line numbers
- Pitfall coverage matrix (all 10 pitfalls, MITIGATED / N/A with script line refs)
- Idempotency proof (5 paths with exact line numbers)
- Rotation flag behavior table
- Named-gate verification table (SEC-08, SEC-11, SEC-13(presence) all PASS)
- Open follow-ups for Plan 1-05 (SEC-09/10/14/16 require VM)
- Shellcheck notes

## Quick.sh Gate Results

Run after both task commits (`ca5bb4d`):

| Gate | Result | Notes |
|------|--------|-------|
| SEC-08 (remote set-url present) | PASS | Live `chezmoi git -- remote set-url origin` call now in rewrite_remote() |
| SEC-11 (script exists, executable, not in .chezmoiscripts) | PASS | All three assertions green |
| SEC-13 (presence) (personal_ed25519 referenced) | PASS | Referenced in SSH_KEY constant + setup_ssh |
| SEC-15 (VaultWarden independence) | PASS | 0 matches in all *.tmpl + .chezmoiscripts/ |
| SEC-05(a) (generate-gpg-key.sh deleted) | PASS (pre-existing) | Owned by Plan 1-02 |
| SEC-05(b) (modify_dot_gitconfig.local signingkey) | PASS (pre-existing) | Owned by Plan 1-02 |
| SEC-02 (bw pin) | PASS (pre-existing) | Owned by Plan 1-03 |

**Aggregate:** 36 PASS, 0 PENDING, 0 FAIL

## Handoff to Plan 1-05

Plan 1-05 provides VM verification for the requirements this plan implements structurally but cannot prove without a live machine:

1. **SEC-09**: `git commit -S` produces a verified signature (requires real GPG key on GitHub + test repo on VM).
2. **SEC-10**: `ssh -T git@github-personal` returns GitHub welcome (requires SSH key registered on GitHub).
3. **SEC-14 (runtime)**: `chezmoi data | jq -r .signingkey` matches the registered GPG key in the keyring (structurally correct here; runtime confirmation is Plan 1-05).
4. **SEC-16**: Full end-to-end VM drill (Stage 1 + Stage 2 + signed commit + SSH + remote + idempotency + rotation).

## Deviations from Plan

**1. [Rule 1 - Bug] Named-gate grep pattern in plan's Task 2 verify command doesn't match harness output format**

- **Found during:** Task 2 verification
- **Issue:** The plan's Task 2 automated verify uses `grep -E 'SEC-11.*(PASS|✓)'` style patterns that expect SEC-XX and ✓ on the same line. The actual quick.sh output format puts the section header (`== SEC-11 ... ==`) on one line and ✓ assertion lines below. The grep patterns never match.
- **Fix:** Documented the mismatch in the script-review artifact. The actual gates were verified via section-context grep (`grep -A4 "SEC-11 ..." | grep -q "✓"`). The aggregate `36 PASS, 0 FAIL` is also confirmation. The plan's grep patterns are a documentation quirk, not a gate failure.
- **Impact:** None on correctness — all three named gates PASS. The fix is self-contained in the review document.

## SEC-15 Verification

```
grep -rEn '\bbw \b|bitwardenAttachment|\{\{ *bitwarden' home/ --include='*.tmpl'
```
Result: **0 matches** — SEC-15 compliant.

```
grep -rEn '\bbw \b|bitwarden' home/.chezmoiscripts/
```
Result: **0 matches** — SEC-15 compliant.

No executable code paths reference bw/bitwarden in either the new functions or any other template.

## Self-Check

### Files Created

- [x] `.planning/phases/01-credential-plane/1-04b-script-review.md` — exists at `/Users/jteague/.local/share/chezmoi/.planning/phases/01-credential-plane/1-04b-script-review.md`

### Files Modified

- [x] `home/scripts/setup-credentials.sh` — 515 lines (was 304), executable, bash -n PASS

### Commits

- [x] `cb62ed8` — feat(01-04b): append GPG/signingkey/rewrite_remote functions + complete main()
- [x] `ca5bb4d` — feat(01-04b): add script-review attestation for setup-credentials.sh

### Key Assertions

- [x] `bash -n home/scripts/setup-credentials.sh` — PASS
- [x] `bash home/scripts/setup-credentials.sh --help | grep -E "rotate-ssh"` — PASS
- [x] `bash home/scripts/setup-credentials.sh --help | grep -E "rotate-gpg"` — PASS
- [x] `bash home/scripts/setup-credentials.sh --help | grep -E "rotate-all"` — PASS
- [x] `! grep -q "TODO(1-04b)" home/scripts/setup-credentials.sh` — PASS (all three markers replaced)
- [x] `grep -q "EDDSA"` — PASS
- [x] `grep -q "no-protection"` — PASS
- [x] `grep -q "gh gpg-key list"` — PASS
- [x] `grep -q "chezmoi git -- remote set-url"` — PASS (live function call, not just comment)
- [x] `grep -q "signingkey"` — PASS
- [x] rewrite_remote is LAST call in main() (line 510, before success banner at line 511)
- [x] SEC-08 PASS in quick.sh
- [x] SEC-11 PASS in quick.sh
- [x] SEC-13(presence) PASS in quick.sh
- [x] SEC-15 PASS in quick.sh
- [x] Script NOT in `home/.chezmoiscripts/` — PASS
- [x] `wc -l home/scripts/setup-credentials.sh` → 515 (≥ 250) — PASS

## Self-Check: PASSED
