# Requirements: chezmoi Modernization

**Defined:** 2026-05-27
**Core Value:** A new machine — any OS in the fleet — can be set up day-1 via a single `chezmoi init --apply` flow (plus VaultWarden login + GitHub PAT for HTTPS clone bootstrap) and arrive at a fully-configured, identity-signed, role-appropriate state without artisanal touch-up.

## v1 Requirements

### Taxonomy & Structure

- [ ] **TAX-01**: User can configure a machine's `role` via `chezmoi init` prompt (one of: dev, gaming, lite) using `promptStringOnce`
- [ ] **TAX-02**: User's `personal` flag works orthogonally to `role` (work-issued dev machine ≠ personal dev machine)
- [ ] **TAX-03**: chezmoi auto-detects OS (darwin / linux / windows) and exposes via `.chezmoi.os`
- [ ] **TAX-04**: chezmoi auto-detects WSL and exposes via `.wsl` flag based on `.chezmoi.kernel.osrelease` containing "microsoft"
- [ ] **TAX-05**: `.chezmoidata/packages.yaml` is restructured around `roles.<role>.<os>` + `overlays.personal.<os>` + `overlays.work.<os>` axes
- [ ] **TAX-06**: `.chezmoiignore` is templated and gates whole-file/subtree inclusion by role + personal + os + wsl (single gating decision point)
- [ ] **TAX-07**: Existing Mac personal + Mac work machines produce zero functional diff after the structural refactor (per `chezmoi diff` validation gate)
- [ ] **TAX-08**: `dot_topics/<tool>/` convention is documented in `docs/dot_topics.md` (load-bearing but currently undocumented)

### Audit & Cleanup (Phase 0.5)

- [ ] **AUD-01**: Dead `packages.yaml` entries removed (orphaned/abandonware audit)
- [ ] **AUD-02**: `personal/work.{core,darwin,linux}` nesting inconsistency normalized within current structure (pre-restructure)
- [ ] **AUD-03**: Orphaned `home/private_dot_config/flameshot/` deleted (Shottr replaced it on Mac)
- [ ] **AUD-04**: `.gitattributes` added enforcing `*.tmpl text eol=lf` (Windows line-ending hygiene)
- [ ] **AUD-05**: `docs/conventions.md` documenting structural decisions inherited from prior sessions

### Secrets & Identity

- [ ] **SEC-01**: chezmoi config sets `bitwarden.unlock = "auto"` (eliminates manual `BW_SESSION` ritual)
- [ ] **SEC-02**: `bw` CLI version pinned in `packages.yaml` against VaultWarden 1.36.0 (prevents CLI/server drift breakage)
- [ ] **SEC-03**: Canonical GPG signing key retrieved from VaultWarden via `bitwardenAttachment` template function
- [ ] **SEC-04**: GPG ownertrust imported via `run_once_after_*.sh.tmpl` so signing works post-import
- [ ] **SEC-05**: `home/scripts/generate-gpg-key.sh` DELETED (not renamed — avoids re-fire of `run_once_` on existing machines generating new canonical key)
- [ ] **SEC-06**: Per-purpose SSH keys retrieved from VaultWarden (`personal-github` + `work-github` minimum)
- [ ] **SEC-07**: SSH `~/.ssh/config` uses Host aliases (`github-personal`, `github-work`) to disambiguate per-purpose keys
- [ ] **SEC-08**: chezmoi repo's git remote rewritten to use `git@github-personal:JamesTeague/dotfiles.git`
- [ ] **SEC-09**: User can `git commit -S` and the commit is signed with the canonical GPG identity on first machine setup
- [ ] **SEC-10**: User can `ssh -T git@github-personal` and authenticate as the personal identity on first setup

### Bootstrap Kit (Disaster Recovery)

- [ ] **BOOT-01**: `bootstrap/encrypted_essentials.age` exists containing recovery essentials (canonical GPG key, primary SSH key, GitHub PAT)
- [ ] **BOOT-02**: age identity stored OFF-repo (paper backup + hardware token strategy documented)
- [ ] **BOOT-03**: Offline known-good `bw` binary embedded in bootstrap kit for VaultWarden-API-compat failure scenarios
- [ ] **BOOT-04**: Bootstrap recovery procedure documented and exercised (vault-offline drill executed once before phase close)
- [ ] **BOOT-05**: `chezmoi apply` with VaultWarden unreachable either falls back to bootstrap kit or fails loud with actionable message (no silent failure)

