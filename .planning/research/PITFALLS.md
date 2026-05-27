# Pitfalls Research

**Domain:** chezmoi modernization — multi-OS fleet refactor + Windows-native extension + VaultWarden integration + WSL greenfield
**Researched:** 2026-05-27
**Confidence:** HIGH for chezmoi mechanics (Context7-grade docs cited) / MEDIUM for VaultWarden quirks (recent issues, version-bound) / HIGH for WSL operational pitfalls (Microsoft docs + known issues)

## Critical Pitfalls

### Pitfall 1: `.chezmoi.toml.tmpl` prompts only fire on `chezmoi init`, never on `chezmoi apply` — refactor leaves existing machines in a half-state

**What goes wrong:**
You restructure `.chezmoi.toml.tmpl` to introduce `role` + `personal` + `os` + `wsl` keys. On the next `chezmoi update` / `apply` on an existing machine (Mac personal, Mac work), the prompts DO NOT run. Templates that reference `.role` evaluate `<no value>` and silently emit garbage, OR fail loud with "map has no entry for key". The persisted `~/.config/chezmoi/chezmoi.toml` on each existing machine still has only the old `personal` boolean.

**Why it happens:**
chezmoi's design: `.chezmoi.toml.tmpl` runs at `init` time and writes a static `chezmoi.toml` to `~/.config/chezmoi/`. From then on, that file is authoritative for that machine. `apply` does not re-prompt. This is correct and intentional behavior — but it surprises people doing a taxonomy migration who expect "the template re-runs."

**How to avoid:**
Three-pronged strategy, all required:
1. Use `promptStringOnce`/`promptBoolOnce` (not bare `promptString`) for every new key. These check existing data first and only prompt if absent. This means `chezmoi init --apply` re-run on an existing machine only prompts for the NEW keys.
2. Provide a documented one-liner per existing machine: `chezmoi init --apply` (no source URL) to re-trigger the template against current data and capture new prompts.
3. For the `personal` → `role + personal` split, derive defaults from existing data inside the template: `{{- $role := promptStringOnce . "role" "role (dev/gaming/lite)" "dev" -}}` and seed `personal` from the prior value if present. Never delete the old key on an existing machine — leave it sitting and just stop reading it.

**Warning signs:**
- `chezmoi diff` on an existing machine shows huge unexpected diffs (templates rendering with empty role)
- Error: `template: ...: executing ... at <.role>: map has no entry for key "role"`
- A machine's `~/.config/chezmoi/chezmoi.toml` has not gained the new keys after pulling the refactor

**Phase to address:** Phase 0.5 / 0 — the taxonomy refactor itself. The `.chezmoi.toml.tmpl` is the entire game.

---

### Pitfall 2: `chezmoi diff` does NOT catch script side-effects, only file diffs

**What goes wrong:**
You use `chezmoi diff` as your "is this safe?" gate on the Mac personal machine before applying the refactored branch. Diff shows clean. You apply. A `run_onchange_install-packages.sh.tmpl` whose template output changed (because role/os now resolve differently) runs `brew install` or `apt install` for a wildly different package set than intended, OR a `run_once_` script that was already run with the old hash now re-runs because the rendered content changed.

