---
phase: 1
plan: 05
status: complete
started: 2026-06-28T21:27:03Z
completed: 2026-06-29T04:25:00Z
vm_host: jteague@10.211.55.4
vm_os: macOS 26.5.1 arm64
snapshot: vanilla-fresh-boot-pre-chezmoi (with passwordless sudoers drop-in baked in for this session)
operator: Teague (planner Mac); Reed drove harness over SSH
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

## Recovery Context (this session)

A prior session driving Plan 1-05 crashed mid-Scenario-1 between 16:29 and
18:49 local time on 2026-06-28; transcript was lost (remote-control session
not persisted locally). State on resume: pre-flight artifact committed
(`84baa19`); a single in-flight finding committed (`4703baa` "remove defunct
'kindle' cask" — `brew bundle` was failing on it during the original
Scenario 1 attempt). All Scenarios re-executed from a freshly-restored
snapshot. See `1-SUMMARY.md` for the complete session arc.

---

## Scenario 1: Fresh Stage 1 + Stage 2

**Snapshot UUID:** `vanilla-fresh-boot-pre-chezmoi` (Parallels — UUID not
captured; identified by name. Snapshot includes a one-time
`/etc/sudoers.d/jteague-nopasswd` so Reed could drive `sudo` over SSH
without password prompts — operator-added before this session, will persist
in the snapshot for future verification cycles.)

### Stage 1 — `chezmoi init --apply` (final, post-fixes)

Final command that completed cleanly (after the bug fixes below landed in
`origin/master`):

```bash
ssh jteague@10.211.55.4 'rm -rf ~/.local/share/chezmoi ~/.config/chezmoi ~/bin/chezmoi
  mkdir -p ~/.config/chezmoi
  cat > ~/.config/chezmoi/chezmoi.toml <<EOF
[data]
  personal = true
  name = "James Teague"
  email = "james@teague.dev"
  role = "dev"
  wsl = false
EOF
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply JamesTeague/dotfiles'
```