### Linux Package Management

- [ ] **LNX-01**: `packages.yaml` supports `roles.dev.linux` with apt package list
- [ ] **LNX-02**: `packages.yaml` supports `roles.dev.linux` with mise tool list (separate from apt)
- [ ] **LNX-03**: `run_onchange_*.sh.tmpl` installs apt packages idempotently with re-run trigger = SHA of packages.yaml
- [ ] **LNX-04**: `run_onchange_*.sh.tmpl` installs mise tools from `~/.config/mise/config.toml`
- [ ] **LNX-05**: NO Linux Homebrew anywhere (explicit decision)

### Windows-Native Support

- [ ] **WIN-01**: `.chezmoi.toml.tmpl` includes `[interpreters.ps1]` configuration with `-ExecutionPolicy Bypass` flag
- [ ] **WIN-02**: All `.ps1.tmpl` files include chezmoi line-ending directive at top (`chezmoi:template:line-ending=native` — singular form)
- [ ] **WIN-03**: `packages.yaml` supports `roles.<role>.windows` with winget package IDs
- [ ] **WIN-04**: `winget-configure.yaml.tmpl` renders to a DSC YAML consumed by `winget configure --file ...`
- [ ] **WIN-05**: `.chezmoiscripts/windows/run_once_before_*.ps1.tmpl` installs winget itself if not present
- [ ] **WIN-06**: `.chezmoiscripts/windows/run_onchange_*.ps1.tmpl` runs `winget configure` against the rendered YAML
- [ ] **WIN-07**: PowerShell profile at `Documents/PowerShell/Microsoft.PowerShell_profile.ps1` initializes starship + PSReadLine
- [ ] **WIN-08**: Cross-OS `~/.config/starship.toml` works correctly in PowerShell (single config across zsh/bash/pwsh)
- [ ] **WIN-09**: Documented Windows bootstrap prerequisites: pwsh 7+ pre-installed, ExecutionPolicy configured, elevated first-run
- [ ] **WIN-10**: Default role for Windows machines maps appropriately (gaming for gaming rig, lite for spiral index, dev for dev-Windows like Lonestar if applicable)

### role=gaming (Windows gaming rig)

- [ ] **GAM-01**: `packages.yaml roles.gaming.windows` includes: Steam, OBS, Discord, Chrome, GIMP, Audacity, Handbrake, HWiNFO64, CPU-Z, GPU-Z, WezTerm, Claude desktop, Epic, EA, Rockstar Launcher, Google Drive, Microsoft Office, GeForce Experience, Elgato Stream Deck, 7-Zip, VLC, MullvadVPN, Bitwarden, PicPick
- [ ] **GAM-02**: Documented manual install for vendor-only software (RODE Central, RODECaster Pro, Insta360 Link Controller)
- [ ] **GAM-03**: Stream Deck profile management at `AppData/Roaming/Elgato/StreamDeck/ProfilesV2/` (binary `.streamDeckProfile` files committed)
- [ ] **GAM-04**: gaming rig successfully bootstraps from `chezmoi init --apply` in elevated pwsh terminal end-to-end

### role=lite (Spiral index Windows)

- [ ] **LIT-01**: `packages.yaml roles.lite.windows` includes: Chrome, Microsoft Office, Bitwarden, PicPick (minimal productivity-only set)
- [ ] **LIT-02**: Minimal PowerShell profile (just starship + basic functionality)
- [ ] **LIT-03**: Documented manual `.msi` install for the vendor work tool (flash drive workflow — not worth automating)
- [ ] **LIT-04**: Spiral index laptop successfully bootstraps from `chezmoi init --apply` end-to-end

### WSL Greenfield

