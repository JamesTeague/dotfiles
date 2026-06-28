# 1-04b Script Review: setup-credentials.sh Attestation

**Date:** 2026-06-28
**Git SHA (setup-credentials.sh after 1-04b commit):** cb62ed8a5b421769f6cfe40f0451ee174b8f9cb0
**Plan:** 1-04b (GPG + signingkey + remote-rewrite)
**Reviewer:** Execution agent (autonomous structural review — no VM execution)

---

## Script Statistics

| Metric | Value |
|--------|-------|
| Total lines | 515 |
| Functions | 10: `usage`, `preflight`, `ensure_gh_auth`, `ssh_pubkey_registered`, `setup_ssh`, `gpg_keyid_registered`, `setup_gpg`, `write_signingkey`, `rewrite_remote`, `main` |
| Exit codes used | 0 (success), 1 (preflight/bad-arg), 2 (gh auth failure), 3 (SSH failure), 4 (GPG failure), 5 (signingkey write failure), 6 (remote rewrite / SSH smoke-test failure) |
| Exit code branches | 16 branches (lines 119, 123, 151, 199, 256, 278, 315, 320, 375, 385, 409, 426, 449, 478, 491, 512) |
| shellcheck | Not installed on this machine — `bash -n` syntax check: PASS |
| min_lines requirement | 250 — PASS (515 actual) |
| SEC-15 clean | PASS — zero matches for three-clause regex in all *.tmpl + .chezmoiscripts/ |

---

## Function Inventory

| Line | Function | Purpose |
|------|----------|---------|
| 63 | `usage()` | Help text with all four flags + examples |
| 132 | `preflight()` | Asserts gh, ssh-keygen, gpg, jq, chezmoi present |
| 160 | `ensure_gh_auth()` | Device-flow auth + scope verification |
| 210 | `ssh_pubkey_registered()` | Fingerprint-compare against gh ssh-key list |
| 238 | `setup_ssh()` | Ed25519 SSH keygen + idempotent registration |
| 291 | `gpg_keyid_registered()` | Key-ID-compare against gh gpg-key list |
| 307 | `setup_gpg()` | EDDSA/Ed25519 GPG keygen via param file + registration |
| 421 | `write_signingkey()` | Idempotent signingkey write to chezmoi.toml [data] |
| 466 | `rewrite_remote()` | SSH smoke-test + chezmoi remote rewrite (LAST step) |
| 500 | `main()` | Orchestrator: preflight → auth → ssh → gpg → signingkey → remote |

---

## Pitfall Coverage Matrix

