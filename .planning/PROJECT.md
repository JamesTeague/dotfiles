# chezmoi Modernization

## What This Is

Extension and modernization of Teague's chezmoi dotfiles repository to natively cover a multi-OS fleet (Mac, Linux, WSL, native Windows) with a clean role-based taxonomy. Replaces the current `personal` boolean + organic OS-nesting structure with explicit roles (`dev` / `gaming` / `lite`) × `personal` flag × auto-detected OS + WSL flag. Adds Windows-native support, VaultWarden-integrated secret management, and a structured migration plan.

## Core Value

A new machine — any OS in the fleet — can be set up day-1 via a single `chezmoi init --apply` flow (plus VaultWarden login + GitHub PAT for HTTPS clone bootstrap) and arrive at a fully-configured, identity-signed, role-appropriate state without artisanal touch-up.

## Requirements

### Validated

(None yet — initial scope for this modernization)

### Active

- [ ] 3-role taxonomy (`dev` / `gaming` / `lite`) implemented in `.chezmoi.toml.tmpl`
- [ ] `personal` flag orthogonal to role
- [ ] OS auto-detection works on darwin / linux / windows
- [ ] WSL auto-detection works as flag
- [ ] `packages.yaml` restructured around `roles.<role>.<os>` + `overlays.personal.<os>`
- [ ] Existing Mac personal + Mac work machines produce no functional diff after refactor
- [ ] Audit pass complete (dead packages removed, `dot_topics/` documented, structure normalized, orphaned flameshot config dropped)
- [ ] VaultWarden integration via chezmoi `bitwarden`/`bitwardenAttachment` template functions
- [ ] Per-purpose SSH key strategy (personal-github, work-github at minimum; optional personal-homelab)
- [ ] Canonical GPG key pulled from VaultWarden enables "sign commits to GitHub from day 1"
- [ ] Linux package management uses apt + mise (NOT Linux Homebrew)
- [ ] Windows host support: PowerShell profile (lightweight starship + PSReadLine parity), winget package management, install scripts as `.ps1.tmpl`
- [ ] role=gaming on Windows host (gaming rig) — full streaming/gaming software install list
- [ ] Stream Deck profile management at `%APPDATA%\Elgato\StreamDeck\ProfilesV2\`
- [ ] role=dev on Linux including WSL (greenfield setup, replacing abandoned-broken state on gaming rig)
- [ ] WSL accommodations: `/etc/wsl.conf` settings (automount metadata, interop appendWindowsPath=false, default user, systemd), `%USERPROFILE%\.wslconfig` for resource limits on Windows host
- [ ] role=lite (spiral index laptop) with minimal install (browser, Office, Bitwarden, PicPick + manual vendor .msi)
- [ ] Lonestar onboarding pattern (whatever OS) — applies established patterns to new machine
- [ ] Session 59 Claude Code integration folded in (settings.json.tmpl + ~/dev/CLAUDE.md, gated by personal flag)
- [ ] Bootstrap kit fallback design (age-encrypted recovery essentials in repo for "VaultWarden unreachable, must bootstrap NOW" scenario)
- [ ] Cross-OS screenshot tool coverage: Shottr (Mac), PicPick (Windows), Flameshot kept and gated to `role=dev + os=linux`

### Out of Scope

- **Unraid homelab management** — appliance OS configured via Web UI, persistence on USB; Unraid's native flash backup is the right primitive, not chezmoi
- **OBS scenes/assets management** — deferred to separate sub-project (assets currently scattered between Mac and gaming rig, needs cleanup + portability redesign first before chezmoi can manage)
- **Forgejo migration / leaving GitHub** — deferred to separate investigation sub-project (Codeberg vs self-host vs stay GitHub)
- **Git setup scripts comprehensive review** — flagged for separate review sub-project (overlaps with Phase 0 retiring generate-gpg-key.sh anyway)
- **Driver installs, BIOS, GPU OC, NVIDIA Control Panel settings, audio device routing, display setup, taskbar pinning** — Windows-side manual touches that can't be automated meaningfully
- **Linux Homebrew on WSL/Linux machines** — apt + mise is the chosen alternative; brew commands not load-bearing for daily shell parity

## Context

### Existing repo baseline
- Source: `~/.local/share/chezmoi`, 93 files, 5.7MB, alive
- `.chezmoiroot = ./home/`; standard chezmoi layout (`.chezmoidata/packages.yaml`, `.chezmoiscripts/`, `.chezmoitemplates/`, `.chezmoiexternal.toml` for oh-my-zsh + tpm)
- Custom convention: `dot_topics/<tool>/` organization layer with `path.zsh`, `eval.zsh`, `config.zsh`, `install.sh` files loaded by zshrc — smart but undocumented
- Current taxonomy: `personal` boolean only, packages.yaml branches `core/darwin/linux + personal/work` with inconsistent nesting depth
- Remote: `git@github.com:JamesTeague/dotfiles.git` (now private as of 2026-05-27)
- chezmoi 2.70.4
- `keyboard/` lives at repo root outside `.chezmoiroot` (VIA layout files, not chezmoi-source)

### Fleet inventory

| Machine | role | personal | os | wsl | Status |
|---------|------|----------|-----|------|--------|
| Mac personal (current MBP) | dev | ✓ | darwin | — | Active, on chezmoi |
| Mac work (current) | dev | ✗ | darwin | — | Active, on chezmoi |
| Lonestar (TBD OS) | dev | ✗ | auto | — | Anticipated |
| Gaming rig (Windows host) | gaming | ✓ | windows | — | Active, artisanal — to onboard |
| WSL on gaming rig | dev | ✓ | linux | ✓ | Broken/abandoned — to greenfield |
| Spiral index laptop | lite | ✗ | windows | — | Artisanal — to onboard |
| Future Linux laptop (speculative) | dev | tbd | linux | — | Hypothetical |

### Why now
- Lonestar job offer = potential new machine incoming; day-1 turnkey setup is the forcing function
- Native Windows machines (gaming rig, spiral index) currently artisanal because Teague didn't know how to extend chezmoi to Windows
- WSL on gaming rig is broken/abandoned, blocking dev work there
- Templating friction (Go templates) tolerable; Nix evaluated and rejected upfront (no native Windows support)

### Prior session work (folded in)
Session 59 (2026-03-19, ember `a266824b`) decided to add Claude Code config to chezmoi: `settings.json.tmpl` (templated hook paths) + `~/dev/CLAUDE.md`, gated by `{{ if not .personal }}` in `.chezmoiignore`. GSD files explicitly excluded (own installer). Memory files excluded (rebuild naturally). Execution was deferred. Folds into Phase 0 of this modernization naturally — no separate workstream.

### Tracked follow-up sub-projects (separate workstreams)
- **OBS cleanup** — consolidate scattered scenes/assets, make portable across Mac + gaming rig
- **Forgejo migration investigation** — Codeberg vs self-host vs stay GitHub
- **Git setup scripts review** — comprehensive audit beyond Phase 0's automatic retirement of `generate-gpg-key.sh`
- **Bootstrap kit fallback design** — age-encrypted recovery essentials (could land in Phase 0 or as standalone)

### Tracked lookups (Teague will confirm during execution)
- Social Stream Ninja install path on Windows (may be full Electron app, not browser source)
- WezTerm Windows config status — does existing cross-platform config Just Work
- Microsoft Office license type — M365 subscription vs perpetual

## Constraints

- **Tech stack**: chezmoi 2.70.4. Go templates. Bash (.sh.tmpl) on *nix, PowerShell (.ps1.tmpl) on Windows.
- **Repo**: GitHub private repo. SSH-remote for routine operations; HTTPS+PAT for initial clone on new machines (chicken-and-egg on SSH keys).
- **Migration safety**: Existing active machines (Mac personal, Mac work) must keep working through migration — no broken-mid-state window allowed. `chezmoi diff` is the per-machine validation gate.
- **Bootstrap dependency**: VaultWarden self-hosted on Unraid via Cloudflare tunnel = single point of failure for routine `chezmoi apply`. Mitigated by bootstrap-kit fallback (age-encrypted recovery essentials in repo).
- **Multi-OS**: Must natively cover macOS, Linux, native Windows, and WSL. Disqualifies Nix and other Linux-centric tooling.
- **Personal vs Work isolation**: Claude Code config, personal entertainment apps, and personal-only tools must NOT appear on work machines. `personal` flag is load-bearing for `.chezmoiignore` gating.
- **File limit**: chezmoi templates can be hairy; keep individual `.tmpl` files reasonably scoped. Refactor anything that exceeds ~200 lines of template logic.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Stay on chezmoi (vs Nix) | Native Windows in fleet; Nix has no native Windows support; chezmoi is one of few tools that covers all OSes | — Pending |
| 3-role taxonomy (dev/gaming/lite) | Captures purpose orthogonal to personal/work; clean enough for current fleet, extensible | — Pending |
| `personal` as orthogonal flag (not absorbed into role) | Work-issued dev machine ≠ personal dev machine despite same role | — Pending |
| VaultWarden via Cloudflare + chezmoi `bitwarden*` template fns | Self-hosted sovereignty with public-internet reachability; premium-tier features free via VaultWarden | — Pending |
| Per-purpose SSH keys (personal-github + work-github min) | Rotation hygiene, clean off-boarding when leaving jobs, smaller blast radius if a key leaks | — Pending |
| Canonical GPG (vs per-machine generate) | Enables "sign commits to GitHub from day 1"; GitHub knows the one key; retires `generate-gpg-key.sh` | — Pending |
| Linux pkg mgmt: apt + mise (not Linux brew) | mise already in zshrc (commit `887c2a2`); cross-OS command parity not load-bearing for daily shell time | — Pending |
| Hybrid migration: Phase 0 refactor branch → additive phases | Atomic structural change with `chezmoi diff` safety net; additive phases ship independently without cross-blockers | — Pending |
| Repo private (was public) | Unlocks BW flexibility, work-config inclusion, encrypted bootstrap kit option | ✓ Good |
| Unraid homelab dropped from chezmoi scope | Appliance OS configured via Web UI; chezmoi doesn't fit; Unraid's flash backup is the right primitive | — Pending |
| OBS cleanup carved as separate sub-project | Cross-role asset surface scattered between Mac and gaming rig; needs portability redesign before chezmoi management | — Pending |
| Bootstrap kit fallback (age-encrypted in repo) | Belt-and-suspenders for "VaultWarden unreachable, must bootstrap NOW" disaster recovery | — Pending |

---
*Last updated: 2026-05-27 after initialization (discussion-first design session preceded)*