**Why it happens:**
`chezmoi diff` prints script contents that would run (per docs), but it cannot show the *effect* of those scripts on the system. It also doesn't catch:
- Permission changes hidden by Windows lacking `private_`/`executable_` semantics
- External source refreshes via `.chezmoiexternal.toml`
- run_onchange hash invalidation (the script's rendered content changed → it re-runs)

**How to avoid:**
- ALWAYS pair `chezmoi diff` with `chezmoi apply --dry-run --verbose` — shows scripts that would run with their full text
- Set `diff.scripts = true` in chezmoi config (or accept default that shows them; verify your config) so diff doesn't hide script text
- For high-risk migrations, run `chezmoi execute-template` against representative templates to inspect rendered output before any apply
- For scripts that install packages, add a defensive `echo "DRY: would install $pkg"` mode behind a `--dry` env var the script reads, and exercise it before real run
- Take a snapshot/backup of the machine state before the cutover apply (Time Machine on Mac, Restic snapshot, or at minimum `chezmoi archive` of current applied state)

**Warning signs:**
- Diff is suspiciously clean for a large refactor — re-check that templates are actually resolving (`chezmoi data` shows full data tree)
- A `run_onchange_` script you didn't expect to run shows up in `chezmoi apply --dry-run`

**Phase to address:** Phase 0 — establish the validation discipline before the first cutover. Document it in PROJECT.md as the per-machine migration ritual.

---

### Pitfall 3: VaultWarden + Bitwarden CLI version mismatch silently breaks login at the worst time

**What goes wrong:**
You bootstrap a fresh Lonestar machine. `bw login` fails with `User Decryption Options are required for client initialization`. The CLI is too new for your self-hosted VaultWarden, OR VaultWarden version is fine but the CLI changed its expected response shape. Your day-1 onboarding stops dead.

**Why it happens:**
This is a real recurring issue. Bitwarden CLI 2025.12.0 broke against VaultWarden < 1.36.x because the CLI started requiring KDF/decryption fields that older VaultWarden versions don't return during API key auth. VaultWarden is a community reimplementation; it lags Bitwarden Cloud on API contract changes by weeks-to-months. winget/brew/apt happily install the LATEST `bw`, which is often ahead of your server.

**How to avoid:**
- Pin a known-good `bw` CLI version in `packages.yaml`, do not float to latest. Update the pin only after verifying against your live VaultWarden version.
- Document the working CLI/server version pair in PROJECT.md (or a dedicated `BITWARDEN-COMPAT.md` in repo).
- Keep VaultWarden upgraded on a steady cadence on the Unraid box, not "whenever I remember." Stale server = future compatibility cliff.
- Bootstrap kit fallback (already planned as a deferred sub-project) needs to cover *exactly* this scenario: age-encrypted recovery essentials + an offline-installable known-good `bw` binary.

**Warning signs:**
- `bw login` error mentioning `User Decryption Options`, `userDecryptionOptions`, or `kdfConfig`
- `bw sync` succeeds but `bw get item` returns malformed data
- Web vault works, CLI doesn't (or vice versa) → API mismatch

**Phase to address:** Phase 2 (VaultWarden integration) — pin the CLI version, document the working pair. Phase 0 (bootstrap kit) — make sure the recovery path doesn't depend on the breaking flow.

---

### Pitfall 4: Cross-OS templates emit wrong line endings on Windows

**What goes wrong:**
You ship the same `dot_gitconfig.tmpl` to Mac and Windows. On Windows it lands with LF endings. Some Windows tools (older Git for Windows, certain editors, legacy `.bat` callers) silently misbehave. Worse: `.ps1.tmpl` scripts emitted with LF can fail to parse in legacy Windows PowerShell 5.x, throwing cryptic syntax errors.

**Why it happens:**
chezmoi's template functions default to LF output. The directive that controls this has had a documentation/code drift bug: docs sometimes show `chezmoi:template:line-endings=native` (plural) while the code expects `chezmoi:template:line-ending=native` (singular). Easy to copy-paste the wrong one and assume it's working.

**How to avoid:**
- For files that are platform-conditional, add the directive at the top: `{{- /* chezmoi:template:line-ending=native */ -}}` — verify singular form by testing on Windows and checking the emitted file (`Get-Content -Raw file | Format-Hex` or `file file.ps1`)
- For PowerShell scripts specifically: explicitly set the interpreter to `pwsh` (PowerShell Core) in `.chezmoi.toml.tmpl` via `[interpreters.ps1]` — Core handles UTF-8 + LF gracefully where 5.x does not.
- Save the source `.tmpl` files in the repo with LF (let `.gitattributes` enforce `*.tmpl text eol=lf`); rely on the line-ending directive for the *rendered* output, not on the source file's endings.
- Add a one-time post-apply check on Windows: dump the line ending of one rendered file as part of `run_once_after_verify-windows.ps1.tmpl`.

**Warning signs:**
- PowerShell errors like "Unexpected token '...' in expression or statement" on scripts that look syntactically fine
- Git for Windows complaining about line endings in committed-from-chezmoi config files
- WezTerm or other configs behaving differently than on Mac despite identical rendered content

**Phase to address:** Phase 3 (Windows extension) — add the directive convention. Phase 0 — establish `.gitattributes` for `*.tmpl`.

---

### Pitfall 5: WSL `interop.appendWindowsPath = false` quietly breaks `code .`, `clip.exe`, and other expected affordances

**What goes wrong:**
You set `[interop] appendWindowsPath = false` in `/etc/wsl.conf` for the gaming-rig WSL (clean PATH discipline). After `wsl --shutdown` and restart, `code .` from WSL stops launching VS Code on Windows. `clip.exe` for pipe-to-clipboard is gone. `explorer.exe .` doesn't open. The greenfield WSL feels broken in ways that don't show up in any test.

**Why it happens:**
`appendWindowsPath=false` is a correct choice for PATH hygiene (Windows PATH entries with spaces shred WSL's `$PATH`), but it removes *all* Windows tool access via PATH inheritance. The Windows-side `.exe`s that are commonly invoked from WSL (`code`, `clip`, `explorer`, `winget`, `wslview`) all rely on PATH inheritance unless explicitly handled.

**How to avoid:**
- If choosing `appendWindowsPath=false`: explicitly add back only the tools you actually use. In `.zshrc` (or wherever shell PATH is set), prepend a narrowly-scoped list:
  ```bash
  for win_tool_dir in "/mnt/c/Users/$USER/AppData/Local/Programs/Microsoft VS Code/bin" \
                       "/mnt/c/Windows/System32"; do
    [ -d "$win_tool_dir" ] && PATH="$PATH:$win_tool_dir"
  done
  ```
- Alternative: leave `appendWindowsPath=true` (default) and accept the PATH bloat — for a dev WSL, the cost is usually worth the affordance.
- The setting lives in per-distro `/etc/wsl.conf` under `[interop]`, NOT in `%USERPROFILE%\.wslconfig` (global). Confusing these locations is itself a common error.
- After any wsl.conf change: `wsl --shutdown` from PowerShell, then re-enter WSL. Without shutdown, changes don't apply.

**Warning signs:**
- `code .` from WSL silently does nothing or `command not found`
- `wsl --shutdown` was not run after editing wsl.conf — settings appear ignored
- `Unknown key 'interop.appendWindowsPath'` (known bug on some WSL versions; means upgrade WSL)

**Phase to address:** Phase 4 (WSL greenfield) — make the appendWindowsPath choice explicit, document the tradeoffs, and if false, ship the narrow re-add list in the WSL `.zshrc.tmpl`.

---

### Pitfall 6: WSL `/mnt/c` file permissions break SSH/GPG keys without `metadata` mount option

**What goes wrong:**
You ship SSH or GPG private keys into the WSL via chezmoi, but accidentally land them under `/mnt/c/Users/...` (e.g., because you symlinked or pointed `$HOME` there). SSH refuses to use them: `UNPROTECTED PRIVATE KEY FILE`. You `chmod 600`. Permissions don't stick — they revert. You think chezmoi is broken.

**Why it happens:**
DrvFs (the `/mnt/c` filesystem) does not persist Unix-style permissions unless `metadata` is set in the automount options. Without metadata, every file appears as `0777` (or whatever umask says) and `chmod` is a no-op. SSH and GPG strictly require `0600` on private keys and will refuse otherwise.

**How to avoid:**
- Keys go in WSL's native filesystem (`~/.ssh/`, `~/.gnupg/`) — never under `/mnt/c/`. This is the right answer 95% of the time.
- If you MUST cross the boundary (e.g., sharing keys with Windows OpenSSH agent), set automount options in `/etc/wsl.conf`:
  ```
  [automount]
  enabled = true
  options = "metadata,uid=1000,gid=1000,umask=22,fmask=11"
  ```
  Then `wsl --shutdown` and re-enter. `chmod` now persists.
- Three different ssh-agent worlds exist (Windows OpenSSH service, Gpg4win's gpg-agent, WSL's ssh-agent). Pick ONE per machine and route the others to it. Mixing them creates baffling "key not found" loops. For a Windows + WSL dev rig: gpg-agent on Windows as the canonical agent, with WSL routing `SSH_AUTH_SOCK` to the Gpg4win socket via `wsl-ssh-pageant` or similar, is the documented pattern.

**Warning signs:**
- `UNPROTECTED PRIVATE KEY FILE` from `ssh` despite `chmod 600`
- `gpg: WARNING: unsafe permissions on homedir`
- `ssh-add` succeeds in one shell, key not found in another (different agent backends)

**Phase to address:** Phase 4 (WSL) — `/etc/wsl.conf` template includes the automount metadata block. Phase 2 (SSH/GPG bootstrap) — document the three-agents-pick-one rule.

---

### Pitfall 7: PowerShell execution policy + script signing blocks first `chezmoi apply` on a fresh Windows machine

**What goes wrong:**
On a fresh Windows install (gaming rig or spiral index), you `chezmoi init --apply`. chezmoi tries to run a `run_once_install-winget-packages.ps1` script. Default execution policy is `Restricted` (client) or `RemoteSigned` (server). The script is unsigned and not from an allowed source. PowerShell refuses. chezmoi reports the script failed. Apply aborts in a half-state.

**Why it happens:**
Windows PowerShell 5.x defaults to Restricted on clients. Even PowerShell Core (pwsh) inherits the policy. Scripts written to a temp file by chezmoi (so the OS can execute them) appear "downloaded" to PowerShell's heuristics in some configurations.

**How to avoid:**
- Configure chezmoi to invoke PowerShell with `-ExecutionPolicy Bypass` for the script invocation. In `.chezmoi.toml.tmpl` (Windows section):
  ```toml
  [interpreters.ps1]
  command = "pwsh"
  args = ["-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
  ```
  (Verify exact arg form against current chezmoi docs — the interpreters reference page is authoritative.)
- Alternative (broader-stroke, less surgical): set CurrentUser scope execution policy to RemoteSigned as a one-time bootstrap step BEFORE first `chezmoi apply`. Document this in the Windows onboarding README as a manual prerequisite.
- Prefer `pwsh` (PowerShell Core / 7+) over Windows PowerShell 5.x: better UTF-8, better cross-platform behavior, fewer parsing gotchas. Ensure `pwsh` is installed before chezmoi runs — bootstrap script that installs pwsh first, then re-launches chezmoi apply, is the clean pattern.

**Warning signs:**
- `cannot be loaded because running scripts is disabled on this system` from PowerShell during apply
- `UnauthorizedAccess` errors in chezmoi log
- Scripts run from PowerShell prompt directly but fail when invoked by chezmoi

**Phase to address:** Phase 3 (Windows extension) — interpreter config in `.chezmoi.toml.tmpl`. The "install pwsh first" bootstrap is a Phase 3 prerequisite.

---

### Pitfall 8: winget package installs from chezmoi script silently swallow UAC failures

**What goes wrong:**
A `run_once_install-winget-packages.ps1.tmpl` loops through winget installs. Some packages require elevation, some don't. From a non-elevated chezmoi context, UAC prompts appear (possibly in the background and missed entirely per known winget-cli bug #5591 / #3335). User dismisses or misses prompt. winget reports the install failed. The PowerShell script's loop continues without checking exit codes. chezmoi sees the script exited 0 (because it didn't `exit 1` on failure). Marks success. You think you have software you don't have.

**Why it happens:**
- winget UAC prompts opened by non-elevated callers can appear minimized/in-background (known bug)
- winget's exit codes are inconsistent across versions
- Naive loops `winget install $pkg` without per-install error handling lose all the signal

**How to avoid:**
- Run the package-install script from an elevated context. Three options:
  1. Have the bootstrap doc instruct user to launch the initial `chezmoi apply` from an elevated terminal (cleanest for first run)
  2. Self-elevate inside the script: detect non-elevated context, relaunch self with `Start-Process -Verb RunAs`. Adds complexity but works for ongoing applies.
  3. Use chezmoi's per-script elevation hooks (check current docs for `run_onchange_before_` patterns)
- Check every `winget install` exit code; collect failures; exit script non-zero if any failed (so chezmoi flags it).
- Prefer winget's `--accept-source-agreements --accept-package-agreements --silent` flags for unattended runs.
- For packages with `elevationProhibited` (rare), they MUST run non-elevated — script must handle the mixed case.

**Warning signs:**
- Apply reports success but a package isn't installed
- UAC prompt taskbar-flashes without coming to foreground
- Winget script's stdout is missing expected `Successfully installed` lines

**Phase to address:** Phase 3 (Windows packages) — design the install script with explicit error handling and document elevation expectation in the bootstrap README.

---

### Pitfall 9: Renaming template variables (`personal` references) — silent rendering with empty values

**What goes wrong:**
Mid-refactor, you rename `.personal` to `.flags.personal` (or split it) in some templates but miss others. Go templates render missing keys as empty string by default (`<no value>` is the string). A `.chezmoiignore` rule `{{ if not .personal }}work-stuff{{ end }}` now evaluates `if not ""` which is `if true` — and the gating inverts on machines that haven't migrated. Work files appear on personal machines or vice versa.

**Why it happens:**
- Go template missing-key behavior is `<no value>` for `.missing.key`, but `not ""` is `true`, `not "<no value>"` is also `true` — the boolean coercion is dangerous
- chezmoi doesn't error by default on missing keys in templates (unless you set `missingkey=error` via `--debug` or config)
- chezmoi data keys are lowercased on the way in (known behavior) — casing changes silently break references

**How to avoid:**
- Before the refactor, grep for ALL references to old variables: `grep -rn 'personal' home/` — keep the list, check every one
- Use `hasKey` defensively in templates: `{{ if and (hasKey . "personal") .personal }}` — fails fast if the key is missing
- Set template strictness during dev: run `chezmoi execute-template --init` against fixture data and verify no `<no value>` appears in critical files
- Use `chezmoi data` to inspect the actual resolved data tree on each machine — confirms what the templates will see
- All keys lowercase always. Never use camelCase or PascalCase in chezmoi data (it'll get lowercased silently and your `.Personal` reference renders empty).

**Warning signs:**
- `chezmoi data` shows different shape than expected
- `<no value>` appears in any rendered file (use `chezmoi apply --dry-run --verbose | grep -i 'no value'`)
- `.chezmoiignore` is gating the wrong files (work files on personal machine, etc.)

**Phase to address:** Phase 0.5 / 0 — the taxonomy refactor. Pre-flight grep + `chezmoi execute-template` pass on fixture data BEFORE any apply.

---

### Pitfall 10: VaultWarden unreachable during `chezmoi apply` — fail-closed bricks routine operations

**What goes wrong:**
Cloudflare tunnel hiccups (cloudflared container restart, certificate edge case, ISP routing blip, Unraid box rebooting). `chezmoi apply` reaches a `{{ bitwarden ... }}` template call. The `bw` CLI hangs or errors. The apply fails. Any routine update on any machine is now blocked on infra that lives in your closet.

**Why it happens:**
chezmoi's `bitwarden` template function calls out to `bw` at template-evaluation time. If the server is unreachable, `bw sync` or `bw get` fails. Templates fail. Apply aborts. There's no inherent caching across `chezmoi apply` invocations of secret material (template-time caching exists within a single apply, per docs, but not across).

**How to avoid:**
- Bootstrap kit fallback (already planned): age-encrypted local copy of the critical secrets, behind a template-time fallback: `{{ if (env "BW_SESSION") }}{{ bitwarden ... }}{{ else }}{{ include "bootstrap-kit/foo.age" | decrypt }}{{ end }}` (pseudo — verify actual chezmoi decrypt template function).
- For non-bootstrap-critical secrets (i.e., things that change rarely), consider rendering them once into a templated-but-not-secret-bearing file and committing the rendered output. Trade vault dependency for marginally less freshness. Acceptable for things like a public SSH key, not for tokens.
- Cache `bw sync` results outside chezmoi: a wrapper script that does `bw sync` if last sync was > N minutes, else skips. Reduces server hits and gives a brief offline tolerance window.
- Monitor the Cloudflare tunnel + VaultWarden uptime actively (Uptime Kuma or similar on Unraid). You want to know it's down BEFORE you try to onboard a machine.

**Warning signs:**
- `chezmoi apply` hangs at a known bitwarden-call template
- `bw sync` returns network errors
- New machine onboarding stalls on `bw login`

**Phase to address:** Phase 2 (VaultWarden integration) — implement the fallback pattern from the start, don't add it later. Bootstrap kit (Phase 0 or standalone) — must exist before anyone is dependent on the vault for daily work.

---

## Moderate Pitfalls

### Pitfall 11: `chezmoi state` boltdb is per-machine and not migrated by the refactor

`run_once_` and `run_onchange_` scripts track state in `~/.config/chezmoi/chezmoistate.boltdb` (per-machine). The refactor changes script *names* and *rendered content* → hash changes → run_once scripts you thought were "done" re-run on every existing machine after the cutover. Sometimes this is fine (re-installing winget packages is idempotent). Sometimes it isn't (a `generate-gpg-key.sh` that was supposed to be retired re-fires and generates a NEW key — disaster).

**Prevention:** Audit every `run_once_` / `run_onchange_` script BEFORE cutover. Anything destructive or one-shot-by-nature: rename + delete the old version + verify the new version's idempotency. For the gpg key generator specifically (already flagged for retirement in Phase 0): delete it cleanly, don't just rename it. If you need to force-skip a script post-cutover on a specific machine: `chezmoi state delete-bucket --bucket=scriptState` resets all script state on that machine (nuke-from-orbit), or use `chezmoi state` subcommands to delete specific entries.

**Phase to address:** Phase 0 — audit scripts as part of the refactor; document any that need state surgery on existing machines.

---

### Pitfall 12: `dot_` prefix and other special prefixes on Windows file names

The `dot_X` → `.X` mapping works the same on Windows (chezmoi handles the rename uniformly). BUT some Windows tools live at non-dot paths (`%APPDATA%\Elgato\StreamDeck\` not `~/.streamdeck/`), and chezmoi's destination dir defaults to `%USERPROFILE%`. Files for AppData need either:
- A symlink template directed at the AppData location, OR
- A script that copies/moves to the right place, OR
- Setting destination dir differently per file (complex)

**Prevention:** For Windows app configs that live outside `%USERPROFILE%`, use a `symlink_` source type pointing at the AppData location, OR an explicit `run_onchange_` script that places the file. Don't try to fight chezmoi's destination-dir model. Document each cross-location placement in the source tree near the file.

**Phase to address:** Phase 3 (Windows) when you tackle Stream Deck profile placement and similar.

---

### Pitfall 13: `.chezmoiexternal.toml` refresh period gotcha (oh-my-zsh, tpm)

`.chezmoiexternal.toml` declares external sources (your oh-my-zsh + tpm archives) with a `refreshPeriod`. Default is "always refresh" if unset. If set too aggressively (like daily), every `apply` redownloads tarballs over network — slow and brittle. If set too rarely (like never), oh-my-zsh ages out and you miss security/compat fixes.

**Prevention:** Set `refreshPeriod = "168h"` (weekly) or similar. Use `chezmoi apply --refresh-externals` for an explicit on-demand refresh. Verify the format in current docs (might be `refreshPeriod` vs `refresh_period`).

**Phase to address:** Phase 0 — audit `.chezmoiexternal.toml` as part of the structural normalization.

---

### Pitfall 14: GPG private key import without trust = useless for signing

After `chezmoi apply` lands the GPG private key from VaultWarden into `~/.gnupg/`, GPG has the key but won't sign with it because the trust level is `unknown` until explicitly set. `git commit -S` will silently NOT sign, or fail with `gpg: signing failed: Unusable secret key`.

**Prevention:** After key import, add a `run_once_after_set-gpg-trust.sh.tmpl` (and `.ps1.tmpl`) that runs:
```bash
echo -e "5\ny\n" | gpg --command-fd 0 --expert --edit-key $KEYID trust
```
…or equivalently `gpg --import-ownertrust` from a trust-db export stored alongside the key. The trust import is a separate ceremony from key import.

**Phase to address:** Phase 2 (GPG bootstrap from VaultWarden).

---

### Pitfall 15: Per-purpose SSH keys + git remote URL mismatch

You set up `~/.ssh/id_personal_github` and `~/.ssh/id_work_github` with `~/.ssh/config` Host aliases (e.g., `Host github-personal` / `Host github-work`). But the chezmoi repo's git remote is still `git@github.com:JamesTeague/dotfiles.git`. After SSH key setup, the chezmoi remote uses the default github.com host → which key gets used depends on agent order. Could be the wrong key. Could silently work via agent forwarding and then break later.

**Prevention:** After SSH key bootstrap, switch the chezmoi git remote to use the right Host alias: `git -C $(chezmoi source-path) remote set-url origin git@github-personal:JamesTeague/dotfiles.git`. Do the same for every repo on the machine. Consider a `run_once_after_rewrite-git-remotes.sh.tmpl` script that handles known repo paths, OR document the manual step crisply.

**Phase to address:** Phase 2 (SSH key strategy).

---

### Pitfall 16: WSL2 systemd requires WSL ≥ 0.67.6 — older WSL fails silently or with confusing errors

`/etc/wsl.conf` `[boot] systemd = true` only works on WSL 0.67.6+. On older WSL, the key is silently ignored and `systemctl` doesn't work — you think systemd is on, it's not, your `enable-bw-agent-on-boot.service` does nothing.

**Prevention:** In the WSL bootstrap script: `wsl --version` first, fail loud with "upgrade WSL: `wsl --update`" if < required. On gaming rig, the WSL is greenfield and Windows host is current → update WSL as part of the Windows phase prerequisites.

**Phase to address:** Phase 4 (WSL greenfield) — version check as the first thing the bootstrap does.

---

## Minor Pitfalls

### Pitfall 17: Go template whitespace control — runaway blank lines or missing whitespace

`{{- ... -}}` trims surrounding whitespace; getting them wrong causes either blank lines stacking up (no trim) or words running together (over-trim, removes intentional spaces). Reading rendered files is the only way to spot these; templates that look clean in source render weird.

**Prevention:** When writing template-heavy files, render-and-inspect via `chezmoi execute-template < file.tmpl` before committing. Adopt a house style: `{{-` and `-}}` on all directives that produce no output (conditionals, ranges); bare `{{` `}}` only when emitting a value.

### Pitfall 18: WSL2 time drift — was fixed, may regress

Earlier WSL2 had clock drift after Windows sleep. Largely fixed in Windows 11. If using older Windows 10 WSL2 or weird sleep scenarios, drift can break TLS (cert validity), `kinit` (Kerberos), and signed-commit verification.

**Prevention:** On WSL: `sudo hwclock -s` as a one-shot if drift observed. Not worth automating unless you actually see drift. Modern Windows 11 + current WSL = ignore.

### Pitfall 19: WezTerm config path differs Mac vs Windows

`~/.config/wezterm/wezterm.lua` on *nix, `%USERPROFILE%\.config\wezterm\wezterm.lua` on Windows (WezTerm does honor `XDG_CONFIG_HOME`-ish paths on Windows in recent versions, but verify per current docs). Single source `dot_config/wezterm/wezterm.lua.tmpl` lands correctly via chezmoi's dot expansion on both.

**Prevention:** Verify on Windows that WezTerm actually reads `%USERPROFILE%\.config\wezterm\`. If not, use a symlink_ source pointing at the Windows-native location.

### Pitfall 20: atuin history sync — preserved, but encryption key bootstrap matters

atuin's sync is end-to-end encrypted with a key the user holds. If you onboard a fresh machine and don't import the same atuin key, sync starts a NEW timeline rather than continuing the existing one.

**Prevention:** Store atuin's key in VaultWarden alongside SSH/GPG. Restore it as part of Phase 2's secret bootstrap before atuin is invoked for the first time on a new machine.

### Pitfall 21: mise activation in PowerShell differs from zsh

`mise activate zsh` vs `mise activate pwsh` — different incantations. Don't copy-paste the zsh line into a `.ps1.tmpl` profile.

**Prevention:** Per-shell profile templates handle their own activation. Don't share a "shell init" template across shell flavors.

### Pitfall 22: `dot_topics/` undocumented convention bites future-you

The `dot_topics/<tool>/path.zsh|eval.zsh|config.zsh|install.sh` convention is smart but invisible. Any new machine's user (or future-you) seeing it for the first time will assume `dot_` means it's a dotfile to be applied, when it's really a *source* of partial config to be loaded by `.zshrc`.

**Prevention:** Phase 0 audit task: add a `dot_topics/README.md` (which IS applied, just as a doc inside the topics dir) explaining the convention. Better still: rename to something that doesn't start with `dot_` so chezmoi doesn't try to put it in `~/.topics/`. Verify what chezmoi actually does with `dot_topics/` today — there may already be a `.chezmoiignore` rule keeping it out of apply.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skip `promptStringOnce`, just use `promptString` | Saves 30 sec of template code | Re-running `chezmoi init` re-prompts ALL keys every time, every machine | **Never** for multi-machine fleets |
| Hardcode role/personal in templates ("just for now") | Avoids data-section work | Refactor never gets undone; templates rot into machine-specific spaghetti | **Never** — defeats the entire taxonomy refactor |
| Skip bootstrap kit fallback ("VaultWarden is reliable enough") | Saves a phase | Single tunnel/cert glitch bricks ALL machines simultaneously; can't even fix the tunnel because you can't get into Unraid | **Never** for the planned vault dependency |
| One giant `install-packages.sh.tmpl` for all OSes | One file to look at | Becomes 500+ line nested-conditional mess; impossible to debug Windows-specific failures | OK in Phase 0 audit phase; split before Phase 1 |
| Use `latest` versions in `packages.yaml` (no pins) | Always-current software | VaultWarden CLI compat break + similar; "it worked yesterday" debugging | OK for shell-only tools (zsh plugins); pin everything that integrates with infra |
| Skip per-purpose SSH keys, one key for everything | Simpler config | Key leak = total compromise; off-boarding from a job means rotating the world | **Never** — security debt that compounds |
| Run `chezmoi apply` from non-elevated terminal on Windows always | No UAC interruptions during dev | Package installs silently fail; you don't know what's actually installed | OK for config-only changes; not OK for first apply or package phase |
| Single `.zshrc.tmpl` no os branching | Tidy file | Mac/Linux/WSL all subtly different; one breaks the others | Acceptable IF you're sure parity holds; verify by actually using all 3 |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| VaultWarden ↔ bw CLI | Floating `bw` to latest, server lags → login broken | Pin CLI version; document compat pair; upgrade server first then CLI |
| chezmoi ↔ bw CLI | Assume `BW_SESSION` exists for template eval | Set `bitwarden.unlock = "auto"` in config; ensure `bw login` has happened; document the `BW_SESSION` export in shell rc |
| chezmoi ↔ Cloudflare tunnel | Treat tunnel as 100% reliable | Implement bootstrap-kit fallback; cache `bw sync` results; monitor tunnel uptime |
| chezmoi ↔ Windows PowerShell | Rely on default execution policy / Windows PowerShell 5.x | Use pwsh (Core); configure interpreters in config; bypass policy for chezmoi scripts only |
| chezmoi ↔ winget | Fire-and-forget loop, no exit-code check, non-elevated context | Run from elevated terminal initially; check every exit code; use `--silent --accept-*` flags |
| chezmoi ↔ Git remote | Default SSH host vs per-purpose key aliases | After SSH bootstrap, rewrite git remotes to use Host aliases |
| chezmoi ↔ GPG | Import key, expect signing to work | Import key + import ownertrust + verify with `gpg --list-secret-keys` showing `[ultimate]` |
| WSL ↔ Windows OpenSSH | Three agents running, conflicting auth | Pick one canonical agent (typically Gpg4win on Windows host); route others to it |
| WSL `/etc/wsl.conf` ↔ Windows `.wslconfig` | Put `[interop]` keys in `.wslconfig` (wrong file) | `interop` is per-distro (`/etc/wsl.conf`); resource limits are global (`.wslconfig`); don't cross them |
| chezmoi external (oh-my-zsh) ↔ refresh | No `refreshPeriod` set → re-downloads every apply | Set explicit `refreshPeriod` (weekly is fine); use `--refresh-externals` for on-demand |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Commit unencrypted bootstrap-kit secrets to private repo | "Private" GitHub repo is still a third party with breach risk; commit history is forever | Use `chezmoi encrypt` (age) for any secret in the repo, even in private repos |
| Single SSH key for all hosts/purposes | One leak → rotate everywhere → high coordination cost | Per-purpose keys (already in plan); document rotation procedure per phase |
| GPG canonical key stored only in VaultWarden | VaultWarden unreachable = can't sign commits = can't push key rotation work | Keep an air-gapped offline backup (encrypted USB) of the GPG master key; subkeys for daily use |
| Trust `chezmoi apply` to run as-is from a remote source you haven't reviewed | Compromised dotfiles repo = arbitrary code execution as you | Review every diff before apply; for bootstrap from URL, verify checksum/sig before piping to shell |
| Persist `BW_SESSION` env var to a shell rc file | Plaintext session token in `~/.zshrc` etc; broader access than intended | Use `bw unlock` interactively or `bitwarden.unlock = "auto"`; do NOT write session token to disk |
| Skip GPG passphrase, "easier for automation" | Anyone with read access to `~/.gnupg/` can sign as you | Use a passphrase; cache via gpg-agent (`default-cache-ttl`); accept the once-per-session prompt |
| Re-use VaultWarden master password across services | Vault breach = everything compromised | Master password is unique, long, and lives only in your head + paper recovery sheet |
| Cloudflare tunnel without access controls | Public-internet-reachable vault with only password auth | Cloudflare Access policy + mTLS (recent best practice per VaultWarden community); IP allowlist if static |

---

## "Looks Done But Isn't" Checklist

- [ ] **Taxonomy refactor:** Templates render without `<no value>` anywhere — verify with `chezmoi apply --dry-run --verbose | grep -i 'no value'` on each existing machine
- [ ] **Taxonomy refactor:** Existing machines' `~/.config/chezmoi/chezmoi.toml` actually gained the new keys — `cat ~/.config/chezmoi/chezmoi.toml` shows `role`, `personal`, etc.
- [ ] **Windows extension:** `chezmoi apply` succeeds end-to-end from a fresh Windows install in a VM, not just on your already-half-set-up gaming rig
- [ ] **Windows extension:** Stream Deck profile actually loaded by Stream Deck app post-apply, not just placed at the right path
- [ ] **Windows extension:** PowerShell profile loads cleanly (no errors on new pwsh session), starship prompt appears, history works
- [ ] **WSL greenfield:** `code .` from WSL launches VS Code on Windows host (interop test); `clip.exe` from WSL receives from pipe (interop test)
- [ ] **WSL greenfield:** `systemctl status` works (systemd actually enabled, not silently ignored due to old WSL)
- [ ] **WSL greenfield:** SSH key in WSL has `0600` perms and survives `wsl --shutdown` (metadata mount working OR keys in native fs)
- [ ] **VaultWarden:** `bw login` works on a fresh machine with no prior state; not just on machines that already have a session
- [ ] **VaultWarden:** `chezmoi apply` from offline (cloudflared stopped, simulate tunnel down) — bootstrap-kit fallback kicks in OR fails loud with actionable message
- [ ] **GPG bootstrap:** `git commit -S` actually signs (signed commit appears in `git log --show-signature`), not just "key imported"
- [ ] **SSH per-purpose keys:** Chezmoi repo's `git pull` uses the correct key (check `ssh -vT git@github-personal` shows the right key fingerprint); not just "keys are in ~/.ssh/"
- [ ] **Multi-machine consistency:** After cutover, Mac personal and Mac work both produce empty `chezmoi diff` — no drift between them
- [ ] **Bootstrap kit:** Actually tested with VaultWarden intentionally taken down, not just designed on paper
- [ ] **Script idempotency:** Re-running `chezmoi apply` immediately after a successful apply produces zero changes and zero script re-runs
- [ ] **role=lite (spiral index):** Browser-Office-Bitwarden-PicPick all installed and working post-apply, not just listed in packages.yaml

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Taxonomy refactor breaks Mac personal mid-cutover | LOW | `chezmoi git -- checkout main` (revert source branch), `chezmoi apply` to restore prior state; investigate in branch separately |
| `chezmoi.toml` on existing machine missing new keys | LOW | Edit `~/.config/chezmoi/chezmoi.toml` by hand to add the missing keys; or `chezmoi init --apply` re-prompts only missing |
| `run_once_` script re-fired (e.g., gpg key generation) | HIGH if destructive | If gpg key regenerated: restore from VaultWarden canonical key OR offline backup; rotate compromised key from any place it was published |
| WSL `/mnt/c` key permissions won't stick | LOW | Move keys to WSL native fs (`~/.ssh/`), update SSH config; OR add `metadata` to `/etc/wsl.conf` automount + `wsl --shutdown` |
| Windows execution policy blocks chezmoi script | LOW | One-shot: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`; then re-apply. Long-term: fix interpreter args in chezmoi config |
| winget package install silently failed | LOW per package | Re-run from elevated terminal: `chezmoi state delete --bucket=scriptState --key=<sha>` then `chezmoi apply` re-fires that script |
| VaultWarden unreachable, need to apply now | MEDIUM | Bootstrap-kit decrypts essentials locally; OR `chezmoi apply --exclude=scripts,encrypted` to skip the secret-touching paths; OR snapshot-rollback the affected machine |
| GPG key imported but commits not signing | LOW | `gpg --import-ownertrust < trust-db.txt` (need this file in vault); OR interactive `gpg --edit-key $ID trust` |
| chezmoi state corruption | MEDIUM | Backup `~/.config/chezmoi/chezmoistate.boltdb`; `chezmoi state reset` (will re-run all run_once scripts — verify idempotency first); restore from backup if reset is destructive |
| Drift between machines mid-migration (one applied, others didn't) | MEDIUM | Pin a "migration tag" in repo (`refactor/v2-cutover`); apply per machine on schedule; verify each with `chezmoi diff` before next; never have >2 versions in flight |
| Bitwarden CLI ↔ VaultWarden version mismatch | MEDIUM | Downgrade `bw` to last known good version (kept in `packages.yaml` pin OR offline binary in bootstrap kit); upgrade VaultWarden separately on Unraid |

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Phase 0 / 0.5: Taxonomy refactor | Existing machines drift, `<no value>` rendering, run_once re-fires | promptStringOnce everywhere; pre-flight `chezmoi execute-template`; script-state audit; cutover ritual documented |
| Phase 0: Audit pass | Remove `generate-gpg-key.sh` cleanly, not just rename | Delete the file entirely; document in commit message; verify no machine has it pending in state |
| Phase 1: Linux + apt + mise | `dot_topics/` convention silently misapplied if it ever escapes its current scope | Audit `.chezmoiignore` covers it; document the convention in `dot_topics/README.md` |
| Phase 2: VaultWarden + SSH + GPG | Bitwarden CLI version drift; agent confusion; trust-db missing | Pin bw CLI; document agent-of-record per machine; ship trust-db alongside key in vault |
| Phase 2: Bootstrap kit | Designed but never tested | Schedule a "vault offline" drill before declaring phase done |
| Phase 3: Windows native | Execution policy, line endings, UAC for winget, AppData paths | pwsh + interpreter config + line-ending directive + elevated bootstrap + symlink_ for AppData configs |
| Phase 3: PowerShell parity | Profile assumes Windows PowerShell 5.x, breaks on pwsh 7+ (or vice versa) | Target pwsh 7+ exclusively; install pwsh as a bootstrap prereq |
| Phase 3: Stream Deck | Profile placement at `%APPDATA%\Elgato\StreamDeck\ProfilesV2\` outside `%USERPROFILE%` root | symlink_ source or run_onchange placer script |
| Phase 4: WSL greenfield | Old WSL → systemd silently ignored; `/mnt/c` permissions; interop tradeoff | `wsl --version` check; metadata mount; explicit appendWindowsPath decision |
| Phase 4: WSL secret bootstrap | Three-agents confusion (Windows OpenSSH, Gpg4win, WSL ssh-agent) | Pick one canonical agent per host; document the routing |
| Phase 5+: role=gaming, role=lite onboarding | Each is the first end-to-end exercise of a new fleet path | Treat first onboarding as a test; document gaps discovered; don't declare phase done on the basis of "it built" |

---

## Cross-Reference to Other Research Dimensions

(Once STACK.md / FEATURES.md / ARCHITECTURE.md land for this domain, these references should resolve. For now, the relevant cross-cuts are:)

- **STACK.md:** chezmoi version pin (2.70.4 baseline per PROJECT.md); `bw` CLI version pin; VaultWarden version awareness; pwsh 7+ as the chosen PowerShell flavor — Pitfalls 3, 7 motivate these
- **FEATURES.md:** "Day-1 single-command onboarding" feature depends on Pitfalls 1, 3, 7, 8, 10 being resolved — these are gates on the headline value
- **ARCHITECTURE.md:** The taxonomy structure (`role` × `personal` × `os` × `wsl`) is the load-bearing data shape; Pitfalls 1, 9 are about preserving its integrity through the migration

---

## Sources

### chezmoi authoritative docs
- [chezmoi: Windows](https://www.chezmoi.io/user-guide/machines/windows/) — Windows-specific behavior, `private_`/`executable_` semantics
- [chezmoi: Interpreters config](https://www.chezmoi.io/reference/configuration-file/interpreters/) — `.ps1` interpreter selection, pwsh vs powershell
- [chezmoi: Bitwarden](https://www.chezmoi.io/user-guide/password-managers/bitwarden/) — `bitwarden.unlock = "auto"`, BW_SESSION
- [chezmoi: Bitwarden functions](https://www.chezmoi.io/reference/templates/bitwarden-functions/) — Template-time caching behavior
- [chezmoi: Setup](https://www.chezmoi.io/user-guide/setup/) — `chezmoi init` re-run with existing config
- [chezmoi: promptStringOnce](https://www.chezmoi.io/reference/templates/init-functions/promptStringOnce/) — Avoids re-prompting on existing data
- [chezmoi: Templates / Directives](https://www.chezmoi.io/reference/templates/directives/) — Line-ending directive
- [chezmoi: Use scripts](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/) — `run_once_` / `run_onchange_` hash semantics
- [chezmoi: Manage different file types](https://www.chezmoi.io/user-guide/manage-different-types-of-file/) — `dot_`, `private_`, `executable_`, encryption + template constraints
- [chezmoi: Troubleshooting](https://www.chezmoi.io/user-guide/frequently-asked-questions/troubleshooting/) — Common failure modes
- [chezmoi: Diff command](https://www.chezmoi.io/reference/commands/diff/) — What diff covers (and doesn't)
- [chezmoi GH discussion #3816: line endings directive](https://github.com/twpayne/chezmoi/discussions/3816) — Singular vs plural directive bug
- [chezmoi GH discussion #1678: clear run_once cache](https://github.com/twpayne/chezmoi/discussions/1678) — Script state reset

### VaultWarden / Bitwarden CLI compat
- [vaultwarden GH issue #6729: CLI 2025.12.0 compat break](https://github.com/dani-garcia/vaultwarden/issues/6729) — "User Decryption Options" recent breakage
- [vaultwarden GH issue #6709: userDecryptionOptions login failure](https://github.com/dani-garcia/vaultwarden/issues/6709)
- [vaultwarden GH issue #4603: attachments not available via CLI](https://github.com/dani-garcia/vaultwarden/issues/4603)
- [vaultwarden GH issue #2378: CLI version login compat](https://github.com/dani-garcia/vaultwarden/issues/2378)
- [Wapnet: Self-hosted Vaultwarden with Cloudflare Tunnel + mTLS](https://blog.wapnet.nl/2026/03/self-hosted-vaultwarden-with-cloudflare-tunnel-and-mtls/) — Recent (March 2026) operational pattern

### WSL operational
- [Microsoft Learn: WSL advanced configuration](https://learn.microsoft.com/en-us/windows/wsl/wsl-config) — `wsl.conf` vs `.wslconfig`, interop, automount, systemd
- [WSL GH issue #9520: interop.appendWindowsPath effect](https://github.com/microsoft/WSL/issues/9520)
- [WSL GH issue #9869: Unknown key interop.appendWindowsPath](https://github.com/microsoft/WSL/issues/9869)
- [linuxvox: WSL PATH broken by spaces in Windows PATH](https://linuxvox.com/blog/wsl-windows-subsystem-linux-breaks-path-when-the-windows-path-has-folder-names-with-spaces/)

### winget / PowerShell on Windows
- [winget-cli GH issue #6173: post-elevation launch failure](https://github.com/microsoft/winget-cli/issues/6173)
- [winget-cli GH issue #5591: UAC prompts in background](https://github.com/microsoft/winget-cli/issues/5591)
- [winget-cli GH discussion #3185: winget as admin](https://github.com/microsoft/winget-cli/discussions/3185)
- [Microsoft Learn: PowerShell execution policies](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)

### GPG / SSH on Windows + WSL
- [Gist: GPG + Git SSH on Windows 10 (matusnovak)](https://gist.github.com/matusnovak/302c7b003043849337f94518a71df777) — Gpg4win + win32-openssh-support pattern
- [Jim's Docs: GPG and SSH for WSL on Windows](https://jimsdocs.jimbrig.com/posts/2022-07-12-configure-gpg-and-ssh-for-wsl-on-windows/) — Three-agents-pick-one routing

### Go templates (whitespace)
- [Go pkg: text/template](https://pkg.go.dev/text/template) — `{{- -}}` whitespace trimming semantics

### Personal experience / context
- Teague's existing chezmoi repo conventions (`dot_topics/`, `.chezmoiroot`, `.chezmoiexternal.toml` for oh-my-zsh + tpm) per `.planning/PROJECT.md`
- VaultWarden on Unraid via Cloudflare tunnel architecture per PROJECT.md constraints

---
*Pitfalls research for: chezmoi multi-OS modernization with VaultWarden integration*
*Researched: 2026-05-27*