- [ ] **WSL-01**: `private_dot_wslconfig.tmpl` (Windows host) renders to `%USERPROFILE%\.wslconfig` with appropriate resource limits + mirrored networking + autoMemoryReclaim + sparseVhd
- [ ] **WSL-02**: `etc/wsl.conf.tmpl` (inside WSL) configures `[boot] systemd=true`, `[automount] options="metadata,umask=22,fmask=11"`, explicit `[interop] appendWindowsPath` decision
- [ ] **WSL-03**: If `appendWindowsPath=false` chosen, narrow re-add list for `code`, `clip.exe`, `explorer.exe` in WSL `.zshrc.tmpl`
- [ ] **WSL-04**: WSL `roles.dev.linux` inherits Mac dev's shell config (zsh + starship + atuin + tmux + topics)
- [ ] **WSL-05**: SSH keys in WSL live in native filesystem (NOT under `/mnt/c/`) to preserve `0600` permissions
- [ ] **WSL-06**: Gpg4win designated as canonical Windows-host agent; WSL routes `SSH_AUTH_SOCK` via `wsl-ssh-pageant` (or current best-practice equivalent)
- [ ] **WSL-07**: `wsl --version` check is first thing the WSL bootstrap does (systemd requires ≥ 0.67.6)
- [ ] **WSL-08**: WSL on gaming rig successfully bootstraps after greenfield wipe (`wsl --unregister Ubuntu` → `wsl --install -d Ubuntu` → `chezmoi init --apply` inside WSL)
- [ ] **WSL-09**: `code .` from WSL launches Windows VS Code (interop verification)

### Lonestar Onboarding & Polish

- [ ] **LON-01**: README has OS-specific "new machine bootstrap" sections (one each for darwin/linux/windows/wsl)
- [ ] **LON-02**: `ROLES.md` exists describing each role's purpose, package inventory, what's included/excluded
- [ ] **LON-03**: Session 59's Claude Code integration folded in (`settings.json.tmpl` + `~/dev/CLAUDE.md` gated by `personal` flag in `.chezmoiignore`)
- [ ] **LON-04**: Lonestar machine (when received) bootstraps end-to-end via documented procedure on first try

### Cross-OS Screenshot Tools

- [x] **SS-01**: Shottr installed on Mac via existing `darwin.casks.personal` (already in baseline) — verified by Plan 00.5-01: present in `home/.chezmoidata/packages.yaml` line 78 AND installed on Mac personal (`brew list --cask | grep shottr`)
- [ ] **SS-02**: PicPick installed on Windows via `winget` for all Windows roles
- [ ] **SS-03**: Flameshot config preserved in `private_dot_config/flameshot/` and gated to `role=dev + os=linux` (dormant until Linux laptop materializes)

### Cross-OS Shell Parity

- [ ] **PAR-01**: `~/.config/starship.toml` is the single prompt config across all OSes and shells
- [ ] **PAR-02**: PSReadLine on Windows provides zsh-autosuggestions-equivalent UX (predictive history)

## v2 Requirements

### Future Linux Laptop

- **FUT-01**: When future Linux laptop materializes, `role=dev + os=linux` should onboard with no additional template work

### Optional Quality-of-Life

