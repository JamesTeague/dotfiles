# Project Research Summary

**Project:** chezmoi Modernization (multi-OS dotfile management, 7-machine fleet)
**Domain:** Cross-OS configuration-as-code with self-hosted secret backend
**Researched:** 2026-05-27
**Confidence:** HIGH

## Executive Summary

This project extends an existing, healthy chezmoi 2.70.4 repo from a Mac-only `personal`-boolean shape into a fleet-aware system spanning macOS, Linux, native Windows, and WSL — taxonomized as `role` (dev/gaming/lite) × `personal` × auto-detected `os` × auto-detected `wsl`. Every load-bearing technology is already at its current stable release (chezmoi 2.70.4, VaultWarden 1.36.0, bw CLI 2026.4.2, PowerShell 7.6.2, mise 2026.5.15, winget 1.28.240, starship 1.25.1) and the chosen patterns (`bitwarden.unlock = "auto"`, `winget configure` DSC YAML, single cross-shell `starship.toml`, chezmoi's built-in age) eliminate entire categories of glue work the prior generation of dotfile repos had to invent. There is no stack uncertainty — the research's job here is to lock the shape, not to pick the parts.

The shape that emerges is opinionated and consistent: `.chezmoiroot = home/` stays, `.chezmoiignore` becomes a templated per-machine inventory (the gating workhorse), `run_onchange_` scripts under `.chezmoiscripts/<os>/` carry idempotent package installs whose re-run trigger is the rendered SHA of a single `.chezmoidata/packages.yaml`, and `.chezmoitemplates/` partials de-duplicate the cross-file blocks (git-signing, SSH host stanzas). VaultWarden via the standard `bw` CLI is the credential plane on every machine; an age-encrypted bootstrap kit in the repo is the disaster-recovery posture for when the Cloudflare tunnel to Unraid is down. Windows-native is the single biggest lift in the modernization and crosses three OS prerequisites (pwsh 7+, ExecPolicy Bypass via interpreter config, elevated first-run for winget), while WSL is uniquely doubly-scoped — chezmoi runs once on the Windows host (to land `%USERPROFILE%\.wslconfig`) and again inside WSL (for everything else); a single apply cannot span that boundary.

The risk concentration is sharp and locatable. The taxonomy refactor itself (Pitfall 1) is high-stakes because `.chezmoi.toml.tmpl` prompts only fire on `chezmoi init`, never on `apply` — existing machines silently render with empty `.role` unless every new key uses `promptStringOnce` AND a documented `chezmoi init --apply` ritual re-runs the template to capture new prompts. Bitwarden CLI ↔ VaultWarden version drift (Pitfall 3) is a recurring real-world bite that requires pinning the CLI in `packages.yaml` against the live server version, not floating to latest. The `generate-gpg-key.sh` retirement (Pitfall 11) is the canonical "must delete cleanly, not just rename" case — leaving the old `run_once_` script under a different name would re-fire on machines that already have it in their state DB and regenerate a NEW canonical key. WSL has two trap pairs: `appendWindowsPath=false` breaks `code .` / `clip.exe` / `explorer.exe` unless narrowly re-added, and keys under `/mnt/c` without the `metadata` automount option silently lose their `0600` permissions on every restart. None of these are showstoppers individually; they are all addressable with the discipline patterns documented in PITFALLS.md, and the roadmap should bake those mitigations directly into the relevant phase definitions.

## Key Findings

### Recommended Stack

Stack is fully prescriptive and current as of 2026-05-27. See `STACK.md` for full version table, install commands, and per-variant patterns.

**Headline simplifications vs 2023-era dotfile repos:** `bitwarden.unlock = "auto"` replaces manual `BW_SESSION` juggling; `winget configure` with DSC YAML replaces ad-hoc `winget install` loops; a single `starship.toml` works across zsh / bash / PowerShell with no per-shell prompt fork; chezmoi's built-in age means no separate `age` binary needed.

**Core technologies (all pinned current as of 2026-05):**
- **chezmoi 2.70.4** — dotfile engine. Already current. `.chezmoiroot` / `.chezmoiexternal.toml` / `.chezmoiscripts/` / `.chezmoidata/` / `.chezmoiignore` are exactly the primitives this fleet's taxonomy needs.
- **VaultWarden 1.36.0 + bw CLI 2026.4.2** — credential plane. CLI accessed via chezmoi's `bitwarden` / `bitwardenFields` / `bitwardenAttachment` template functions. **`bitwardenSecrets` does NOT work against VaultWarden** — explicitly avoid.
- **age (chezmoi built-in)** — encryption for bootstrap kit. No separate binary; activates when `age` not on PATH.
- **mise 2026.5.15** — runtime version manager (node/python/ruby/go) on *nix only. Windows uses winget.
- **winget 1.28.240 + DSC YAML** — Windows packages. `winget configure --file ...` from a `run_onchange_*.ps1.tmpl` is the blessed path.
- **PowerShell 7.6.2** — Windows shell. Target 7.x exclusively; do NOT support 5.1.
- **starship 1.25.1** — cross-shell prompt. Single `~/.config/starship.toml` for zsh, bash, pwsh.
- **PSReadLine 2.4.5** — bundled with pwsh 7.6.x; do NOT `Install-Module PSReadLine -Force`.

**Anti-stack (explicitly rejected):** Nix / home-manager (no native Windows), Linux Homebrew, Bitwarden Secrets Manager / `rbw`, PowerShell 5.1, Chocolatey, Scoop, MSYS2 / Git Bash, oh-my-posh, pyenv/nvm/rbenv/goenv (all replaced by mise), per-machine GPG key generation.

### Expected Features

**Must have (table stakes):**
- 3-role × personal × OS × WSL taxonomy in `.chezmoi.toml.tmpl`
- Restructured `packages.yaml` around `roles.<role>.<os>` + `overlays.personal.<os>` + `overlays.work.<os>`
- Per-OS conditional gating via `.chezmoiignore` (whole-file) + in-file `{{ if eq .chezmoi.os ... }}` (within-file deltas)
- VaultWarden integration via `bitwarden*` template functions with `bitwarden.unlock = "auto"`
- Canonical GPG signing key pulled from VaultWarden (retires `generate-gpg-key.sh` — must DELETE cleanly)
- Per-purpose SSH keys (personal-github + work-github + optional homelab) via `Host` aliases in `~/.ssh/config`
- Encrypted bootstrap kit (age-encrypted recovery essentials; identity OFF-repo on paper / hardware token)
- Day-1 single-command bootstrap (`chezmoi init --apply <repo>`) per OS with documented manual prereqs
- Drift detection (`chezmoi diff` zero-functional-diff is the per-machine cutover gate)
- `dot_topics/<tool>/` convention documented (currently load-bearing but undocumented)

**Should have (differentiators):**
- Cross-OS prompt parity via starship (lift to Windows pwsh)
- PowerShell profile parity with zshrc muscle memory
- Stream Deck profile management (gaming rig only) via binary `.streamDeckProfile` files
- `run_onchange_` install scripts whose re-run trigger is the SHA of `packages.yaml`
- `.chezmoiignore` as readable per-machine inventory (heavily commented)
- Per-role README/docs scaffold (ROLES.md as deliverable)
- Hostname-based prompt defaults in `.chezmoi.toml.tmpl`

**Defer (post-modernization):**
- Future Linux laptop role=dev coverage (only when laptop is real)
- Renovate/Dependabot for `packages.yaml` pins
- Shell-prompt "chezmoi N commits behind" indicator
- Atuin server self-host for cross-machine history sync (separate decision)

**Anti-features (explicitly out of scope):** one-key-everywhere SSH, Nix, Linux Homebrew, one-key-everywhere GPG, OBS/Unraid in chezmoi, auto-apply on git pull, auto-detected role, driver/BIOS/GPU automation, stow-style symlinks, custom inline encryption pipelines.

### Architecture Approach

Single-repo, single-`.chezmoiroot` (`home/`) source tree with five layered concerns: static data (`.chezmoidata/*.yaml`, loaded before templating), root config (`.chezmoi.toml.tmpl`, prompts + auto-detection), gating (`.chezmoiignore`, templated), target-state entries (`dot_*`/`private_*`/`executable_*`), externals (`.chezmoiexternal.toml`), shared partials (`.chezmoitemplates/`), and scripts (`.chezmoiscripts/<os>/`).

**Apply-time data flow (10 strict steps):** read `.chezmoiroot` → load static data → load per-machine config → compute built-in facts → evaluate `.chezmoiignore` as template → plan target state → before-scripts → apply target updates (incl. externals) → after-scripts → record state in `chezmoistate.boltdb`.

**Non-negotiable structural rules:**
- `.chezmoidata/*` files CANNOT be templates (load before engine starts)
- `run_*_before_*` scripts CANNOT consume externals (externals apply during step 8)

**Major components:**
1. `.chezmoi.toml.tmpl` — `promptStringOnce`/`promptBoolOnce` ONLY (never bare `promptString`) + auto-detection (os/arch/hostname/wsl)
2. `.chezmoidata/packages.yaml` — `packages.roles.<role>.<os>` + `overlays.personal.<os>` + `overlays.work.<os>`. Plain YAML.
3. `.chezmoiignore` (templated) — gating workhorse. Per-OS/role/personal subtree exclusions. Excludes always win.
4. `.chezmoiscripts/<os>/` — `common/`, `darwin/`, `linux/`, `windows/` subdirs with `run_[once|onchange]_[before|after]?_NN-name.{sh,ps1}.tmpl`. Numeric prefix orders. `run_onchange_` is the workhorse.
5. `.chezmoitemplates/` — partials via `{{ template "name" . }}`. First population: git-signing, SSH host stanza, brew-bundle renderer.
6. `bootstrap/` — age-encrypted recovery essentials + `run_once_recover.sh.tmpl` gated to `--data='{"bootstrap":true}'`. Age identity OFF-repo.
7. Per-machine `chezmoi.toml` + `chezmoistate.boltdb` — auto-written / chezmoi-internal. Tracks data + `run_once`/`run_onchange` hashes.

**Anti-patterns:** wrapping whole files in `{{ if eq .chezmoi.os "X" }}` (use `.chezmoiignore`); install scripts inside `dot_topics/<tool>/` (chezmoi copies, doesn't execute); templating `.chezmoidata/*.yaml`; one mega-install-script (split for hash isolation); storing age recovery identity in repo; relying on `.chezmoiroot` being templated.

### Critical Pitfalls

Five that the roadmap must bake into specific phases (full 22 in PITFALLS.md):

1. **`.chezmoi.toml.tmpl` prompts fire only on `chezmoi init`, never on `apply`** (Pitfall 1) — Existing Mac machines silently render `<no value>` for `.role` unless every new key uses `promptStringOnce` AND each existing machine runs `chezmoi init --apply` ritual. Phase 0 must include the per-machine cutover ritual + pre-flight `chezmoi execute-template`.

2. **VaultWarden ↔ Bitwarden CLI version drift breaks login at the worst time** (Pitfall 3) — CLI 2025.12.0 already broke against VaultWarden < 1.36.x. Pin CLI in `packages.yaml`; document working CLI/server pair; bootstrap kit must include offline known-good `bw` binary.

3. **Windows has three first-run prerequisites chezmoi cannot automate itself** (Pitfalls 4, 7, 8) — pwsh 7+ pre-installed (chezmoi falls back to 5.x without DSC v3); execution policy must allow scripts (`[interpreters.ps1]` with `-ExecutionPolicy Bypass`, OR documented one-time `Set-ExecutionPolicy`); first apply MUST run from elevated terminal (winget UAC bug #5591). Line-ending directive (`chezmoi:template:line-ending=native` — singular, doc/code drift exists) at top of every `.ps1.tmpl`.

4. **WSL trap pairs** (Pitfalls 5, 6) — `appendWindowsPath=false` breaks `code .`/`clip.exe`/`explorer.exe`; `/mnt/c` without `metadata` automount = SSH/GPG `UNPROTECTED PRIVATE KEY FILE`. Three ssh-agent worlds (Windows OpenSSH service, Gpg4win, WSL ssh-agent) must route to ONE canonical. Pick Gpg4win on host; route WSL `SSH_AUTH_SOCK` via `wsl-ssh-pageant`.

5. **`run_once_` script state is per-machine boltdb and survives refactors** (Pitfall 11) — `generate-gpg-key.sh` retirement is the canonical "must DELETE not rename" case. Renaming = old hash re-fires on machines that have it in state = NEW canonical GPG key (disaster). Audit every `run_once_` BEFORE Phase 0 cutover.

**Honorable mention (Pitfall 10):** VaultWarden unreachable during `chezmoi apply` fails-closed and bricks routine operations across the fleet simultaneously. Bootstrap-kit fallback is NOT optional — must land in Phase 1, not "later."

## Implications for Roadmap

Six phases with hard ordering between the first three; parallel-safe opportunism in the rest.

### Phase 0.5: Audit & Documentation

**Rationale:** Defensible baseline before structural change. Pure additive; zero apply risk.

**Delivers:** `docs/dot_topics.md`; `docs/conventions.md`; dead config dropped (orphaned flameshot, unused taps, dead casks); `packages.yaml` nesting normalized (no axis restructuring yet); `.gitattributes` enforcing `*.tmpl text eol=lf`.

**Addresses:** Pitfall 22 (`dot_topics/` undocumented).

### Phase 0: Structural Refactor (on branch, atomic)

**Rationale:** Foundation. Taxonomy must land before any subsequent phase. Branch-based with `chezmoi diff` empty on BOTH Mac machines as merge gate.

**Delivers:** `.chezmoi.toml.tmpl` extended with `role` prompt (`promptStringOnce` exclusively; default `dev`); `.chezmoidata/roles.yaml`; rewritten `.chezmoidata/packages.yaml` (`roles.<role>.<os>` + overlays); `.chezmoiscripts/{common,darwin,linux,windows}/` skeleton; updated `.chezmoiignore`; `.chezmoitemplates/` with first 2-3 partials; **explicit DELETION (not rename) of `generate-gpg-key.sh`**; per-machine cutover ritual documented.

**Addresses:** Table stakes 1-3 (taxonomy, packages restructure, OS+WSL gating).

**Avoids:** Pitfalls 1, 2, 9, 11.

**Validation gate:** `chezmoi diff` empty on Mac personal AND Mac work; `chezmoi apply --dry-run --verbose | grep -i 'no value'` returns nothing.

### Phase 1: VaultWarden + Secret Plane + Bootstrap Kit

**Rationale:** Credential plane must land before any phase that depends on retrieving secrets. Bootstrap kit must exist before operational vault dependency.

**Delivers:** `bitwarden.unlock = "auto"`; canonical GPG signing key via `bitwardenAttachment` + ownertrust import; per-purpose SSH keys with `Host` aliases; chezmoi git remote rewritten to `git@github-personal:...`; `bootstrap/encrypted_essentials.age` + age-identity stewardship strategy (paper + hardware token); offline known-good `bw` binary; **`bw` CLI version PINNED in `packages.yaml`** against VaultWarden 1.36.0; vault-offline drill executed.

**Addresses:** Table stakes 4-7.

**Avoids:** Pitfalls 3, 10, 14, 15.

**Validation gate:** Cloudflared stopped → `chezmoi apply` uses bootstrap-kit fallback or fails loud with actionable message; `git commit -S` actually signs; `ssh -vT git@github-personal` shows right fingerprint.

### Phase 2: Windows-Native Support

**Rationale:** Biggest single lift. New shell + package manager + scripting dialect + path conventions. Must precede WSL phase.

**Delivers:** `AppData/` subtree (literal Windows layout); `.chezmoiscripts/windows/run_once_before_10-install-winget.ps1.tmpl`; `run_onchange_20-install-packages.ps1.tmpl` using `winget configure --file winget-configure.yaml`; `winget-configure.yaml.tmpl` (DSC YAML with `Microsoft.WinGet.DSC/WinGetPackage`); `private_Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl` with starship init + PSReadLine config; `packages.yaml` additions for `roles.{gaming,dev,lite}.windows`; `[interpreters.ps1]` with `-ExecutionPolicy Bypass`; line-ending directive on every `.ps1.tmpl`; Windows bootstrap README documenting 3 prereqs; Stream Deck profile placement under `AppData/Roaming/Elgato/StreamDeck/ProfilesV2/` (gaming only).

**Addresses:** Differentiators (cross-OS prompt parity, pwsh parity, Stream Deck); Windows package management; `role=gaming` and `role=lite`.

**Avoids:** Pitfalls 4, 7, 8, 12.

**Validation gate:** Fresh Windows VM → `chezmoi init --apply` from elevated terminal → end-to-end success; Stream Deck app loads profile; pwsh profile loads with starship.

### Phase 3: WSL Greenfield (additive, crosses host/WSL boundary)

**Rationale:** WSL is uniquely two-application (Windows host for `.wslconfig`, inside WSL for everything else). Single apply cannot span. Depends on Phase 2.

**Delivers:** `private_dot_wslconfig.tmpl` (Windows host source tree → `%USERPROFILE%\.wslconfig` with memory/processors/swap/mirrored-networking/autoMemoryReclaim/sparseVhd); `etc/wsl.conf.tmpl` in WSL source tree (`[boot] systemd=true`, `[automount] options="metadata,umask=22,fmask=11"`, explicit `appendWindowsPath` decision); `packages.yaml` additions for `roles.dev.linux` (apt + mise); WSL detected via `.chezmoi.kernel.osrelease | lower | contains "microsoft"`; documented canonical-agent rule (Gpg4win on host; WSL `SSH_AUTH_SOCK` via `wsl-ssh-pageant`); narrow Windows-tool re-add list in WSL `.zshrc.tmpl` (if `appendWindowsPath=false`); `wsl --version` check as first bootstrap step.

**Addresses:** WSL greenfield setup on gaming rig; `role=dev` on Linux; cross-OS shell parity extending to WSL.

**Avoids:** Pitfalls 5, 6, 16.

**Validation gate:** `code .` from WSL launches Windows VS Code; `systemctl status` works; SSH key in WSL native fs has `0600` surviving `wsl --shutdown`.

### Phase 4: Lonestar Onboarding + Polish

**Rationale:** Hardening. If Phases 0-3 are clean, this is documentation + first-run polish + parallel-safe items.

**Delivers:** OS-specific "new machine bootstrap" README sections; ROLES.md spec; Session 59 Claude Code integration (`settings.json.tmpl` + `~/dev/CLAUDE.md` gated by `personal`); first end-to-end Lonestar onboarding executed as real test; optional GitHub Actions schema lint for `.chezmoidata/packages.yaml`; hostname-based prompt defaults if init friction observed; "Looks Done But Isn't" checklist run as final acceptance.

### Phase Ordering Rationale

- **0.5 → 0 → 1 is strict.** Audit before refactor; refactor before secret plane (`.role` must resolve before `bitwarden*` templates can gate).
- **Phase 2 (Windows) before Phase 3 (WSL) is strict.** `.wslconfig` is a Windows-host artifact.
- **Phase 4 is opportunistic.** Internal items mostly parallel-safe.
- **Bootstrap kit lives in Phase 1, NOT Phase 4.** Treating as "later" is the failure mode.
- **`generate-gpg-key.sh` DELETION is Phase 0 line-item, not a footnote.** Wrong handling = new canonical key on every existing machine = security incident.

### Research Flags

**Need deeper research at planning time (`/gsd:research-phase`):**
- **Phase 2 (Windows):** exact `[interpreters.ps1]` arg form (singular vs plural line-ending bug); `winget configure` flag handling from templated YAML; long-path policy on gaming rig; Stream Deck profile UUID stability across exports
- **Phase 3 (WSL):** `wsl-ssh-pageant` (or successor) for routing `SSH_AUTH_SOCK` to Gpg4win — evolving best practice; WSL version requirements vs gaming rig actual state
- **Phase 1 (VaultWarden + Bootstrap):** chezmoi `decrypt` template fn syntax + `--data='{"bootstrap":true}'` gating; age-identity stewardship choice (paper / hardware token / where it physically lives)

**Standard patterns (skip research):**
- Phase 0.5 (audit/docs/dead-config removal — obvious from current repo)
- Phase 0 (architecture fully specified in ARCHITECTURE.md; pitfalls in PITFALLS.md)
- Phase 4 (reuses earlier patterns)

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Every recommendation verified against current upstream docs and GitHub releases as of 2026-05. Versions explicit. |
| Features | HIGH | chezmoi capabilities verified against official docs; cross-OS quirks verified against real-world dotfile repos; 11 anti-features catalogued. |
| Architecture | HIGH | Sourced from official chezmoi docs + practitioner write-ups; build order is opinionated and aligned with feature dependency graph. |
| Pitfalls | HIGH (chezmoi mechanics) / MEDIUM (VaultWarden quirks — version-bound) / HIGH (WSL operational pitfalls). 22 pitfalls with detection signals + recovery. |

**Overall:** HIGH

### Gaps to Address (operational, not research-resolvable)

- **Bootstrap-kit content design (Phase 1):** what goes in the age-encrypted essentials; where age identity physically lives during disaster; recovery ceremony itself
- **VaultWarden + bw CLI compat tracking (ongoing):** pinned-version strategy + documented upgrade runbook
- **Three-agents routing (Phase 3):** re-verify `wsl-ssh-pageant` (or successor) best practice at planning time
- **Long-path policy on gaming rig (Phase 2):** first-hand verification before deep `AppData/...` tree applies
- **Tracked PROJECT.md lookups (Teague confirms during execution):** SSN install path; WezTerm Windows config status; Office license type

## Sources

### Primary (HIGH confidence) — chezmoi docs
- https://www.chezmoi.io/reference/source-state-attributes/
- https://www.chezmoi.io/reference/special-files/
- https://www.chezmoi.io/reference/special-directories/chezmoidata/
- https://www.chezmoi.io/reference/application-order/
- https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/
- https://www.chezmoi.io/user-guide/templating/
- https://www.chezmoi.io/user-guide/password-managers/bitwarden/
- https://www.chezmoi.io/reference/templates/bitwarden-functions/
- https://www.chezmoi.io/user-guide/encryption/age/
- https://www.chezmoi.io/user-guide/machines/windows/
- https://www.chezmoi.io/reference/configuration-file/interpreters/
- https://www.chezmoi.io/reference/templates/init-functions/promptStringOnce/

### Primary (HIGH confidence) — stack upstream
- chezmoi 2.70.4, VaultWarden 1.36.0, bw CLI 2026.4.2, pwsh 7.6.2, PSReadLine 2.4.5, winget 1.28.240, mise 2026.5.15, starship 1.25.1 (all from official GitHub releases pages)
- https://learn.microsoft.com/en-us/windows/wsl/wsl-config
- https://learn.microsoft.com/en-us/windows/package-manager/configuration/

### Secondary (MEDIUM)
- VaultWarden issues #6729, #6709 (CLI compat breaks)
- winget-cli issue #5591 (UAC swallowed)
- WSL issues #9520, #9869 (appendWindowsPath behavior)
- chezmoi discussions #3816 (line-ending directive drift), #3083 (.chezmoiroot non-templated), #4942 (WSL detection)
- Practitioner repos: jwnmulder/dotfiles, karnzx/dotfiles, mimikun/dotfiles-windows, Jaykul/dotfiles

### Detailed research files
- `.planning/research/STACK.md`
- `.planning/research/FEATURES.md`
- `.planning/research/ARCHITECTURE.md`
- `.planning/research/PITFALLS.md`

---
*Research completed: 2026-05-27*
*Ready for roadmap: yes*
