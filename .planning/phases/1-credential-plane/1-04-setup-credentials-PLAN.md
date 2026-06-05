---
phase: 1-credential-plane
plan: 04
type: execute
wave: 2
depends_on:
  - "1-01"
files_modified:
  - home/scripts/setup-credentials.sh
autonomous: true
requirements:
  - SEC-08
  - SEC-11
  - SEC-12
  - SEC-13
  - SEC-14
must_haves:
  truths:
    - "home/scripts/setup-credentials.sh exists, is executable, NOT a run_once_ chezmoi script"
    - "Script --help output enumerates --rotate-ssh, --rotate-gpg, --rotate-all flags"
    - "Script is idempotent: re-running on an already-configured machine is a no-op (no duplicate keys registered)"
    - "Script generates ed25519 SSH key at ~/.ssh/personal_ed25519 with empty passphrase and title-comment <hostname>-personal-<YYYYMMDD>"
    - "Script generates EDDSA/Ed25519 GPG key via parameter file with %no-protection and registers via gh gpg-key add (armored, idempotent)"
    - "Script idempotently writes signingkey to ~/.config/chezmoi/chezmoi.toml [data] section and triggers chezmoi apply of ~/.gitconfig.local"
    - "Script rewrites chezmoi remote to git@github-personal:JamesTeague/dotfiles.git as the LAST step, AFTER smoke-testing ssh -T github-personal"
    - "Script lints clean with shellcheck (no SC2086/SC2034/SC2155 warnings, or each disable is commented)"
  artifacts:
    - path: "home/scripts/setup-credentials.sh"
      provides: "Operator-invoked Stage-2 credential bootstrap (gh auth + ssh keygen+register + gpg keygen+register + signingkey write + chezmoi remote rewrite)"
      min_lines: 200
  key_links:
    - from: "home/scripts/setup-credentials.sh"
      to: "gh CLI (auth login / ssh-key add / gpg-key add / ssh-key list / gpg-key list)"
      via: "shell-out calls"
      pattern: "gh (auth|ssh-key|gpg-key)"
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
Create the load-bearing artifact for Phase 1: `home/scripts/setup-credentials.sh`. This is the Stage-2 bootstrap script — operator runs it ONCE per machine after `chezmoi init --apply` completes — that takes a fresh machine from "Stage 1 GREEN, signing OFF" to "Stage 2 GREEN, signing ON, github-personal SSH auth working".

