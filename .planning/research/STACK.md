# Stack Research

**Domain:** Multi-OS dotfile management (macOS / Linux / WSL / native Windows) with self-hosted secret backend
**Researched:** 2026-05-27
**Confidence:** HIGH (all recommendations verified against current upstream docs and GitHub releases as of May 2026)

## TL;DR — Prescriptive Stack

| Layer | Tool | Pinned Version | Confidence |
|-------|------|----------------|------------|
| Dotfile engine | **chezmoi** | 2.70.4 (already current — May 19, 2026 release) | HIGH |
| Secret backend (server) | **VaultWarden** | 1.36.0 | HIGH |
| Secret backend (client) | **Bitwarden CLI (`bw`)** | 2026.4.2 | HIGH |
| Encrypted bootstrap fallback | **age** | latest stable (via chezmoi's built-in age, no separate install needed) | HIGH |
| Runtime/tool manager (non-Windows) | **mise** | 2026.5.15 (via APT for Debian/Ubuntu/WSL) | HIGH |
| Package mgmt (macOS) | **Homebrew** | rolling | HIGH (existing) |
| Package mgmt (Linux/WSL) | **apt + mise** | distro-stable + 2026.5.15 | HIGH |
| Package mgmt (Windows) | **winget** | 1.28.240 (configure command via DSC YAML) | HIGH |
| Shell (Windows) | **PowerShell 7.6.2** (install via winget; do NOT target 5.1) | 7.6.2 | HIGH |
| Prompt | **starship** | 1.25.1 (cross-shell parity Mac/Linux/PowerShell) | HIGH |
| PowerShell line editor | **PSReadLine** | 2.4.5 (bundled with PowerShell 7.6.x; pin in `$PROFILE` install logic) | HIGH |
| Distro userland (WSL) | **Ubuntu 24.04 LTS** (or 26.04 LTS once shipped) | LTS | MEDIUM |

---

## Core Technologies

### chezmoi 2.70.4

**Status:** You are already on the latest stable. No upgrade pressure. 2.70.4 shipped 2026-05-19 with fixes for Linux ARM installs, git-lfs, and template data handling. The 2.70.x line added incremental template ergonomics: `.chezmoi.flags` (2.70.2), `.chezmoi.rawHomeDir` and case-insensitive glob (2.70.1), multiple externals + podman alias (2.70.0). No breaking changes.

**Why it's the right engine:**
- Cross-OS first-class: same binary, same template engine, same source tree drives macOS, Linux, Windows (PowerShell), WSL.
- Built-in age and bitwarden integrations — no glue scripts to maintain.
- `.chezmoiroot`, `.chezmoiexternal.toml`, `.chezmoiscripts/`, `.chezmoidata/`, `.chezmoiignore` are exactly the primitives this project's role × OS × WSL taxonomy needs.
- Active maintenance with monthly+ patch cadence. Single-binary install on every target OS.

**Operational notes for templates:**
- `.chezmoi.os` returns `darwin`, `linux`, `windows`. Use it as the OS axis.
- WSL detection: `(eq .chezmoi.os "linux") (.chezmoi.kernel.osrelease | lower | contains "microsoft")` — chezmoi exposes `.chezmoi.kernel.osrelease` exactly for this.
- Per-OS file naming: `run_once_install-packages.sh.tmpl` and `run_once_install-packages.ps1.tmpl` coexist; each is gated by an `{{ if eq .chezmoi.os "..." }}` guard at the top.

### VaultWarden 1.36.0 + Bitwarden CLI 2026.4.2

**VaultWarden 1.36.0** (2026-05-03) ships with item archiving, OpenID Connect SSO (≥1.35.0), and the web vault updated to 2026.4.1. It is API-compatible with the official `bw` CLI; the only setup wrinkle is pointing the CLI at your self-hosted endpoint before logging in.

**`bw` CLI 2026.4.2** (2026-05-20) is the current release. The 2026.4.2 patch is a security fix for local API-key storage — keep current.

**Self-hosted setup (one-time per machine):**
```bash
bw config server https://vaultwarden.yourdomain.tld
bw login                              # email + master pw + 2FA
export BW_SESSION="$(bw unlock --raw)"  # this is what chezmoi needs
```

**chezmoi ↔ bw glue (verified function signatures):**

| Function | Signature | Returns |
|----------|-----------|---------|
| `bitwarden` | `bitwarden arg...` (args pass to `bw get` unchanged) | parsed JSON of the item |
| `bitwardenFields` | `bitwardenFields arg...` | `fields[]` as a dict keyed by field `name` |
| `bitwardenAttachment` | `bitwardenAttachment FILENAME ITEMID` | raw attachment bytes |
| `bitwardenAttachmentByRef` | `bitwardenAttachmentByRef FILENAME ITEMID FIELDNAME` | attachment looked up by a custom field reference |
| `bitwardenSecrets` | (Bitwarden Secrets Manager — not VaultWarden compatible, **do not use**) | — |

All results are cached per template run, so multiple calls with identical args invoke `bw` once.

**Auto-unlock config (recommended in `~/.config/chezmoi/chezmoi.toml`):**
```toml
[bitwarden]
    unlock = "auto"   # only unlock if BW_SESSION not already set; locks after run
```
This eliminates the need to `export BW_SESSION` manually before `chezmoi apply` while still respecting an existing session if you've already unlocked in your shell.

**Verified usage idioms:**
```gotemplate
# Login credential
password = {{ (bitwarden "item" "ssh-deploy-key").login.password }}

# Custom field (use bitwardenFields for these, not bitwarden)
token = {{ (bitwardenFields "item" "github-pat").token.value }}

# Binary attachment (private SSH key, GPG export, etc.)
{{- bitwardenAttachment "id_ed25519" "personal-github-ssh" -}}
```

**Pitfall:** `bw` does NOT prompt for re-unlock when the session times out — it returns an error and chezmoi fails template rendering. Mitigation: `unlock = "auto"` in config + capture `bw login` errors in the bootstrap script.

### age (via chezmoi built-in)

**You don't need to install age separately.** chezmoi has a built-in age implementation that activates when the `age` command is not on `PATH`. The built-in lacks passphrase/symmetric/SSH-key modes — for the bootstrap-kit use case (X25519 keypair, recipient-encrypted, no passphrase), the built-in is sufficient and one less binary to manage.

**Workflow:**
```bash
chezmoi age-keygen --output=$HOME/key.txt        # generate identity once
chezmoi add --encrypt path/to/secret             # encrypts at add-time
```

Configure once in `~/.config/chezmoi/chezmoi.toml.tmpl`:
```toml
encryption = "age"
[age]
    identity = "{{ .chezmoi.homeDir }}/.config/chezmoi/key.txt"
    recipient = "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"
```

Encrypted files in the source state are stored with a leading `encrypted_` prefix (e.g. `encrypted_dot_ssh/encrypted_id_ed25519`). chezmoi handles encrypt-on-add, decrypt-on-apply transparently.

**Bootstrap-kit pattern for this project:**
1. Generate one age recipient keypair, store the identity (private key) in VaultWarden as an attachment on a `bootstrap-kit-age-identity` item.
2. Encrypt a tiny set of recovery essentials (VaultWarden URL, recovery codes, SSH bootstrap script) to that recipient and commit the ciphertext into the repo.
3. On a fresh machine with no VaultWarden: clone repo + retrieve identity from any out-of-band channel (printed paper backup, password manager export USB, etc.) + `chezmoi apply` decrypts the recovery essentials. From there, manual VaultWarden re-establishment.

**Confidence note:** This is a "belt and suspenders" use case. The mechanism is correct and verified; the operational discipline (where the age identity actually lives during a disaster) is the design surface that needs explicit choice in PROJECT phase 0.

### mise 2026.5.15

**Status:** Latest stable as of 2026-05-23. Already in your zshrc. Use for runtime version pinning (node, python, ruby, go, etc.) on macOS, Linux, and WSL. Functions natively on Windows too (via `winget install jdx.mise` or `scoop`), but on Windows our package mgmt strategy is winget so we keep mise scoped to *nix.

**Install (Debian/Ubuntu/WSL — recommended):**
```bash
sudo install -dm 755 /etc/apt/keyrings
curl -fSs https://mise.en.dev/gpg-key.pub | sudo tee /etc/apt/keyrings/mise-archive-keyring.asc > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.asc] https://mise.en.dev/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/mise.list
sudo apt update && sudo apt install -y mise
```

(For Ubuntu 26.04+, the simpler `ppa:jdxcode/mise` is also available.)

**Global vs project semantics:**
- `mise use --global node@26` — writes to `~/.config/mise/config.toml`, applies to every shell.
- `mise use node@22` (in a project dir) — writes `mise.toml` in that directory, takes precedence over global.
- `mise.toml` and `.tool-versions` (asdf-compat) both work; prefer `mise.toml` for new projects.

**For chezmoi managed config:** template `~/.config/mise/config.toml` and add per-OS runtime pins under `roles.dev.*`. Don't try to manage project-level `mise.toml`s via chezmoi — those belong in each project repo.

### winget 1.28.240 + DSC YAML

**Status:** Latest stable (2026-04-17). The configure command works since 1.6.2631+, so 1.28.x has it well-shaken.

**Configuration is declarative YAML invoked via `winget configure`:**
- File: `winget-configure.yaml` (or whatever path)
- Engine: PowerShell DSC v3 resources, including the `Microsoft.WinGet.DSC` module which provides `WinGetPackage`
- Idempotent: resource ordering doesn't matter — chezmoi-friendly because we'd template the YAML and run `winget configure --file ...` from a `run_onchange_*.ps1.tmpl` script

**Minimal example (templated as `winget-configure.yaml.tmpl`):**
```yaml
# yaml-language-server: $schema=https://aka.ms/configuration-dsc-schema/0.2
properties:
  resources:
    - resource: Microsoft.WinGet.DSC/WinGetPackage
      id: git
      directives:
        description: Install Git
      settings:
        id: Git.Git
        source: winget
    - resource: Microsoft.WinGet.DSC/WinGetPackage
      id: pwsh
      settings:
        id: Microsoft.PowerShell
        source: winget
{{- if eq .role "gaming" }}
    - resource: Microsoft.WinGet.DSC/WinGetPackage
      id: obs
      settings:
        id: OBSProject.OBSStudio
        source: winget
{{- end }}
  configurationVersion: 0.2.0
```

**Why winget configure over a list of `winget install` calls in a `.ps1.tmpl`:**
1. Idempotent — re-running doesn't re-install already-present packages
2. Microsoft's blessed-path; DSC resources beyond `WinGetPackage` (e.g. `DeveloperMode`, registry, fonts since 1.28) give a single declarative surface for OS settings + package installs
3. Native `--accept-source-agreements --accept-package-agreements` handling

**Package ID discovery:** `winget search <name>` then use the `Id` column verbatim. The well-known IDs (`Git.Git`, `Microsoft.PowerShell`, `Microsoft.WindowsTerminal`, `Starship.Starship`, `Bitwarden.CLI`) are stable.

### PowerShell 7.6.2 (NOT 5.1)

**Status:** 7.6.2 shipped 2026-05-21. **Target this exclusively.** Windows 11 still ships with Windows PowerShell 5.1 as `powershell.exe`; PowerShell 7 installs alongside as `pwsh.exe`. PowerShell 7.x is cross-platform, actively developed, includes DSC v3 (needed for `winget configure`), and is what Microsoft's developer-experience tooling assumes in 2026.

**Install via winget (chicken-and-egg note: ships with the OS in some 11 25H2 SKUs but assume it doesn't):**
```powershell
winget install --id Microsoft.PowerShell --source winget
```

**Profile path:** `$PROFILE.CurrentUserAllHosts` resolves to `~\Documents\PowerShell\profile.ps1` (note: `PowerShell\`, not `WindowsPowerShell\` — that's the 5.1 path). chezmoi target: `Documents/PowerShell/profile.ps1` via `dot_documents/powershell/profile.ps1.tmpl` (or use `windows`-specific path resolution).

**5.1 stance:** Don't try to support it. Microsoft has been clear that 5.1 is in maintenance mode and 7.x is the forward path. Targeting both doubles the surface area for zero practical gain in this fleet (all your Windows machines are Windows 11).

### starship 1.25.1

**Status:** Latest stable (2026-04-30). Cross-shell prompt — same `~/.config/starship.toml` works for zsh (macOS, Linux), bash (Linux/WSL fallback), and PowerShell (Windows).

**Init lines:**
- zsh (`.zshrc`): `eval "$(starship init zsh)"`
- bash (`.bashrc`): `eval "$(starship init bash)"`
- PowerShell (`$PROFILE`): `Invoke-Expression (&starship init powershell)`

**Install:**
- macOS: `brew install starship`
- Linux/WSL: `curl -sS https://starship.rs/install.sh | sh` (or via mise: `mise use --global starship@1.25.1`)
- Windows: `winget install --id Starship.Starship`

### PSReadLine 2.4.5

**Status:** 2.4.5 shipped 2025-10-22; remains current as of May 2026. **Bundled with PowerShell 7.6.x out of the box** — you do not need to install it for parity. Pin/upgrade only if you want predictive IntelliSense tweaks beyond the bundled version.

**Recommended profile snippet** (for prediction + history-based completions matching zsh-autosuggestions feel):
```powershell
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
```

### WSL 2 — Ubuntu 24.04 LTS

**Recommended distro:** Ubuntu 24.04 LTS. (26.04 LTS lands later in 2026; if available at execution time, prefer it for the longer support tail and matching `ppa:jdxcode/mise` ergonomics.)

**`/etc/wsl.conf` (per-distro, templated as `dot_etc/wsl.conf.tmpl` and applied with elevation):**
```ini
[boot]
systemd=true

[automount]
enabled=true
options="metadata,umask=22,fmask=11"

[interop]
enabled=true
appendWindowsPath=false       # critical: keep Windows %PATH% out of Linux $PATH

[user]
default=teague

[network]
generateResolvConf=true
```

**`%USERPROFILE%\.wslconfig` (Windows-side, global to the WSL VM):**
```ini
[wsl2]
memory=16GB                    # tune to host RAM; ~50% is the WSL default which is often too much
processors=8
swap=8GB
localhostForwarding=true
networkingMode=mirrored        # Win11 22H2+; nicer than NAT for dev workflows

[experimental]
autoMemoryReclaim=gradual
sparseVhd=true                 # auto-shrink the VHD as files are deleted
```

**Operational pitfall:** `wsl.conf` only re-reads after the distro fully shuts down (8-second rule). `.wslconfig` requires `wsl --shutdown` of the entire VM. Document this in install scripts so first-apply doesn't appear to silently fail.

---

## Supporting Tools

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| **GitHub CLI (`gh`)** | latest | PAT-less GitHub operations once authenticated | Bootstrap: HTTPS clone of private dotfiles repo without juggling raw PATs |
| **Windows Terminal** | latest (via Microsoft Store or `winget install Microsoft.WindowsTerminal`) | Default terminal host for pwsh + WSL | All Windows hosts |
| **age** binary (optional) | latest | Symmetric / passphrase / SSH-key encryption beyond chezmoi built-in | Skip unless you need passphrase mode for the bootstrap kit |
| **direnv** (optional) | latest | Per-project env loading | If projects need env vars not covered by mise |
| **OpenSSH client** | OS-bundled | Day-1 git over ssh | Pre-installed everywhere we care about |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **Nix / home-manager** | No native Windows support. Mac/Linux-only ecosystem disqualifies it for this fleet by definition. | chezmoi (which is what you're already on) |
| **Linux Homebrew** | Already ruled out in PROJECT.md. Adds a second package manager on Linux with poor distro integration, slow installs, and no real cross-OS command parity benefit (zsh setup is the only shared command surface, and that's a `.zshrc` concern not a package manager concern). | apt + mise |
| **Bitwarden Secrets Manager (`bitwardenSecrets` template fn)** | VaultWarden doesn't implement the Bitwarden Secrets Manager API — it's a separate cloud product. Templates using `bitwardenSecrets` will fail against VaultWarden. | `bitwarden`, `bitwardenFields`, `bitwardenAttachment` only |
| **`rbw` (Rust Bitwarden CLI) template fns** | Adds an extra CLI to install and manage; the official `bw` CLI works fine against VaultWarden and is what chezmoi docs lead with. | Stick with `bw` |
| **Windows PowerShell 5.1** | Maintenance mode. No DSC v3. No cross-platform parity. Forces dual profile paths. Forces older syntax constraints in shared scripts. | PowerShell 7.6.x exclusively |
| **Chocolatey on Windows** | winget is now the Microsoft-blessed path with first-class DSC integration. Choco still works but adds a third package surface (winget + Store + choco) for zero gain. | winget + (Store only when a vendor doesn't ship to winget) |
| **Scoop on Windows** | Same reasoning as Chocolatey. Fine tool, but pointless second package manager when winget covers your install set. | winget |
| **MSYS2 / Git Bash on Windows for shell parity** | Tempting trap — gives you a *nix-shaped shell on Windows but doesn't integrate with WSL filesystem, doesn't give real systemd, and you still need PowerShell for Windows-native tasks. Two half-shells is worse than two whole shells. | pwsh on Windows host, zsh-in-WSL when you want *nix |
| **`oh-my-posh`** | Functionally overlaps starship; starship gives you a single config across all four OSes. Don't run both. | starship |
| **`pyenv`, `nvm`, `rbenv`, `goenv` independently** | All replaced by mise. Running these alongside mise causes PATH shadowing headaches. | mise |
| **GPG agent per-machine key generation** | PROJECT.md already retires `generate-gpg-key.sh`. One canonical signing key, distributed via VaultWarden, lets every machine sign as "you" from minute one. | Canonical GPG key pulled via `bitwardenAttachment` |

---

## Stack Patterns by Variant

### If `role = dev` and `os = darwin`
- Package mgmt: Homebrew (existing); `Brewfile` continues to work
- Shell: zsh + starship + oh-my-zsh (existing external)
- Runtimes: mise
- Secrets: `bw` CLI + chezmoi `bitwarden*` functions

### If `role = dev` and `os = linux` (including WSL)
- Package mgmt: apt for system packages; mise for runtimes
- Shell: zsh + starship + oh-my-zsh; install zsh via apt
- Bootstrap: `run_once_before_*-install-apt-packages.sh.tmpl` runs apt installs idempotently
- WSL extra: `/etc/wsl.conf` templated and copied with sudo

### If `role = gaming` and `os = windows`
- Package mgmt: `winget configure` via templated DSC YAML
- Shell: PowerShell 7.6.x + starship + PSReadLine; profile at `Documents/PowerShell/profile.ps1`
- Stream Deck assets: synced into `%APPDATA%\Elgato\StreamDeck\ProfilesV2\` via chezmoi targeting `AppData/Roaming/...`
- Manual surface: drivers, NVIDIA Control Panel, audio routing — explicitly out of scope per PROJECT.md

### If `role = lite` and `os = windows`
- Package mgmt: winget DSC YAML with minimal resource list (Browser, Office, Bitwarden desktop, PicPick)
- No PowerShell profile customization beyond the minimum (lite = lite)
- Manual: vendor `.msi` installs noted in a README, not automated

---

## Version Compatibility & Pitfalls

| Combination | Notes |
|-------------|-------|
| chezmoi 2.70.x + bw CLI 2026.4.x | Verified working; `bitwarden.unlock = "auto"` requires bw on PATH at template-render time |
| chezmoi built-in age + age CLI on PATH | Built-in is used only if `age` binary absent. Installing the standalone binary silently switches chezmoi to it — be aware if behavior changes |
| VaultWarden 1.36.0 + bw CLI 2026.4.2 | `bw config server` must be run before first `bw login`; if you change servers, `bw logout` first |
| PowerShell 7.6.x + PSReadLine | 2.4.5 bundled; do not `Install-Module PSReadLine -Force` unless you intentionally want a newer Gallery version |
| winget configure + PowerShell 7 | DSC v3 resources require PowerShell 7; don't try to run `winget configure` from 5.1 |
| mise on WSL with `appendWindowsPath=false` | Required combination — if Windows `%PATH%` leaks in, Windows-side `node.exe`/`python.exe` can shadow mise's shims and produce confusing "wrong version" errors |
| Cloudflare tunnel + VaultWarden + bw CLI | Long-lived `bw sync` calls have hit Cloudflare's 100-second free-tier timeout in the past; if you see HTTP 524s, switch to running `bw sync` interactively or move sync off the tunnel |

---

## Sources

| Source | Topic | Confidence |
|--------|-------|------------|
| https://github.com/twpayne/chezmoi/releases (2.70.4, 2026-05-19) | chezmoi current version + 2.70.x feature deltas | HIGH |
| https://www.chezmoi.io/reference/templates/bitwarden-functions/ | `bitwarden*` template fn signatures and `bitwarden.unlock` config | HIGH |
| https://www.chezmoi.io/user-guide/encryption/age/ | age integration workflow, built-in fallback, recipient/identity config | HIGH |
| https://github.com/jdx/mise/releases (2026.5.15, 2026-05-23) | mise current version | HIGH |
| https://mise.jdx.dev/installing-mise.html | mise APT install for Debian/Ubuntu/WSL, Windows native support | HIGH |
| https://learn.microsoft.com/en-us/windows/package-manager/configuration/ | winget configure DSC YAML schema and behavior | HIGH |
| https://github.com/microsoft/winget-cli/releases (1.28.240, 2026-04-17) | winget current version | HIGH |
| https://github.com/dani-garcia/vaultwarden/releases (1.36.0, 2026-05-03) | VaultWarden current version + feature notes | HIGH |
| https://github.com/bitwarden/clients/releases (CLI 2026.4.2, 2026-05-20) | bw CLI current version and security fix | HIGH |
| https://github.com/PowerShell/PowerShell/releases (7.6.2, 2026-05-21) | PowerShell 7 current stable | HIGH |
| https://github.com/PowerShell/PSReadLine/releases (2.4.5, 2025-10-22) | PSReadLine current version | HIGH |
| https://github.com/starship/starship/releases (1.25.1, 2026-04-30) | starship current version | HIGH |
| https://starship.rs/guide/ | PowerShell init line: `Invoke-Expression (&starship init powershell)` | HIGH |
| https://learn.microsoft.com/en-us/windows/wsl/wsl-config (updated 2025-12) | Full `/etc/wsl.conf` and `.wslconfig` reference incl. systemd, mirrored networking, autoMemoryReclaim, sparseVhd | HIGH |
| https://contributing.bitwarden.com/getting-started/clients/cli/ | `bw config server` syntax for self-hosted | MEDIUM (the contributing docs cover config server; the login/unlock loop is well-documented but on the user-help portal, not pulled directly) |

---
*Stack research for: multi-OS dotfile management with VaultWarden-backed secrets*
*Researched: 2026-05-27*
