---
phase: 01-credential-plane
plan: 04a
type: execute
wave: 2
depends_on:
  - "1-01"
files_modified:
  - home/scripts/setup-credentials.sh
autonomous: true
requirements:
  - SEC-11
  - SEC-12
  - SEC-13
must_haves:
  truths:
    - "home/scripts/setup-credentials.sh exists, is executable, NOT a run_once_ chezmoi script"
    - "Script --help output enumerates --rotate-ssh, --rotate-gpg, --rotate-all flags"
    - "Script header/constants/usage/argparse/preflight sections are present and bash-syntax-clean"
    - "ensure_gh_auth() function is present and references admin:public_key, admin:gpg_key, repo scopes"
    - "setup_ssh() function generates ed25519 SSH key at ~/.ssh/personal_ed25519 with empty passphrase and title-comment <hostname>-personal-<YYYYMMDD>"
    - "ssh_pubkey_registered() function uses gh ssh-key list --json key for idempotent fingerprint-compare-before-add (cli/cli#5085 mitigation)"
    - "main() function skeleton in place calling ensure_gh_auth + setup_ssh; placeholders/TODO comments mark where Plan 1-04b appends setup_gpg + write_signingkey + rewrite_remote"
    - "Script lints clean with shellcheck on the partial body (no SC2086/SC2034/SC2155 warnings, or each disable is commented)"
  artifacts:
    - path: "home/scripts/setup-credentials.sh"
      provides: "Operator-invoked Stage-2 credential bootstrap — auth + SSH path (Plan 1-04b appends GPG + signingkey + remote rewrite)"
      min_lines: 150
  key_links:
    - from: "home/scripts/setup-credentials.sh"
      to: "gh CLI (auth login / ssh-key add / ssh-key list)"
      via: "shell-out calls in ensure_gh_auth + setup_ssh + ssh_pubkey_registered"
      pattern: "gh (auth|ssh-key)"
    - from: "home/scripts/setup-credentials.sh"
      to: "~/.ssh/personal_ed25519"
      via: "ssh-keygen -t ed25519 -f $SSH_KEY"
      pattern: "personal_ed25519"
---

<objective>
Author the first half of `home/scripts/setup-credentials.sh`: the script skeleton (header banner, constants, usage, argparse, preflight) plus the gh-auth + SSH-keygen-and-register path. This is the foundational half — Plan 1-04b appends the GPG keygen + signingkey write + chezmoi remote rewrite + script-review attestation on top of this scaffolding.

Purpose: Splitting the original Plan 1-04 (≈400 lines bash, 10 functions, 14 subsections) into 1-04a + 1-04b reduces per-task cognitive load below the threshold where execution-time quality degrades. Both plans run in Wave 2 (parallel-eligible with 1-02 and 1-03; sequential within the 1-04 pair — 1-04b appends to the file 1-04a creates). 1-05 (VM verification) depends on BOTH 1-04a and 1-04b.

Output: One executable bash script of approximately 150-180 lines with the header → preflight → ensure_gh_auth → ssh_pubkey_registered → setup_ssh → main-skeleton path complete. The bottom of the file has clearly marked TODO comments showing where Plan 1-04b appends setup_gpg, write_signingkey, rewrite_remote.
</objective>

<execution_context>
@/Users/jteague/.claude/get-shit-done/workflows/execute-plan.md
@/Users/jteague/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/phases/01-credential-plane/1-CONTEXT.md
@.planning/phases/01-credential-plane/1-RESEARCH.md

<interfaces>
Key research findings driving this half of the script (from 1-RESEARCH.md):