Pre-write of `chezmoi.toml` is the workaround for the TTY/promptOnce
limitation (Finding #3 below). Result: Homebrew installed, 81 brew bundle
dependencies installed, mas block cleanly skipped (no App Store sign-in on
VM), `chezmoi diff -x externals` empty. Stage 1 GREEN end-to-end.

### Stage 2 — `setup-credentials.sh` (interactive device flow)

Command: `ssh -t jteague@10.211.55.4 'bash ~/scripts/setup-credentials.sh'`

Captured stdout (key excerpts):

```
[auth] Checking GitHub authentication...
[auth] Not authenticated with GitHub.
[auth] Launching gh auth login (device flow).
[auth] A code will be displayed — enter it at: https://github.com/login/device

! First copy your one-time code: 663F-8FB6
Open this URL to continue in your web browser: https://github.com/login/device
✓ Authentication complete.
✓ Logged in as JamesTeague
[ssh] Generating ed25519 key at /Users/jteague/.ssh/personal_ed25519 (title: macos-personal-20260628)...
SHA256:uPifNSFc1VMLMDL1l7EZ388cMNjnbHQHocRYO8oY/ak macos-personal-20260628
[ssh] SSH key registered successfully.
[gpg] Generating EDDSA/Ed25519 GPG key for James Teague <james@teague.dev>...
[gpg] Key generated: 28831AB776AED71C
[gpg] GPG key registered successfully.
[signingkey] Inserted signingkey under [data] section.
[signingkey] Verified: chezmoi data .signingkey = 28831AB776AED71C
[remote] SSH auth confirmed.
[remote] Rewriting chezmoi remote: https://github.com/JamesTeague/dotfiles.git → git@github-personal:JamesTeague/dotfiles.git
Stage 2 complete.
```

Exit 0.

### Post-Stage-2 Verifications

| Check | Command | Expected | Result |
|-------|---------|----------|--------|
| SEC-08 | `chezmoi git -- remote get-url origin` | `git@github-personal:JamesTeague/dotfiles.git` | ✅ **PASS** — `git@github-personal:JamesTeague/dotfiles.git` |
| SEC-09 | `git commit -S --allow-empty -m phase1 && git log --show-signature -1` | "Good signature" | ✅ **PASS** — `gpg: Good signature from "James Teague <james@teague.dev>"` (EDDSA key `1A9351CD3D9B0557268F39B528831AB776AED71C`) |
| SEC-10 | `ssh -T git@github-personal` | "Hi ...! You've successfully authenticated..." | ✅ **PASS** — `Hi JamesTeague! You've successfully authenticated, but GitHub does not provide shell access.` (rc=1 is GitHub's standard exit for no-shell — banner is the gate) |
| SEC-13 | `ssh-keygen -lf ~/.ssh/personal_ed25519.pub` | ED25519 | ✅ **PASS** — `256 SHA256:uPifNSFc1VMLMDL1l7EZ388cMNjnbHQHocRYO8oY/ak macos-personal-20260628 (ED25519)` |
| SEC-14 | `chezmoi data \| jq -r .signingkey` matches GPG keyring | MATCH | ✅ **PASS** — `28831AB776AED71C` matches `sec ed25519/28831AB776AED71C` |
| gitconfig | `grep -E "signingkey\|gpgsign" ~/.gitconfig.local` | both present | ✅ **PASS** — `signingkey = 28831AB776AED71C` + `gpgsign = true` |

---

## Scenario 2: Idempotency re-run

Initial run against the original (broken) script regenerated the GPG key
because the idempotency check used `gh gpg-key list --json` which is not a
supported flag (TSV-only). See Finding #7 below — fixed in commit `e0ec7b9`.

### Re-run output (post-fix, clean baseline)

After fix landed and Scenario-2 pollution was cleaned up (deleted dup
`92168368EB6C0C68` from GitHub + local, restored chezmoi signingkey to
`28831AB776AED71C`):

```
[auth] Already authenticated with required scopes — skipping login.
[ssh] Setting up personal SSH key...
[ssh] Key already exists at /Users/jteague/.ssh/personal_ed25519 — checking registration.
[skip] SSH key already registered with GitHub.
[gpg] Setting up personal GPG key...
[skip] GPG key 28831AB776AED71C already exists locally and is registered with GitHub.
[signingkey] Writing signingkey 28831AB776AED71C to chezmoi config...
[signingkey] Updated existing signingkey line.
[signingkey] Verified: chezmoi data .signingkey = 28831AB776AED71C
[signingkey] gitconfig.local re-rendered.
[remote] SSH auth confirmed.
[skip] chezmoi remote already set to git@github-personal:JamesTeague/dotfiles.git
Stage 2 complete.
```

Exit 0.

### Key count before/after

| Metric | Value |
|--------|-------|
| SSH key count before | 4 (3 historical + `macos-personal-20260628`) |
| SSH key count after | 4 — **unchanged** ✓ |
| GPG key count before | 4 (`28831AB776AED71C` + 3 historical) |
| GPG key count after | 4 — **unchanged** ✓ |

**Result: PASS** — true no-op re-run; no new keys generated or registered.

---

## Scenario 3: Rotation (PARTIAL — full fresh-snapshot rerun deferred)

**Caveat:** Full Scenario 3 per plan (restore snapshot → Stage 1 → Stage 2 →
`--rotate-all`) was not executed. The `--rotate-all` mechanics were tested
on the current (un-restored) VM as a code-path validation only. Full
fresh-snapshot rerun is **deferred to a follow-up session** — see Open
Follow-ups below.

Initial `--rotate-all` run was a partial pass (SSH rotated, GPG was a
no-op via the same idempotency path). Fixed in commit `6b7c518`.

### --rotate-all run (post-fix)

```
[ssh] --rotate-ssh: old fingerprint (log for manual GitHub cleanup):
256 SHA256:hkg+vhqKmwJgHJUEC/BdzQTeOu1vqt2jthM5cAgCuUM macos-personal-20260628 (ED25519)
[ssh] Removing old key files: /Users/jteague/.ssh/personal_ed25519  /Users/jteague/.ssh/personal_ed25519.pub
[ssh] Generating ed25519 key at /Users/jteague/.ssh/personal_ed25519 (title: macos-personal-20260628)...
SHA256:WC8DaGTBgvQUWODn5BSj1im56K7k6Sh1JqroBwS2Gok macos-personal-20260628
[ssh] SSH key registered successfully.
[gpg] --rotate-gpg: logging existing key IDs for manual GitHub cleanup:
  old key ID: 28831AB776AED71C (fpr: 1A9351CD3D9B0557268F39B528831AB776AED71C)
[gpg] Generating EDDSA/Ed25519 GPG key for James Teague <james@teague.dev>...
[gpg] Key generated: DE15BBB28C086F4F
[gpg] GPG key registered successfully.
[signingkey] Updated existing signingkey line.
[signingkey] Verified: chezmoi data .signingkey = DE15BBB28C086F4F
[remote] SSH auth confirmed.
[skip] chezmoi remote already set to git@github-personal:JamesTeague/dotfiles.git
Stage 2 complete.
```

Exit 0.

### Rotation verification

| Check | Before rotation | After rotation | Match? |
|-------|-----------------|----------------|--------|
| SSH fingerprint | `SHA256:hkg+vhqKmwJgHJUEC/BdzQTeOu1vqt2jthM5cAgCuUM` | `SHA256:WC8DaGTBgvQUWODn5BSj1im56K7k6Sh1JqroBwS2Gok` | ✅ **CHANGED** |
| GPG key ID | `28831AB776AED71C` | `DE15BBB28C086F4F` | ✅ **CHANGED** |
| chezmoi signingkey | `28831AB776AED71C` | `DE15BBB28C086F4F` | ✅ **matches new GPG key** |
| Old key IDs logged | n/a | `28831AB776AED71C (fpr: 1A9351CD...)` | ✅ **printed for manual cleanup** |

**Result: PARTIAL PASS** — rotation mechanics verified; full fresh-snapshot
rerun deferred.

---

## Manual Verifications

### Device-flow UX (Scenario 1)

| Question | Operator notes |
|----------|---------------|
| Did script display clear device-flow URL + code? | ✅ Yes — `! First copy your one-time code: 663F-8FB6` + URL on next line, both unambiguous. |
| Did device-flow code entry succeed on first try? | ✅ Yes. |
| Any UX friction observed? | Minor: the `Pseudo-terminal will not be allocated` warning from `ssh -t` over a pipe is noise; functional. `~/.zshenv` references `~/.cargo/env` which doesn't exist on the VM (rustup not part of bootstrap) — emits `no such file or directory` on every ssh session. Cosmetic, but worth fixing. |

### Stale-key cleanup decision (Scenario 3)

| Question | Operator notes |
|----------|---------------|
| Old SSH fingerprint clearly logged? | ✅ Yes — `[ssh] --rotate-ssh: old fingerprint (log for manual GitHub cleanup): ...` |
| Old GPG key ID clearly logged? | ✅ Yes — `old key ID: 28831AB776AED71C (fpr: 1A9351CD...)` (post-fix, with fingerprint for `gh gpg-key delete`) |
| Cleanup procedure (`gh ssh-key delete`) straightforward? | ✅ Yes — `gh gpg-key delete <key-id-text>` works (not numeric id; confirmed during cleanup of Scenario-2 pollution). Same pattern for SSH: `gh ssh-key delete <numeric-id>` (uses numeric id, not the title; difference between SSH and GPG delete APIs worth documenting). |
| Did operator delete stale keys from GitHub? | Pollution from Scenario-2 dup (`92168368EB6C0C68`) deleted during cleanup. Rotation old key (`28831AB776AED71C`) intentionally LEFT on GitHub as test-residue — operator may clean up via `gh gpg-key delete 28831AB776AED71C` when comfortable. |

---

## Requirement ID -> Result Map

| Req ID | Description | Scenario | Result |
|--------|-------------|----------|--------|
| SEC-02 | bitwarden-cli pin documented + present | pre-flight | **PASS** |
| SEC-05 | generate-gpg-key.sh deleted + gitconfig rewritten | pre-flight | **PASS** |
| SEC-07 | SSH config template with github-personal | pre-flight | **PASS** |
| SEC-08 | chezmoi remote = git@github-personal:JamesTeague/dotfiles.git | 1 | **PASS** |
| SEC-09 | `git commit -S` verified Good signature | 1 | **PASS** |
| SEC-10 | `ssh -T git@github-personal` welcome banner | 1 | **PASS** |
| SEC-11 | setup-credentials.sh exists, executable, NOT in .chezmoiscripts/ | pre-flight | **PASS** |
| SEC-12 | Rotation generates new keys + logs old for cleanup | 3 (partial) | **PASS** (mechanics verified post-fix; full fresh-snapshot rerun deferred) |
| SEC-13 | personal_ed25519 ED25519 | 1 | **PASS** |
| SEC-14 | chezmoi data .signingkey matches GPG keyring | 1 | **PASS** |
| SEC-15 | Structural VW-independence | pre-flight | **PASS** |
| SEC-16 | End-to-end VM + idempotency no-op | 1+2 | **PASS** |

**Phase 1 exit gate: ALL 12 ACTIVE REQUIREMENTS GREEN.**

---

## Findings (Phase 1 design gaps surfaced by VM verification)

All findings were surfaced because Mac personal + Mac work could not be
fresh-install targets — see 1-CONTEXT.md. Eight gaps in total; six fixed in
source during this session, two documented for follow-up.

### Findings fixed in source (committed to master)

| # | Finding | Commit | Notes |
|---|---------|--------|-------|
| 1 | `kindle` cask defunct in Homebrew (brew bundle fails entire fetch) | `4703baa` | Pre-existing from prior session; first thing surfaced. Amazon Kindle is web-app sufficient. |
| 4 | Third-party taps (`jesseduffield/lazydocker`, `nikitabobko/tap`) not auto-trusted; Homebrew 4.7+ refuses non-interactive load | `064ba57` | `brew trust --tap` pre-call added in `run_onchange_before_02-install-packages.sh.tmpl`. `lazygit` had been grandfathered on the VM somehow; trusting unconditionally is safer. |
| 5 | `gh` formula missing from `packages.yaml` despite `setup-credentials.sh` requiring it (script comment line 14 even claims Stage 1 installs it) | `841f685` | Added to `roles.dev.core.brews` between git and grep. |
| 6 | `mas install` hangs indefinitely when App Store is not signed in (no auth prompt, just locked) | `2e2eb60` | Guard via `defaults read MobileMeAccounts Accounts \| grep -q AccountID` at the top of `run_onchange_before_03-mas.sh.tmpl`; clean skip with operator-facing message. |
| 7 | `setup-credentials.sh` used `gh ssh-key list --json` / `gh gpg-key list --json`, but neither subcommand supports `--json` (TSV-only). Silent `2>/dev/null` swallowed the error → idempotency check always failed → script re-registered SSH (server-side dedup masked) and **regenerated** GPG every re-run. | `e0ec7b9` | Switched both to `gh api user/keys` / `gh api user/gpg_keys` which support `--jq`. |
| 8 | `--rotate-gpg` printed old key ID but local delete silently failed (modern GPG refuses to delete secret keys via short-id even with `--batch --yes`). Idempotency-skip then no-op'd the regeneration. | `6b7c518` | Extract long fingerprint via colon-format `fpr:` lines; two-pass delete (`--delete-secret-keys` then `--delete-keys`) using fingerprint. Old-id log now includes the fingerprint too. |

### Findings documented for follow-up (no source fix this session)

| # | Finding | Owner | Notes |
|---|---------|-------|-------|
| 2 | Vanilla macOS has no Command Line Tools; `git` is a stub that triggers the GUI install prompt. `chezmoi init` therefore fails (`chezmoi: git: exit status 1`) on a truly fresh machine. | new "Stage 0" doc work | Headless install via `softwareupdate -i "Command Line Tools for Xcode <version>"` works; requires the `/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress` touch-file trick. Should be a documented pre-step in `docs/credential-plane.md` and ideally a separate `bootstrap-clt.sh` script. |
| 3 | `chezmoi.toml.tmpl` uses `promptBoolOnce/promptStringOnce/promptChoiceOnce` for `personal`/`name`/`email`/`role`. SSH without `-t` has no TTY → init fails before any template eval. `--promptBool` flags do **not** populate `promptBoolOnce` (separate caches). | template revision OR docs | Workaround used this session: pre-write `~/.config/chezmoi/chezmoi.toml` with `[data]` block so the `Once` functions read existing values silently. For real-world fresh installs, operators sit at the machine and answer prompts (the `Once` design is correct UX). The Stage 1 command in the plan should be updated to either use `ssh -t` + manual prompt-answer OR include the pre-write workaround for headless verification. |

---

## Operator Notes

- The `kindle` finding (#1) was pre-existing — surfaced during the prior
  (crashed) session and already committed. Confirmed during this session
  that the snapshot's brew bundle no longer fails on it.
- The CLT install (#2) used the `softwareupdate -i "Command Line Tools for
  Xcode 26.6-26.6"` recipe with the `/tmp/.com.apple.dt...in-progress`
  touch-file. Took ~5 min on the VM. Worth scripting as `bootstrap-clt.sh`.
- The mas guard (#6) currently exits 0 with a one-line message — chezmoi
  apply continues past it cleanly, which is the desired behavior.
- Scenario 2's "broken idempotency" run polluted GitHub with a duplicate
  GPG key (`92168368EB6C0C68`) that was cleaned up during recovery. Worth
  noting in docs: if anyone hits a script bug mid-rotation, the pollution
  cleanup pattern is `gh gpg-key delete <key-id-text>` + local
  `gpg --batch --yes --delete-secret-keys <fingerprint>` + `sed` the
  chezmoi.toml signingkey back.
- The rotation old-key residue (`28831AB776AED71C`) is intentionally left
  on GitHub for now — operator can delete via
  `gh gpg-key delete 28831AB776AED71C` when ready.

## Open Follow-ups (next session)

1. **Full Scenario 3 rerun against a freshly-restored snapshot.** The
   current session validated rotation MECHANICS but did not validate the
   full chain (restore → Stage 1 → Stage 2 → `--rotate-all`) end-to-end
   from a clean machine. Suggested approach: re-snapshot the current VM
   state (which already has all 6 source fixes baked into the pulled tree),
   so future Scenario 3 reruns skip the brew install phase.
2. **Stage 0 CLT bootstrap docs/script** (Finding #2). Add
   `docs/credential-plane.md` "Stage 0: Command Line Tools" section.
   Optional: `home/scripts/bootstrap-clt.sh` for a one-line operator
   command.
3. **Stage 1 init-command revision** (Finding #3). Update the plan's
   Stage 1 command and `docs/credential-plane.md` to either use `ssh -t`
   for headless verification + manual prompt-answer, or the pre-write
   workaround.
4. **Cosmetic: `~/.zshenv` references `~/.cargo/env`** which doesn't exist
   pre-rust-install. Causes a `no such file or directory` warning on every
   ssh session. Guard with `[ -f ~/.cargo/env ] && . ~/.cargo/env`.
5. **Document the gh delete-id asymmetry**: `gh ssh-key delete` takes the
   GitHub numeric id; `gh gpg-key delete` takes the key-id text. Worth a
   one-liner in `docs/credential-plane.md` cleanup section.

---

*Last updated: 2026-06-29 (Reed) — Scenarios 1 + 2 GREEN, Scenario 3 partial
GREEN (mechanics verified, full rerun deferred); all 12 active SEC
requirements PASS; 6 source fixes committed; 2 design-gap follow-ups
documented.*