- **QOL-01**: GitHub Actions schema lint for `.chezmoidata/packages.yaml` (catches typos early)
- **QOL-02**: Hostname-based prompt defaults in `.chezmoi.toml.tmpl` if init friction observed
- **QOL-03**: Renovate/Dependabot for `packages.yaml` pins (only if pin patterns prove painful)
- **QOL-04**: Atuin server self-host on Unraid for cross-machine history sync (separate decision)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Unraid homelab management via chezmoi | Appliance OS configured via Web UI; Unraid's native flash backup is the right primitive |
| OBS scenes/assets management in chezmoi | Cross-role personal media surface; scattered assets need cleanup + portability redesign first — deferred to standalone sub-project |
| Forgejo migration / leaving GitHub | Deferred to separate investigation sub-project |
| Comprehensive git scripts review | Overlaps with Phase 0's `generate-gpg-key.sh` retirement anyway; expanded review is separate sub-project |
| Driver/BIOS/GPU OC/NVIDIA Control Panel automation | Can't be meaningfully automated; manual is correct |
| Audio device routing (RODECaster → Windows → OBS) | Machine-specific (depends on USB ports + audio device GUIDs Windows assigns); not portable |
| Display setup/scaling, taskbar pinning | Per-machine, hardware-specific manual touches |
| Linux Homebrew | apt + mise is the chosen alternative |
| Nix / home-manager | No native Windows support; locked decision |
| Bitwarden Secrets Manager / `rbw` | VaultWarden doesn't implement; locked decision |
| PowerShell 5.1 support | 5.1 is maintenance mode, no DSC v3, dual profile paths |
| One-key-everywhere SSH | Rotation hygiene; per-purpose keys with smaller blast radius |
| Per-machine GPG key generation | Inverse of canonical-key approach; locked decision |
| Auto-apply on git pull | Surprise side effects; user runs `chezmoi apply` explicitly |
| Auto-detected role | Role is explicit user intent, not OS-derived |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUD-01 | Phase 0.5 | Pending |
| AUD-02 | Phase 0.5 | Pending |
| AUD-03 | Phase 0.5 | Pending |
| AUD-04 | Phase 0.5 | Pending |
| AUD-05 | Phase 0.5 | Pending |
| TAX-01 | Phase 0 | Pending |
| TAX-02 | Phase 0 | Pending |
| TAX-03 | Phase 0 | Pending |
| TAX-04 | Phase 0 | Pending |
| TAX-05 | Phase 0 | Pending |
| TAX-06 | Phase 0 | Pending |
| TAX-07 | Phase 0 | Pending |
| TAX-08 | Phase 0 | Pending |
| SEC-01 | Phase 1 | Pending |
| SEC-02 | Phase 1 | Pending |
| SEC-03 | Phase 1 | Pending |
| SEC-04 | Phase 1 | Pending |
| SEC-05 | Phase 0 | Pending |
| SEC-06 | Phase 1 | Pending |
| SEC-07 | Phase 1 | Pending |
| SEC-08 | Phase 1 | Pending |
| SEC-09 | Phase 1 | Pending |
| SEC-10 | Phase 1 | Pending |
| BOOT-01 | Phase 1 | Pending |
| BOOT-02 | Phase 1 | Pending |
| BOOT-03 | Phase 1 | Pending |
| BOOT-04 | Phase 1 | Pending |
| BOOT-05 | Phase 1 | Pending |
| LNX-01 | Phase 3 | Pending |
| LNX-02 | Phase 3 | Pending |
| LNX-03 | Phase 3 | Pending |
| LNX-04 | Phase 3 | Pending |
| LNX-05 | Phase 0 | Pending |
| WIN-01 | Phase 2 | Pending |
| WIN-02 | Phase 2 | Pending |
| WIN-03 | Phase 2 | Pending |
| WIN-04 | Phase 2 | Pending |
| WIN-05 | Phase 2 | Pending |
| WIN-06 | Phase 2 | Pending |
| WIN-07 | Phase 2 | Pending |
| WIN-08 | Phase 2 | Pending |
| WIN-09 | Phase 2 | Pending |
| WIN-10 | Phase 2 | Pending |
| GAM-01 | Phase 2 | Pending |
| GAM-02 | Phase 2 | Pending |
| GAM-03 | Phase 2 | Pending |
| GAM-04 | Phase 2 | Pending |
| LIT-01 | Phase 2 | Pending |
| LIT-02 | Phase 2 | Pending |
| LIT-03 | Phase 2 | Pending |
| LIT-04 | Phase 2 | Pending |
| WSL-01 | Phase 3 | Pending |
| WSL-02 | Phase 3 | Pending |
| WSL-03 | Phase 3 | Pending |
| WSL-04 | Phase 3 | Pending |
| WSL-05 | Phase 3 | Pending |
| WSL-06 | Phase 3 | Pending |
| WSL-07 | Phase 3 | Pending |
| WSL-08 | Phase 3 | Pending |
| WSL-09 | Phase 3 | Pending |
| LON-01 | Phase 4 | Pending |
| LON-02 | Phase 4 | Pending |
| LON-03 | Phase 4 | Pending |
| LON-04 | Phase 4 | Pending |
| SS-01 | Phase 0.5 | Complete (2026-05-27, Plan 00.5-01) |
| SS-02 | Phase 2 | Pending |
| SS-03 | Phase 0 | Pending |
| PAR-01 | Phase 2 | Pending |
| PAR-02 | Phase 2 | Pending |

**Coverage:**
- v1 requirements: 69 total
- Mapped to phases: 69
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-27*
*Last updated: 2026-05-27 after roadmap creation (coverage count corrected: 69 reqs total)*