1. **gh ssh-key add is NOT idempotent** (cli/cli#5085). Workaround: enumerate registered keys via `gh ssh-key list --json key` + fingerprint-compare against local pubkey BEFORE attempting add.

2. **gh auth status check before gh auth login** — re-running login clobbers existing tokens. Detect auth state first; only run `gh auth login` if not authed or scopes insufficient (need `admin:public_key`, `admin:gpg_key`, `repo`).

3. Recommended SSH key title convention: `<hostname>-personal-<YYYYMMDD>` (per 1-RESEARCH.md Pitfall 10 — makes stale entries identifiable for fleet cleanup).

Recommended exit codes (full set; this plan only uses 1, 2, 3):
- 0 — success (fresh or idempotent re-run)
- 1 — pre-flight failure (gh / gpg / ssh-keygen missing)
- 2 — gh auth login failed / interrupted
- 3 — SSH key generation or registration failed
- 4 — GPG key generation or registration failed [reserved for 1-04b]
- 5 — signingkey write to chezmoi config failed [reserved for 1-04b]
- 6 — chezmoi remote rewrite or smoke test failed [reserved for 1-04b]

**Handoff contract to Plan 1-04b**: At the end of this plan, the script will have:
- Complete header/constants/usage/argparse/preflight blocks
- Complete ensure_gh_auth, ssh_pubkey_registered, setup_ssh function bodies
- A `main()` function whose final lines are clearly marked:
  ```bash
  ensure_gh_auth
  setup_ssh
  # TODO(1-04b): setup_gpg
  # TODO(1-04b): write_signingkey
  # TODO(1-04b): rewrite_remote
  echo "Stage 2 complete. Verify: git commit -S --allow-empty -m verify && git log --show-signature -1"
  ```
  Plan 1-04b replaces the three TODO lines and appends the three new function bodies above main().

<!-- SEC-15 contract (canonical from Plan 1-01 interfaces block): -->
<!-- Three-clause regex: \bbw \b|bitwardenAttachment|\{\{ *bitwarden -->
<!-- This script MAY have one or two design-comment lines mentioning VW per SEC-15's exception list. -->
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Author setup-credentials.sh skeleton + auth/SSH path</name>
  <files>home/scripts/setup-credentials.sh</files>
  <action>
Create `home/scripts/setup-credentials.sh` as an executable bash script (`#!/usr/bin/env bash` shebang, `set -uo pipefail` — NOT `-e`, because we want to handle specific exit-1 cases gracefully).

**Script structure** (in order):

1. **Header banner comment block** (lines 1-30): purpose, two-stage architecture summary, link to `docs/credential-plane.md`, link to `phases/01-credential-plane/1-CONTEXT.md`. State explicitly: "Operator-invoked. NOT a chezmoi run_once_ script. Re-runnable; idempotent by default; rotation via --rotate-* flags."

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

9. **`main()` function — SKELETON** (lines 260-end):
   - Print banner with hostname + date.
   - Call `ensure_gh_auth` then `setup_ssh`.
   - Three TODO marker lines (exact text, so Plan 1-04b can sed/grep them deterministically):
     ```bash
     # TODO(1-04b): setup_gpg
     # TODO(1-04b): write_signingkey
     # TODO(1-04b): rewrite_remote
     ```
   - Final success banner: `echo "Stage 2 complete. Verify: git commit -S --allow-empty -m verify && git log --show-signature -1"`
   - Exit 0.

10. **End of file**: `main "$@"`.

**Critical**: NO references to `bw` / `bitwarden` / `bitwardenAttachment` anywhere in the executable code paths. One or two design-comment lines mentioning VW are permitted per SEC-15 exception list.

**Lint requirement**: script passes `shellcheck -x home/scripts/setup-credentials.sh` with no errors. Allowed warnings only with inline `# shellcheck disable=SCNNNN` and a justifying comment.

After writing, `chmod +x home/scripts/setup-credentials.sh`.

**Verify --help works**: even though setup_gpg/write_signingkey/rewrite_remote are TODOs, the script's argument parser must print usage and exit 0 on `--help` without invoking any TODO path.
  </action>
  <verify>
    <automated>cd /Users/jteague/.local/share/chezmoi && test -x home/scripts/setup-credentials.sh && bash -n home/scripts/setup-credentials.sh && bash home/scripts/setup-credentials.sh --help | grep -E "rotate-ssh" >/dev/null && bash home/scripts/setup-credentials.sh --help | grep -E "rotate-gpg" >/dev/null && bash home/scripts/setup-credentials.sh --help | grep -E "rotate-all" >/dev/null && grep -q "personal_ed25519" home/scripts/setup-credentials.sh && grep -q "gh ssh-key list" home/scripts/setup-credentials.sh && grep -q "TODO(1-04b): setup_gpg" home/scripts/setup-credentials.sh && grep -q "TODO(1-04b): write_signingkey" home/scripts/setup-credentials.sh && grep -q "TODO(1-04b): rewrite_remote" home/scripts/setup-credentials.sh && (command -v shellcheck >/dev/null 2>&1 && shellcheck -x home/scripts/setup-credentials.sh || echo "shellcheck not installed — skipping lint") && ! ls home/.chezmoiscripts/*setup-credentials* 2>/dev/null && ! grep -E "\\bbw \\b|bitwardenAttachment|\\{\\{ *bitwarden" home/scripts/setup-credentials.sh | grep -v "^[[:space:]]*#"</automated>
  </verify>
  <done>Script executable, syntactically valid bash; --help enumerates all three rotation flags without triggering TODO paths; script lives in home/scripts/ NOT home/.chezmoiscripts/; references personal_ed25519 + gh ssh-key list (cli/cli#5085 idempotency); three TODO marker lines present in exact form for Plan 1-04b handoff; shellcheck clean (if installed); SEC-15 three-clause regex returns zero matches in non-comment lines; SEC-11 and SEC-13(presence) gates in quick.sh turn GREEN.</done>
</task>

</tasks>

<verification>
After Task 1:
- `bash home/scripts/setup-credentials.sh --help` enumerates all three rotation flags
- `bash -n home/scripts/setup-credentials.sh` passes syntax check
- Script lives in `home/scripts/` and NOT in `home/.chezmoiscripts/`
- Three `TODO(1-04b):` marker comments present in exact form for Plan 1-04b's append step
- `bash .planning/phases/01-credential-plane/checks/quick.sh` shows SEC-11 PASS and SEC-13(presence) PASS
- SEC-15 three-clause grep clean on non-comment lines
</verification>

<success_criteria>
- SEC-11 GREEN (script present, executable, not in .chezmoiscripts/)
- SEC-12 documented in --help (flag presence; behavior continues in 1-04b for --rotate-gpg)
- SEC-13 (SSH presence + cli/cli#5085 idempotency) implemented
- Plan 1-04b can append on top without re-reading the entire script context
- shellcheck clean (if installed)
- No bw/bitwardenAttachment in executable paths
</success_criteria>

<output>
After completion, create `.planning/phases/01-credential-plane/1-04a-SUMMARY.md` covering: line count, function count (ensure_gh_auth, ssh_pubkey_registered, setup_ssh, usage, main-skeleton), exit codes used (0/1/2/3), Pitfall coverage for this half (Pitfalls 5/6/7 from 1-RESEARCH.md), shellcheck verdict, and explicit handoff to Plan 1-04b naming the three TODO markers it must replace and the three function bodies it must append.
</output>