Purpose: Without this script, the per-machine-keys architecture has no implementation surface. Plan 1-02's gitconfig template gracefully omits signing when `.signingkey` is unset (that's the Stage-1-only path); Plan 1-03's SSH config references `~/.ssh/personal_ed25519` (which doesn't exist until this script generates it). This plan IS the credential bootstrap. Idempotency, rotation, and fingerprint-compare-before-register (cli/cli#5085 mitigation) are all in scope.

Output: One executable bash script (~200-300 lines including help/header/error handling). Sets up SEC-11/12/13/14 directly; enables SEC-08 (remote rewrite as last step); enables Stage-2 verifications (SEC-09 signed commit, SEC-10 ssh auth) that Plan 1-05 confirms on the VM.
</objective>

<execution_context>
@/Users/jteague/.claude/get-shit-done/workflows/execute-plan.md
@/Users/jteague/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/phases/1-credential-plane/1-CONTEXT.md
@.planning/phases/1-credential-plane/1-RESEARCH.md
@home/modify_dot_gitconfig.local

<interfaces>
Key research findings driving script design (from 1-RESEARCH.md):

1. **gh ssh-key add / gh gpg-key add are NOT idempotent** (cli/cli#5085). Workaround: enumerate registered keys via `gh ssh-key list --json key` + fingerprint-compare against local pubkey BEFORE attempting add. Same pattern for GPG with `gh gpg-key list --json keyId`.

2. **GPG keygen via parameter file** with `%no-protection` to skip pinentry-mac stall (Pitfall 1). Algorithm: `Key-Type: EDDSA` + `Key-Curve: Ed25519` matches the SSH choice and produces small modern keys.

3. **Long key ID extraction**: `gpg --list-secret-keys --keyid-format LONG --with-colons "$EMAIL" | awk -F: '/^sec:/ {print $5; exit}'` — colon output is the machine-parseable form.

4. **gh gpg-key add requires armored format** (starting with `-----BEGIN PGP PUBLIC KEY BLOCK-----`) per cli/cli#6528. Use `gpg --armor --export "$KEY_ID" | gh gpg-key add - --title "$TITLE"`.

5. **chezmoi data signingkey write** — target `~/.config/chezmoi/chezmoi.toml` `[data]` section (the file the existing init produces). Two cases: signingkey line already present → sed-replace; signingkey absent → awk-insert after `[data]` header. Idempotent.

6. **chezmoi git remote rewrite**: `chezmoi git -- remote set-url origin git@github-personal:JamesTeague/dotfiles.git` is canonical. Must be LAST step, AFTER smoke-testing `ssh -T git@github-personal` (Pitfall 7).

7. **gpg-connect-agent reloadagent /bye** after keygen so the current session's gpg-agent sees the new key (Pitfall 8).

8. **gh auth status check before gh auth login** — re-running login clobbers existing tokens. Detect auth state first; only run `gh auth login` if not authed or scopes insufficient (need `admin:public_key`, `admin:gpg_key`, `repo`).

Recommended SSH key title convention: `<hostname>-personal-<YYYYMMDD>` (per 1-RESEARCH.md Pitfall 10 — makes stale entries identifiable for fleet cleanup).

Recommended exit codes:
- 0 — success (fresh or idempotent re-run)
- 1 — pre-flight failure (gh / gpg / ssh-keygen missing)
- 2 — gh auth login failed / interrupted
- 3 — SSH key generation or registration failed
- 4 — GPG key generation or registration failed
- 5 — signingkey write to chezmoi config failed
- 6 — chezmoi remote rewrite or smoke test failed
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Author setup-credentials.sh with idempotent fresh-install path</name>
  <files>home/scripts/setup-credentials.sh</files>
  <action>
Create `home/scripts/setup-credentials.sh` as an executable bash script (`#!/usr/bin/env bash` shebang, `set -uo pipefail` — NOT `-e`, because we want to handle specific exit-1 cases gracefully).

**Script structure** (in order):

1. **Header banner comment block** (lines 1-30): purpose, two-stage architecture summary, link to `docs/credential-plane.md`, link to `phases/1-credential-plane/1-CONTEXT.md`. State explicitly: "Operator-invoked. NOT a chezmoi run_once_ script. Re-runnable; idempotent by default; rotation via --rotate-* flags."

2. **Constants block** (lines 30-60):
   - `KEY_DIR="${HOME}/.ssh"`
   - `SSH_KEY="${KEY_DIR}/personal_ed25519"`
   - `HOSTNAME_SHORT="$(hostname -s)"`
   - `TODAY="$(date +%Y%m%d)"`
   - `KEY_TITLE="${HOSTNAME_SHORT}-personal-${TODAY}"`
   - `CHEZMOI_CFG="${HOME}/.config/chezmoi/chezmoi.toml"`
   - `REQUIRED_SCOPES=("admin:public_key" "admin:gpg_key" "repo")`
   - `CHEZMOI_REMOTE_TARGET="git@github-personal:JamesTeague/dotfiles.git"`

3. **`usage()` function** (lines 60-90): prints help. Documents flags `--rotate-ssh`, `--rotate-gpg`, `--rotate-all`, `--help` / `-h`. Documents what each flag does. Documents default no-op behavior when already configured. Example invocations.

4. **Argument parser** (lines 90-110): parse `--help`, `--rotate-ssh`, `--rotate-gpg`, `--rotate-all`. Set booleans `ROTATE_SSH=0`, `ROTATE_GPG=0`. `--rotate-all` sets both. Unknown args → print usage to stderr + exit 1.

5. **Pre-flight checks** (lines 110-140): assert `command -v gh ssh-keygen gpg jq chezmoi >/dev/null 2>&1`. Each missing tool → fail loud with install hint + exit 1. Critical: this script assumes Stage 1 completed (so brew installed `gh gnupg jq chezmoi`).

6. **`ensure_gh_auth()` function** (lines 140-180):
   - `gh auth status -h github.com >/dev/null 2>&1` — if exit 0, check scopes via `gh auth status -h github.com 2>&1 | grep "Token scopes:"` and grep for all of `admin:public_key`, `admin:gpg_key`, `repo`. If all present, skip login.
   - Otherwise: `echo "Launching gh auth login (device flow) — enter the displayed code at https://github.com/login/device"; gh auth login --hostname github.com --git-protocol ssh --web -s admin:public_key,admin:gpg_key,repo` — if non-zero, exit 2 with "Re-run when ready" message.

7. **`ssh_pubkey_registered()` function** (lines 180-210): args: pubkey file path. Returns 0 if the fingerprint of that pubkey is already in `gh ssh-key list --json key --jq '.[].key'`. Implementation: extract local fingerprint with `ssh-keygen -lf "$1" | awk '{print $2}'`. Compare against registered fingerprints by piping each registered key through `ssh-keygen -lf -`. `grep -qFx` for exact match.

8. **`setup_ssh()` function** (lines 210-260):
   - If `$ROTATE_SSH==1` and `$SSH_KEY` exists: log old fingerprint to stdout for manual cleanup, then `rm -f "$SSH_KEY" "$SSH_KEY.pub"` and let the next branch regenerate.
   - If `$SSH_KEY` does NOT exist: `ssh-keygen -t ed25519 -N "" -C "$KEY_TITLE" -f "$SSH_KEY"`. On non-zero exit: fail with exit 3.
   - Idempotency check: `if ssh_pubkey_registered "$SSH_KEY.pub"; then echo "[skip] SSH key already registered with GitHub"; else gh ssh-key add "$SSH_KEY.pub" --title "$KEY_TITLE" --type authentication; fi`. On gh non-zero exit AND stderr doesn't say "key is already in use" → exit 3.

9. **`gpg_keyid_registered()` function** (lines 260-280): arg: long key ID. Returns 0 if `gh gpg-key list --json keyId --jq '.[].keyId'` contains exact match.

10. **`setup_gpg()` function** (lines 280-340):
    - Resolve EMAIL from chezmoi data: `EMAIL="$(chezmoi data | jq -r .email 2>/dev/null)"`. If empty / null → exit 4.
    - Resolve NAME similarly.
    - If `$ROTATE_GPG==1`: log existing key IDs (`gpg --list-secret-keys --keyid-format LONG --with-colons "$EMAIL" | awk -F: '/^sec:/ {print $5}'`) for manual cleanup, then `gpg --batch --yes --delete-secret-and-public-key "$KEYID"` for each (continue on error — local deletion can lag agent state).
    - Check existing: `EXISTING_KEYID="$(gpg --list-secret-keys --keyid-format LONG --with-colons "$EMAIL" 2>/dev/null | awk -F: '/^sec:/ {print $5; exit}')"`. If non-empty AND `gpg_keyid_registered "$EXISTING_KEYID"` → idempotent skip (set KEY_ID="$EXISTING_KEYID", continue to signingkey write).
    - Otherwise: write parameter file to a temp path via heredoc using `Key-Type: EDDSA`, `Key-Curve: Ed25519`, `Key-Usage: sign`, `Subkey-Type: ECDH`, `Subkey-Curve: Cv25519`, `Subkey-Usage: encrypt`, `Name-Real: $NAME`, `Name-Email: $EMAIL`, `Expire-Date: 0`, `%no-protection`, `%commit`. Run `gpg --batch --gen-key "$PARAM_FILE"`. On non-zero: exit 4. `rm "$PARAM_FILE"`.
    - Re-resolve `KEY_ID` from colon output (same awk pattern).
    - Reload agent: `gpg-connect-agent reloadagent /bye >/dev/null 2>&1 || true` (best-effort, Pitfall 8).
    - Register: `if gpg_keyid_registered "$KEY_ID"; then echo "[skip] GPG key already registered"; else gpg --armor --export "$KEY_ID" | gh gpg-key add - --title "$KEY_TITLE"; fi`. Non-zero gh exit (excluding "already in use") → exit 4.

11. **`write_signingkey()` function** (lines 340-380):
    - If `! test -f "$CHEZMOI_CFG"` → exit 5 with "chezmoi init must run first".
    - If `grep -qE '^\s*signingkey\s*=' "$CHEZMOI_CFG"`: `sed -i.bak "s|^\\s*signingkey\\s*=.*|  signingkey = \"$KEY_ID\"|" "$CHEZMOI_CFG"` and `rm "${CHEZMOI_CFG}.bak"`.
    - Else: detect `[data]` line; insert `  signingkey = "$KEY_ID"` after it via awk one-liner (see 1-RESEARCH.md Example 6 for the exact awk recipe). Write to `${CHEZMOI_CFG}.new` then `mv`.
    - Verify post-write: `chezmoi data | jq -r .signingkey | grep -qFx "$KEY_ID"` — if false, exit 5.
    - Trigger immediate gitconfig re-render: `chezmoi apply "${HOME}/.gitconfig.local"` (best-effort; non-zero is a warning not an exit since next routine apply will fix it).

12. **`rewrite_remote()` function** (lines 380-420):
    - Smoke test FIRST: `ssh -o StrictHostKeyChecking=accept-new -T git@github-personal 2>&1 | grep -q "successfully authenticated"` — `ssh -T` exits 1 by design, so check `${PIPESTATUS[0]}` for the grep, not `$?` for the ssh. If grep doesn't match → exit 6 with "SSH auth failed; remote rewrite skipped".
    - Get current remote: `CUR="$(chezmoi git -- remote get-url origin 2>/dev/null || true)"`.
    - If `$CUR == $CHEZMOI_REMOTE_TARGET` → idempotent skip with log.
    - Else: `chezmoi git -- remote set-url origin "$CHEZMOI_REMOTE_TARGET"` — non-zero → exit 6.

13. **`main()` function** (lines 420-end):
    - Print banner with hostname + date.
    - Call `ensure_gh_auth`, `setup_ssh`, `setup_gpg`, `write_signingkey`, `rewrite_remote` in order.
    - Final success banner: "Stage 2 complete. Verify: git commit -S --allow-empty -m verify && git log --show-signature -1".
    - Exit 0.

14. **End of file**: `main "$@"`.

**Critical**: NO references to `bw` / `bitwarden` / `bitwardenAttachment` anywhere in the executable code paths. The script MAY have one or two design-comment lines mentioning VW (e.g., "VW is runtime-only; this script does not touch it") — those are permitted per SEC-15's exception list, but keep them sparse.

**Lint requirement**: script passes `shellcheck -x home/scripts/setup-credentials.sh` with no errors. Allowed warnings only with inline `# shellcheck disable=SCNNNN` and a justifying comment.

After writing, `chmod +x home/scripts/setup-credentials.sh`.
  </action>
  <verify>
    <automated>cd /Users/jteague/.local/share/chezmoi && test -x home/scripts/setup-credentials.sh && bash -n home/scripts/setup-credentials.sh && bash home/scripts/setup-credentials.sh --help | grep -E "rotate-ssh" >/dev/null && bash home/scripts/setup-credentials.sh --help | grep -E "rotate-gpg" >/dev/null && bash home/scripts/setup-credentials.sh --help | grep -E "rotate-all" >/dev/null && grep -q "personal_ed25519" home/scripts/setup-credentials.sh && grep -q "EDDSA" home/scripts/setup-credentials.sh && grep -q "no-protection" home/scripts/setup-credentials.sh && grep -q "gh ssh-key list" home/scripts/setup-credentials.sh && grep -q "gh gpg-key list" home/scripts/setup-credentials.sh && grep -q "chezmoi git -- remote set-url" home/scripts/setup-credentials.sh && grep -q "signingkey" home/scripts/setup-credentials.sh && (command -v shellcheck >/dev/null 2>&1 && shellcheck -x home/scripts/setup-credentials.sh || echo "shellcheck not installed — skipping lint") && ! ls home/.chezmoiscripts/*setup-credentials* 2>/dev/null</automated>
  </verify>
  <done>Script executable, syntactically valid bash; --help enumerates all three rotation flags; script lives in home/scripts/ NOT home/.chezmoiscripts/ (verified by ls negation); references personal_ed25519, EDDSA+%no-protection, gh ssh-key list / gh gpg-key list (idempotency), chezmoi remote rewrite, signingkey write; shellcheck clean (if installed); SEC-11/12/13 (presence) gates in quick.sh turn GREEN.</done>
</task>

<task type="auto">
  <name>Task 2: Verify quick.sh passes for SEC-11/13(presence) and structural review of script paths</name>
  <files>.planning/phases/1-credential-plane/1-04-script-review.md</files>
  <action>
This task is a structural review checkpoint — Plan 1-04 is autonomous but the script is the highest-risk artifact in Phase 1. Run the structural harness and capture an in-tree review attestation.

1. Run `bash .planning/phases/1-credential-plane/checks/quick.sh` from the repo root. Capture stdout + stderr to `/tmp/quick-1-04.log`. Verify that SEC-11 and SEC-13 (presence) gates pass:
   - `assert_file home/scripts/setup-credentials.sh` → PASS
   - executable check → PASS
   - NOT-in-chezmoiscripts check → PASS (assert_cmd_zero_output)
   - `assert_grep "personal_ed25519" home/scripts/setup-credentials.sh` → PASS

2. Run SEC-15 grep manually as a defense check: `grep -rEn "\\bbw \\b|bitwardenAttachment|\\{\\{ *bitwarden" home/ --include='*.tmpl'` → zero matches. `grep -rEn "\\bbw \\b|bitwarden" home/.chezmoiscripts/` → zero matches. Print result.

3. Write `.planning/phases/1-credential-plane/1-04-script-review.md` containing:
   - Date + git SHA of setup-credentials.sh
   - Counts: total lines, function count, exit-code branches, shellcheck warnings (with justifications if any)
   - Pitfall coverage matrix: for each of Pitfalls 1-9 in 1-RESEARCH.md, cite the script line range that addresses it (or note "N/A — runtime-only, not script-side")
   - Idempotency proof: enumerate the four paths the script takes on second-run (already authed, ssh key present + registered, gpg key present + registered, signingkey already in chezmoi data) and cite the line that skips each
   - Rotation flag behavior: enumerate what `--rotate-ssh`, `--rotate-gpg`, `--rotate-all` delete + log + skip
   - Open follow-ups (if any) — anything Plan 1-05 verification surfaces but Plan 1-04 cannot fix without VM access

This artifact lives in the planning tree (not in the source tree) and is committed alongside the script. It is the audit trail for the highest-risk artifact in the phase.

Do NOT execute the script in this task — no VM available, would attempt to register keys. Only structural review.
  </action>
  <verify>
    <automated>cd /Users/jteague/.local/share/chezmoi && bash .planning/phases/1-credential-plane/checks/quick.sh > /tmp/quick-1-04.log 2>&1; grep -c "✓\|pass" /tmp/quick-1-04.log | awk '{exit ($1 >= 4) ? 0 : 1}' && test -f .planning/phases/1-credential-plane/1-04-script-review.md && grep -q "Pitfall" .planning/phases/1-credential-plane/1-04-script-review.md && grep -q "Idempotency" .planning/phases/1-credential-plane/1-04-script-review.md && grep -q "Rotation" .planning/phases/1-credential-plane/1-04-script-review.md && ! grep -rEn "\\bbw \\b|bitwardenAttachment|\\{\\{ *bitwarden" home/ --include='*.tmpl'</automated>
  </verify>
  <done>quick.sh reports at least 4 passes (SEC-05 from 1-02, SEC-02/07 from 1-03, SEC-11/13(presence) from 1-04, all sharing Plan 1-01's harness); script-review.md exists with all required sections; SEC-15 grep clean.</done>
</task>

</tasks>

<verification>
After both tasks:
- `bash home/scripts/setup-credentials.sh --help` enumerates all three rotation flags
- `bash -n home/scripts/setup-credentials.sh` passes syntax check
- Script lives in `home/scripts/` and NOT in `home/.chezmoiscripts/` (verified by ls)
- `bash .planning/phases/1-credential-plane/checks/quick.sh` shows SEC-11/13(presence) as PASS
- SEC-15 structural VW-independence grep remains GREEN
- `.planning/phases/1-credential-plane/1-04-script-review.md` exists with Pitfall/Idempotency/Rotation sections
</verification>

<success_criteria>
- SEC-08, SEC-11, SEC-12, SEC-13, SEC-14 are IMPLEMENTED (verification on VM happens in Plan 1-05)
- Script is operator-invoked (NOT a chezmoi run_once_)
- Script is idempotent on re-run; --rotate-* flags force regen
- Script lints clean with shellcheck (if installed)
- script-review.md provides the audit trail mapping each Pitfall to a line range and proving the four idempotency paths
- SEC-15 structural gate unchanged
</success_criteria>

<output>
After completion, create `.planning/phases/1-credential-plane/1-04-SUMMARY.md` covering: script statistics (LOC, functions, exit codes), Pitfall coverage matrix, idempotency proof, rotation behavior, link to 1-04-script-review.md, explicit handoff to Plan 1-05 listing the VM verifications that prove SEC-08/09/10/12/14/16 (SEC-09/10/14/16 cannot be verified in this plan — they need a fresh VM with the operator entering a device-flow code).
</output>
