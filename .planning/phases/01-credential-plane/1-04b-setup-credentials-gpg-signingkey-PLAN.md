---
phase: 01-credential-plane
plan: 04b
type: execute
wave: 2
depends_on:
  - "1-01"
  - "1-04a"
files_modified:
  - home/scripts/setup-credentials.sh
  - .planning/phases/01-credential-plane/1-04b-script-review.md
autonomous: true
requirements:
  - SEC-08
  - SEC-12
  - SEC-14
must_haves:
  truths:
    - "Script is idempotent: re-running on an already-configured machine is a no-op (no duplicate keys registered)"
    - "setup_gpg() function generates EDDSA/Ed25519 GPG key via parameter file with %no-protection and registers via gh gpg-key add (armored, idempotent)"
    - "write_signingkey() idempotently writes signingkey to ~/.config/chezmoi/chezmoi.toml [data] section and triggers chezmoi apply of ~/.gitconfig.local"
    - "rewrite_remote() rewrites chezmoi remote to git@github-personal:JamesTeague/dotfiles.git as the LAST step, AFTER smoke-testing ssh -T github-personal"
    - "main() calls setup_gpg + write_signingkey + rewrite_remote in order, replacing the three TODO(1-04b) markers from Plan 1-04a"
    - "Script lints clean with shellcheck (no SC2086/SC2034/SC2155 warnings, or each disable is commented)"
    - "1-04b-script-review.md exists with Pitfall coverage matrix, idempotency proof, and rotation behavior sections"
  artifacts:
    - path: "home/scripts/setup-credentials.sh"
      provides: "Complete operator-invoked Stage-2 credential bootstrap (1-04a auth+SSH + 1-04b GPG+signingkey+remote-rewrite)"
      min_lines: 250
    - path: ".planning/phases/01-credential-plane/1-04b-script-review.md"
      provides: "Audit-trail attestation for the highest-risk artifact in Phase 1"
      min_lines: 40
  key_links:
    - from: "home/scripts/setup-credentials.sh"
      to: "gh CLI (gpg-key add / gpg-key list)"
      via: "shell-out calls in setup_gpg + gpg_keyid_registered"
      pattern: "gh gpg-key"
    - from: "home/scripts/setup-credentials.sh"
      to: "~/.config/chezmoi/chezmoi.toml [data].signingkey"
      via: "idempotent sed/awk write under [data] section"
      pattern: "signingkey"
    - from: "home/scripts/setup-credentials.sh"
      to: "chezmoi git remote (origin)"
      via: "chezmoi git -- remote set-url origin"
      pattern: "remote set-url origin"
    - from: "home/scripts/setup-credentials.sh"
      to: "home/modify_dot_gitconfig.local (rendered)"
      via: "chezmoi apply ~/.gitconfig.local trigger after signingkey write"
      pattern: "chezmoi apply"
---

<objective>
Append the GPG keygen + signingkey write + chezmoi remote rewrite functionality to `home/scripts/setup-credentials.sh` (built by Plan 1-04a), then produce the script-review attestation artifact for the completed file.