| Pitfall | Status | Script Location | How Addressed |
|---------|--------|----------------|---------------|
| **Pitfall 1**: pinentry-mac stalls unattended GPG keygen | MITIGATED | Lines 358-373 (param file heredoc) | `%no-protection` in parameter file eliminates pinentry prompt entirely |
| **Pitfall 2**: `gh ssh-key add`/`gh gpg-key add` 422-exit-1 on duplicate (cli/cli#5085) | MITIGATED | Lines 210-233 (SSH), 291-303 (GPG) | `ssh_pubkey_registered()` fingerprint-compare; `gpg_keyid_registered()` key-ID-compare before any add call; stderr "already in use" as defense-in-depth fallback |
| **Pitfall 3**: bw/VaultWarden version drift | N/A (script scope) | n/a | VW not used in this script. Addressed by SEC-02 (packages.yaml PIN comment). |
| **Pitfall 4**: `chezmoi apply` reads bw via template | N/A (script scope) | n/a | SEC-15 structural gate. Script itself has zero bw/bitwarden executable references. |
| **Pitfall 5**: signingkey written to file chezmoi doesn't read | MITIGATED | Lines 426-457 (`write_signingkey`) | Writes to CHEZMOI_CFG (`~/.config/chezmoi/chezmoi.toml`) — the same file init produces. Post-write verify: `chezmoi data | jq -r '.signingkey'` must equal KEY_ID or exit 5. |
| **Pitfall 6**: SSH config IdentitiesOnly missing | N/A (script scope) | n/a | Owned by Plan 1-03's SSH config template. `IdentitiesOnly yes` confirmed present in `home/private_dot_ssh/config.tmpl`. |
| **Pitfall 7**: Remote rewrite before key registered | MITIGATED | Lines 468-481 (`rewrite_remote`) | `ssh -T git@github-personal` smoke test with `grep -q "successfully authenticated"` BEFORE any remote set-url call. Exit 6 if SSH auth fails. `rewrite_remote()` is the LAST function called in `main()`. |
| **Pitfall 8**: gpg-agent doesn't see new key in current session | MITIGATED | Lines 392-393 | `gpg-connect-agent reloadagent /bye >/dev/null 2>&1 \|\| true` after keygen (best-effort; non-fatal per design). |
| **Pitfall 9**: VM verification target stateful between runs | N/A (script scope) | n/a | Plan 1-05 VM verification handles. Snapshot restore between fresh-run and rotation-test scenarios documented in 1-RESEARCH. |
| **Pitfall 10**: Stale GitHub-side keys accumulate | MITIGATED | Lines 330-343 (ROTATE_GPG path), lines 242-247 (ROTATE_SSH path) | Both rotation paths log the old fingerprint/key-ID to stdout. Manual cleanup via `gh ssh-key delete` / `gh gpg-key delete` is documented in usage() and docs/credential-plane.md. |

---

## Idempotency Proof

Four paths the script takes on a second-run (re-run on already-configured machine):

### Path 1: gh auth already present with correct scopes
- **Line:** 176-179 (`ensure_gh_auth`)
- **Behavior:** `gh auth status -h github.com` succeeds; scope check finds all three scopes present; `printf '[auth] Already authenticated with required scopes — skipping login.\n'`; returns 0.
- **No-op:** Does not call `gh auth login`.

### Path 2: SSH key present locally + registered with GitHub
- **Line:** 250-262 (`setup_ssh` key-generation skip), 265-267 (`setup_ssh` registration skip)
- **Behavior:** `[[ -f "${SSH_KEY}" ]]` true → skip keygen. `ssh_pubkey_registered "${SSH_KEY}.pub"` returns 0 → `printf '[skip] SSH key already registered with GitHub.\n'`.
- **No-op:** Does not call `ssh-keygen` or `gh ssh-key add`.

### Path 3: GPG key present locally + registered with GitHub
- **Line:** 342-349 (`setup_gpg` idempotent skip)
- **Behavior:** `gpg --list-secret-keys --keyid-format LONG --with-colons "${EMAIL}"` finds EXISTING_KEYID; `gpg_keyid_registered "${EXISTING_KEYID}"` returns 0 → sets `KEY_ID="${EXISTING_KEYID}"` and returns 0.
- **No-op:** Does not call `gpg --batch --gen-key` or `gh gpg-key add`.

### Path 4: signingkey already in chezmoi data
- **Line:** 431-437 (`write_signingkey` sed-replace path)
- **Behavior:** `grep -qE '^\s*signingkey\s*=' "${CHEZMOI_CFG}"` succeeds → sed replaces with same value → post-write verify passes. Net change: file modified in-place with identical value (no semantic change).
- **Effectively idempotent:** sed may rewrite the line, but the value is identical. chezmoi apply ~/.gitconfig.local is re-triggered (best-effort; not harmful).

### Path 5: chezmoi remote already correct
- **Line:** 483-485 (`rewrite_remote` idempotency skip)
- **Behavior:** `CUR="$(chezmoi git -- remote get-url origin)"` equals `CHEZMOI_REMOTE_TARGET` → `printf '[skip] chezmoi remote already set to ...\n'`.
- **No-op:** Does not call `chezmoi git -- remote set-url`.

---

## Rotation Flag Behavior

| Flag | What gets deleted/logged | What gets regenerated | What gets re-registered |
|------|--------------------------|----------------------|------------------------|
| `--rotate-ssh` | Old SSH key fingerprint logged to stdout; `rm -f "${SSH_KEY}" "${SSH_KEY}.pub"` | New ed25519 key at `~/.ssh/personal_ed25519` | New pubkey via `gh ssh-key add` |
| `--rotate-gpg` | Old GPG long key IDs logged to stdout; `gpg --batch --yes --delete-secret-and-public-key` for each (best-effort, continue on error) | New EDDSA/Ed25519 GPG key via param file | New armored pubkey via `gh gpg-key add` |
| `--rotate-all` | Both of the above | Both of the above | Both of the above |

**GitHub-side stale cleanup:** Old keys are NOT deleted from GitHub automatically. The script logs the old fingerprint/key-ID to stdout. Manual cleanup: `gh ssh-key list` + `gh ssh-key delete <id>` / `gh gpg-key list` + `gh gpg-key delete <id>`. Quarterly procedure documented in `docs/credential-plane.md`.

**ROTATE path lines:**
- `--rotate-ssh`: lines 242-247 (log fingerprint + delete local files)
- `--rotate-gpg`: lines 327-342 (log IDs + `gpg --batch --yes --delete-secret-and-public-key`)

---

## Named-gate Verification Table

Run from repo root after Task 1 commit (`cb62ed8`):

```
bash .planning/phases/01-credential-plane/checks/quick.sh > /tmp/quick-1-04b.log 2>&1
```

| Gate | Required Pattern | Actual Output Line | Status |
|------|-----------------|-------------------|--------|
| SEC-08 | `chezmoi git -- remote set-url origin` in script | `✓ grep 'chezmoi git -- remote set-url origin' in .../setup-credentials.sh` | **PASS** |
| SEC-11 | Script exists, executable, not in .chezmoiscripts/ | Three ✓ lines under `== SEC-11 ...==` header | **PASS** |
| SEC-13 (presence) | `personal_ed25519` referenced in script | `✓ grep 'personal_ed25519' in .../setup-credentials.sh` | **PASS** |

**Note on grep pattern mismatch:** The plan's Task 2 verification commands use `grep -E 'SEC-11.*(PASS|✓)'` style patterns that look for SEC-XX and ✓ on the same line. The actual quick.sh output format puts the header (`== SEC-11 ... ==`) on one line and ✓ assertions on the next. The gates PASS substantively (confirmed via section-context grep and aggregate `PASS:36 PENDING:0 FAIL:0`). The pattern mismatch is a documentation quirk in the plan's verification command, not a gate failure.

**Aggregate result:** 36 PASS, 0 PENDING, 0 FAIL.

---

## SEC-15 Structural Check

```
grep -rEn '\bbw \b|bitwardenAttachment|\{\{ *bitwarden' home/ --include='*.tmpl'
```
Result: **0 matches** — PASS

```
grep -rEn '\bbw \b|bitwarden' home/.chezmoiscripts/
```
Result: **0 matches** — PASS

---

## Open Follow-ups for Plan 1-05

The following cannot be verified without VM access (these are structural gates satisfied by code; runtime behavior requires Plan 1-05 VM drill):

1. **SEC-09**: `git commit -S` produces a verified signature — requires a real GPG key on GitHub + a test repo on the VM.
2. **SEC-10**: `ssh -T git@github-personal` authenticates as personal identity — requires actual SSH key registered on GitHub.
3. **SEC-14 (runtime half)**: GPG key present in keyring matches `signingkey` in chezmoi data — structurally satisfied here; runtime confirmation is Plan 1-05.
4. **SEC-16**: End-to-end VM verification (Stage 1 + Stage 2 + signed commit + SSH auth + remote rewrite + idempotency re-run) — full VM drill is Plan 1-05.
5. **write_signingkey post-write verify (runtime)**: The `chezmoi data | jq -r '.signingkey'` verify runs at runtime; cannot execute without a live chezmoi.toml with [data].signingkey. Plan 1-05 confirms this path.

---

## Shellcheck Notes

`shellcheck` is not installed on this development machine. The following disables exist in the script (both from 1-04a, not new in 1-04b):

- Line 223: `# shellcheck disable=SC2016` — `$pk` is intentionally inside single-quotes for a `while-read` pipe; shell expansion is not intended there.

All other code was written to be shellcheck-clean (POSIX-safe quoting, no word-splitting on variables, no unquoted expansions). Runtime shellcheck on a machine with shellcheck installed is recommended before Plan 1-05 VM execution.