Purpose: 1-04a established the script scaffolding, gh auth path, and SSH keygen/registration. 1-04b lands the GPG side (the highest-risk new code per 1-RESEARCH Pitfall analysis — Pitfall 1 pinentry stall, Pitfall 8 agent reload, cli/cli#6528 armored-format requirement), the signingkey write (which unblocks Plan 1-02's gitconfig template), and the chezmoi remote rewrite (which MUST happen last, after smoke-testing SSH). The script-review attestation is the audit trail mapping each Pitfall to a script line range — required because the script is the load-bearing artifact for Phase 1.

Output: Three new function bodies appended to the script (setup_gpg, write_signingkey, rewrite_remote), main() updated to call them in order (TODO markers replaced), and `.planning/phases/01-credential-plane/1-04b-script-review.md` capturing the audit trail.
</objective>

<execution_context>
@/Users/jteague/.claude/get-shit-done/workflows/execute-plan.md
@/Users/jteague/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/phases/01-credential-plane/1-CONTEXT.md
@.planning/phases/01-credential-plane/1-RESEARCH.md
@home/scripts/setup-credentials.sh
@home/modify_dot_gitconfig.local

<interfaces>
Key research findings driving this half (from 1-RESEARCH.md):

1. **gh gpg-key add is NOT idempotent** (cli/cli#5085). Workaround: enumerate registered keys via `gh gpg-key list --json keyId` + key-ID-compare BEFORE attempting add.

2. **GPG keygen via parameter file** with `%no-protection` to skip pinentry-mac stall (Pitfall 1). Algorithm: `Key-Type: EDDSA` + `Key-Curve: Ed25519` matches the SSH choice and produces small modern keys.

3. **Long key ID extraction**: `gpg --list-secret-keys --keyid-format LONG --with-colons "$EMAIL" | awk -F: '/^sec:/ {print $5; exit}'` — colon output is the machine-parseable form.

4. **gh gpg-key add requires armored format** (starting with `-----BEGIN PGP PUBLIC KEY BLOCK-----`) per cli/cli#6528. Use `gpg --armor --export "$KEY_ID" | gh gpg-key add - --title "$TITLE"`.

5. **chezmoi data signingkey write** — target `~/.config/chezmoi/chezmoi.toml` `[data]` section (the file the existing init produces). Two cases: signingkey line already present → sed-replace; signingkey absent → awk-insert after `[data]` header. Idempotent.

6. **chezmoi git remote rewrite**: `chezmoi git -- remote set-url origin git@github-personal:JamesTeague/dotfiles.git` is canonical. Must be LAST step, AFTER smoke-testing `ssh -T git@github-personal` (Pitfall 7).

7. **gpg-connect-agent reloadagent /bye** after keygen so the current session's gpg-agent sees the new key (Pitfall 8).

Exit codes used by this plan: 4, 5, 6 (reserved by 1-04a's interfaces block).

**Handoff contract from Plan 1-04a**: The script has three `TODO(1-04b):` marker lines inside main() in exact form:
```
# TODO(1-04b): setup_gpg
# TODO(1-04b): write_signingkey
# TODO(1-04b): rewrite_remote
```
This plan replaces those with the function calls and appends the function bodies ABOVE main().

<!-- SEC-15 contract (canonical from Plan 1-01 interfaces block): -->
<!-- Three-clause regex: \bbw \b|bitwardenAttachment|\{\{ *bitwarden -->
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Append GPG/signingkey/remote-rewrite functions + complete main()</name>
  <files>home/scripts/setup-credentials.sh</files>
  <action>
Edit `home/scripts/setup-credentials.sh` (created by Plan 1-04a). The edit has two halves:

**Half A — Append three new function bodies** above the `main()` function definition (preserve all 1-04a content intact):

1. **`gpg_keyid_registered()` function**: arg: long key ID. Returns 0 if `gh gpg-key list --json keyId --jq '.[].keyId'` contains exact match.

2. **`setup_gpg()` function**:
    - Resolve EMAIL from chezmoi data: `EMAIL="$(chezmoi data | jq -r .email 2>/dev/null)"`. If empty / null → exit 4.
    - Resolve NAME similarly.
    - If `$ROTATE_GPG==1`: log existing key IDs (`gpg --list-secret-keys --keyid-format LONG --with-colons "$EMAIL" | awk -F: '/^sec:/ {print $5}'`) for manual cleanup, then `gpg --batch --yes --delete-secret-and-public-key "$KEYID"` for each (continue on error — local deletion can lag agent state).
    - Check existing: `EXISTING_KEYID="$(gpg --list-secret-keys --keyid-format LONG --with-colons "$EMAIL" 2>/dev/null | awk -F: '/^sec:/ {print $5; exit}')"`. If non-empty AND `gpg_keyid_registered "$EXISTING_KEYID"` → idempotent skip (set KEY_ID="$EXISTING_KEYID", continue to signingkey write).
    - Otherwise: write parameter file to a temp path via heredoc using `Key-Type: EDDSA`, `Key-Curve: Ed25519`, `Key-Usage: sign`, `Subkey-Type: ECDH`, `Subkey-Curve: Cv25519`, `Subkey-Usage: encrypt`, `Name-Real: $NAME`, `Name-Email: $EMAIL`, `Expire-Date: 0`, `%no-protection`, `%commit`. Run `gpg --batch --gen-key "$PARAM_FILE"`. On non-zero: exit 4. `rm "$PARAM_FILE"`.
    - Re-resolve `KEY_ID` from colon output (same awk pattern).
    - Reload agent: `gpg-connect-agent reloadagent /bye >/dev/null 2>&1 || true` (best-effort, Pitfall 8).
    - Register: `if gpg_keyid_registered "$KEY_ID"; then echo "[skip] GPG key already registered"; else gpg --armor --export "$KEY_ID" | gh gpg-key add - --title "$KEY_TITLE"; fi`. Non-zero gh exit (excluding "already in use") → exit 4.

3. **`write_signingkey()` function**:
    - If `! test -f "$CHEZMOI_CFG"` → exit 5 with "chezmoi init must run first".
    - If `grep -qE '^\s*signingkey\s*=' "$CHEZMOI_CFG"`: `sed -i.bak "s|^\\s*signingkey\\s*=.*|  signingkey = \"$KEY_ID\"|" "$CHEZMOI_CFG"` and `rm "${CHEZMOI_CFG}.bak"`.
    - Else: detect `[data]` line; insert `  signingkey = "$KEY_ID"` after it via awk one-liner (see 1-RESEARCH.md Example 6 for the exact awk recipe). Write to `${CHEZMOI_CFG}.new` then `mv`.
    - Verify post-write: `chezmoi data | jq -r .signingkey | grep -qFx "$KEY_ID"` — if false, exit 5.
    - Trigger immediate gitconfig re-render: `chezmoi apply "${HOME}/.gitconfig.local"` (best-effort; non-zero is a warning not an exit since next routine apply will fix it).

4. **`rewrite_remote()` function**:
    - Smoke test FIRST: `ssh -o StrictHostKeyChecking=accept-new -T git@github-personal 2>&1 | grep -q "successfully authenticated"` — `ssh -T` exits 1 by design, so check `${PIPESTATUS[0]}` for the grep, not `$?` for the ssh. If grep doesn't match → exit 6 with "SSH auth failed; remote rewrite skipped".
    - Get current remote: `CUR="$(chezmoi git -- remote get-url origin 2>/dev/null || true)"`.
    - If `$CUR == $CHEZMOI_REMOTE_TARGET` → idempotent skip with log.
    - Else: `chezmoi git -- remote set-url origin "$CHEZMOI_REMOTE_TARGET"` — non-zero → exit 6.

**Half B — Replace the three TODO markers in main()** with the actual function calls, in order:
- `# TODO(1-04b): setup_gpg` → `setup_gpg`
- `# TODO(1-04b): write_signingkey` → `write_signingkey`
- `# TODO(1-04b): rewrite_remote` → `rewrite_remote`

Preserve the post-call success banner verbatim.

**Critical**: Same SEC-15 rule — NO `bw` / `bitwarden` references in executable code paths. The handful of design-comment lines from 1-04a remain; do not introduce more.

**Lint requirement**: script passes `shellcheck -x home/scripts/setup-credentials.sh` with no errors on the complete file. Allowed warnings only with inline `# shellcheck disable=SCNNNN` and a justifying comment.

After editing, the script remains executable (no chmod needed — preserved from 1-04a).
  </action>
  <verify>
    <automated>cd /Users/jteague/.local/share/chezmoi && test -x home/scripts/setup-credentials.sh && bash -n home/scripts/setup-credentials.sh && ! grep -q "TODO(1-04b)" home/scripts/setup-credentials.sh && grep -q "setup_gpg" home/scripts/setup-credentials.sh && grep -q "write_signingkey" home/scripts/setup-credentials.sh && grep -q "rewrite_remote" home/scripts/setup-credentials.sh && grep -q "EDDSA" home/scripts/setup-credentials.sh && grep -q "no-protection" home/scripts/setup-credentials.sh && grep -q "gh gpg-key list" home/scripts/setup-credentials.sh && grep -q "chezmoi git -- remote set-url" home/scripts/setup-credentials.sh && grep -q "signingkey" home/scripts/setup-credentials.sh && (command -v shellcheck >/dev/null 2>&1 && shellcheck -x home/scripts/setup-credentials.sh || echo "shellcheck not installed — skipping lint") && ! grep -E "\\bbw \\b|bitwardenAttachment|\\{\\{ *bitwarden" home/scripts/setup-credentials.sh | grep -v "^[[:space:]]*#"</automated>
  </verify>
  <done>All three TODO(1-04b) markers replaced with function calls; setup_gpg/write_signingkey/rewrite_remote function bodies appended; references EDDSA+%no-protection, gh gpg-key list (cli/cli#5085 idempotency), chezmoi remote rewrite, signingkey write; bash-syntax clean; shellcheck clean (if installed); SEC-08, SEC-14 structural gates in quick.sh turn GREEN.</done>
</task>

<task type="auto">
  <name>Task 2: Write 1-04b-script-review.md attestation + verify SEC-11/13(presence)/SEC-08 gates by name</name>
  <files>.planning/phases/01-credential-plane/1-04b-script-review.md</files>
  <action>
This task is a structural review checkpoint — the script is the highest-risk artifact in Phase 1. Run the structural harness, verify specific gates by NAME (not aggregate count), and capture an in-tree review attestation.

1. Run `bash .planning/phases/01-credential-plane/checks/quick.sh` from the repo root. Capture stdout + stderr to `/tmp/quick-1-04b.log`.

2. Verify specific gates by NAME (this is the strict version — aggregate-pass counts are not sufficient because sibling-plan gates may be RED). Required PASSes (each by name):
   - **SEC-11 PASS**: `grep -E 'SEC-11.*(PASS|✓)' /tmp/quick-1-04b.log`
   - **SEC-13 (presence) PASS**: `grep -E 'SEC-13.*present.*(PASS|✓)' /tmp/quick-1-04b.log` — matches the "personal_ed25519 referenced" assertion banner (verbatim banner text comes from 1-01 lib.sh interfaces)
   - **SEC-08 PASS**: `grep -E 'SEC-08.*(PASS|✓)' /tmp/quick-1-04b.log` — matches the `chezmoi git -- remote set-url origin` structural assertion

   If any of the three named gates is RED, FAIL this task. Aggregate counts (≥N PASSes) are NOT acceptable — name-by-name assertion is the contract.

3. Run SEC-15 grep manually as a defense check (canonical three-clause regex):
   - `grep -rEn '\bbw \b|bitwardenAttachment|\{\{ *bitwarden' home/ --include='*.tmpl'` → zero matches
   - `grep -rEn '\bbw \b|bitwarden' home/.chezmoiscripts/` → zero matches
   - Print result.

4. Write `.planning/phases/01-credential-plane/1-04b-script-review.md` containing:
   - Date + git SHA of setup-credentials.sh (after 1-04b's commit)
   - Counts: total lines, function count (8: usage, ensure_gh_auth, ssh_pubkey_registered, setup_ssh, gpg_keyid_registered, setup_gpg, write_signingkey, rewrite_remote + main), exit-code branches (0-6), shellcheck warnings (with justifications if any)
   - Pitfall coverage matrix: for each of Pitfalls 1-9 in 1-RESEARCH.md, cite the script line range that addresses it (or note "N/A — runtime-only, not script-side")
   - Idempotency proof: enumerate the four paths the script takes on second-run (already authed, ssh key present + registered, gpg key present + registered, signingkey already in chezmoi data) and cite the line that skips each
   - Rotation flag behavior: enumerate what `--rotate-ssh`, `--rotate-gpg`, `--rotate-all` delete + log + skip
   - Named-gate verification table: SEC-08, SEC-11, SEC-13(presence) → PASS/RED status from /tmp/quick-1-04b.log grep output
   - Open follow-ups (if any) — anything Plan 1-05 verification surfaces but 1-04b cannot fix without VM access

This artifact lives in the planning tree (not in the source tree) and is committed alongside the script edit. It is the audit trail for the highest-risk artifact in the phase.

Do NOT execute the script in this task — no VM available, would attempt to register keys. Only structural review.
  </action>
  <verify>
    <automated>cd /Users/jteague/.local/share/chezmoi && bash .planning/phases/01-credential-plane/checks/quick.sh > /tmp/quick-1-04b.log 2>&1; grep -E 'SEC-11.*(PASS|✓)' /tmp/quick-1-04b.log >/dev/null && grep -E 'SEC-13.*present.*(PASS|✓)' /tmp/quick-1-04b.log >/dev/null && grep -E 'SEC-08.*(PASS|✓)' /tmp/quick-1-04b.log >/dev/null && test -f .planning/phases/01-credential-plane/1-04b-script-review.md && grep -q "Pitfall" .planning/phases/01-credential-plane/1-04b-script-review.md && grep -q "Idempotency" .planning/phases/01-credential-plane/1-04b-script-review.md && grep -q "Rotation" .planning/phases/01-credential-plane/1-04b-script-review.md && grep -q "Named-gate" .planning/phases/01-credential-plane/1-04b-script-review.md && ! grep -rEn '\bbw \b|bitwardenAttachment|\{\{ *bitwarden' home/ --include='*.tmpl'</automated>
  </verify>
  <done>quick.sh reports SEC-08, SEC-11, and SEC-13(presence) all PASS by name (not aggregate count); 1-04b-script-review.md exists with all required sections including the named-gate verification table; SEC-15 three-clause grep clean.</done>
</task>

</tasks>

<verification>
After both tasks:
- `bash home/scripts/setup-credentials.sh --help` still enumerates all three rotation flags
- `bash -n home/scripts/setup-credentials.sh` passes syntax check
- All three `TODO(1-04b)` markers gone
- Script lives in `home/scripts/` and NOT in `home/.chezmoiscripts/`
- `bash .planning/phases/01-credential-plane/checks/quick.sh` shows SEC-08, SEC-11, SEC-13(presence) PASS by name
- SEC-15 three-clause structural VW-independence grep remains GREEN
- `.planning/phases/01-credential-plane/1-04b-script-review.md` exists with Pitfall/Idempotency/Rotation/Named-gate sections
</verification>

<success_criteria>
- SEC-08, SEC-12, SEC-14 are IMPLEMENTED (VM verification of SEC-08/14 + flag-help SEC-12 happens in Plan 1-05)
- Script is operator-invoked (NOT a chezmoi run_once_)
- Script is idempotent on re-run; --rotate-* flags force regen
- Script lints clean with shellcheck (if installed)
- 1-04b-script-review.md provides the audit trail mapping each Pitfall to a line range, proving the four idempotency paths, and named-gate verification table
- Named-gate assertion (not aggregate-count) is the contract for Plan 1-05's dependency on this plan
- SEC-15 three-clause structural gate unchanged
</success_criteria>

<output>
After completion, create `.planning/phases/01-credential-plane/1-04b-SUMMARY.md` covering: script statistics (LOC, functions, exit codes 0-6), Pitfall coverage matrix, idempotency proof, rotation behavior, link to 1-04b-script-review.md, the named-gate verification table (SEC-08/11/13-presence), and explicit handoff to Plan 1-05 listing the VM verifications that prove SEC-08/09/10/14/16 (SEC-09/10/14/16 cannot be verified in this plan — they need a fresh VM with the operator entering a device-flow code).
</output>
