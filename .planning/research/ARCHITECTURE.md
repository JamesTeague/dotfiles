# Architecture Research

**Domain:** chezmoi dotfiles repo, multi-OS fleet, role-based config
**Researched:** 2026-05-27
**Confidence:** HIGH (sourced from official chezmoi docs + multi-OS practitioner write-ups)

> Scope: this document covers the structural shape of a well-designed multi-OS chezmoi repo, the apply-time data flow, the package-manifest restructure target, and the migration build order for Phase 0.5 → Phase 4 of the modernization. It is opinionated — "do X because Y", not "consider X or Y or Z."

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                          chezmoi source repo                          │
│                                                                       │
│  ┌────────────────────┐    ┌──────────────────────────────────────┐  │
│  │ .chezmoiroot       │    │ home/                                │  │
│  │ ("home")           │───▶│   (source state root)                │  │
│  └────────────────────┘    └──────────────────────────────────────┘  │
│                                              │                        │
│  ┌─────────────────────────────────────┐    │                        │
│  │ STATIC DATA (loaded pre-template)   │◀───┤                        │
│  │  .chezmoidata/                      │    │                        │
│  │    packages.yaml                    │    │                        │
│  │    roles.yaml                       │    │                        │
│  └─────────────────────────────────────┘    │                        │
│                                              │                        │
│  ┌─────────────────────────────────────┐    │                        │
│  │ ROOT CONFIG TEMPLATE                │◀───┤                        │
│  │  .chezmoi.toml.tmpl                 │    │                        │
│  │  → prompts: personal/role/name/...  │    │                        │
│  │  → autodetects: os/arch/wsl         │    │                        │
│  │  → writes ~/.config/chezmoi/        │    │                        │
│  │           chezmoi.toml [data]       │    │                        │
│  └─────────────────────────────────────┘    │                        │
│                                              │                        │
│  ┌─────────────────────────────────────┐    │                        │
│  │ GATING                              │◀───┤                        │
│  │  .chezmoiignore  (templated)        │    │                        │
│  │  → per-OS / per-role exclusions     │    │                        │
│  └─────────────────────────────────────┘    │                        │
│                                              │                        │
│  ┌─────────────────────────────────────┐    │                        │
│  │ TARGET-STATE ENTRIES                │◀───┤                        │
│  │  dot_*.tmpl, private_, executable_  │    │                        │
│  │  dot_topics/<tool>/...              │    │                        │
│  │  dot_config/<app>/...               │    │                        │
│  └─────────────────────────────────────┘    │                        │
│                                              │                        │
│  ┌─────────────────────────────────────┐    │                        │
│  │ EXTERNALS                           │◀───┤                        │
│  │  .chezmoiexternal.toml              │    │                        │
│  │  → oh-my-zsh, tpm, etc.             │    │                        │
│  └─────────────────────────────────────┘    │                        │
│                                              │                        │
│  ┌─────────────────────────────────────┐    │                        │
│  │ SHARED PARTIALS                     │◀───┤                        │
│  │  .chezmoitemplates/                 │    │                        │
│  │  → includeTemplate "git-signing" .  │    │                        │
│  └─────────────────────────────────────┘    │                        │
│                                              │                        │
│  ┌─────────────────────────────────────┐    │                        │
│  │ SCRIPTS                             │◀───┘                        │
│  │  .chezmoiscripts/                   │                             │
│  │    common/                          │                             │
│  │    darwin/   run_onchange_*.sh.tmpl │                             │
│  │    linux/    run_onchange_*.sh.tmpl │                             │
│  │    windows/  run_onchange_*.ps1.tmpl│                             │
│  └─────────────────────────────────────┘                             │
└──────────────────────────────────────────────────────────────────────┘
                              │
                              │  chezmoi apply
                              ▼
┌──────────────────────────────────────────────────────────────────────┐
│                       Destination ($HOME / %USERPROFILE%)             │
│   ~/.zshrc        ~/.gitconfig    ~/.ssh/config    ~/.topics/...      │
│   ~/.config/...   ~/AppData/...   %APPDATA%/Elgato/StreamDeck/...     │
└──────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────────┐
│  chezmoi STATE (boltdb at ~/.local/share/chezmoi/chezmoistate.boltdb) │
│   tracks: run_once content hashes, run_onchange hashes per filename,  │
│           external refresh timestamps, entryState                     │
└──────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Implementation |
|-----------|----------------|----------------|
| `.chezmoiroot` | Names the subdir holding the source state. Read FIRST, before everything else. | One-line file containing `home`. Cannot be a template. |
| `.chezmoi.toml.tmpl` | One-time prompts + auto-detection. Writes `~/.config/chezmoi/chezmoi.toml`. Becomes the `data` namespace on subsequent applies. | Go template. Uses `promptBoolOnce` / `promptStringOnce` / `promptChoiceOnce`. |
| `.chezmoidata/*.yaml` | Static structured data. Loaded BEFORE template engine. All files merge to root data dict in lexical order. | Plain YAML/TOML/JSON. **Cannot be templates.** |
| `.chezmoiignore` | Decides which source entries are excluded from this machine's target. Re-evaluated every apply. | Templated (even without `.tmpl`). Negation supported (`!path`), excludes always win. |
| `.chezmoiexternal.toml` | Declares external archives/files (oh-my-zsh, tpm). Refreshed on `refreshPeriod`. Applied DURING the update phase. | Plain TOML (also templatable as `.chezmoiexternal.toml.tmpl`). |
| `.chezmoitemplates/<name>` | Reusable template partials called via `{{ template "name" . }}` or `includeTemplate "name" .`. | Plain text; not files in the target state. |
| `.chezmoiscripts/` | Scripts that run during apply but do NOT produce target files. Used for package installs, system tweaks. | `run_[once|onchange]_[before|after]_NN-name.{sh,ps1}.tmpl` |
| `dot_*` / `private_*` / `executable_*` entries | Target-state files. Prefix grammar encodes attributes; `.tmpl` suffix opts into templating. | Source-state files mirroring target structure. |
| Per-machine `chezmoi.toml` | Persisted data answers; the `data` table is the second layer of variables visible to all templates. | Auto-written by `.chezmoi.toml.tmpl` on `chezmoi init`. |
| `chezmoistate.boltdb` | Tracks run_once/run_onchange hashes and external refresh times. Local to the machine. | BoltDB; chezmoi-internal, do not edit. |

## Recommended Project Structure

The target layout below is **post-Phase-0 refactor** — everything additive in Phases 1-4 plugs into it without further structural change.

```
~/.local/share/chezmoi/                  # repo root
├── .chezmoiroot                          # "home"
├── README.md                             # human-facing; not in source state
├── docs/                                 # convention guide, dot_topics primer
│   ├── conventions.md
│   └── dot_topics.md
├── keyboard/                             # VIA layouts, outside .chezmoiroot
└── home/                                 # source state root
    ├── .chezmoi.toml.tmpl                # root config: prompts + autodetect
    ├── .chezmoiignore                    # TEMPLATED: per-OS/role gating
    ├── .chezmoiexternal.toml             # oh-my-zsh, tpm, etc.
    │
    ├── .chezmoidata/                     # static data, loaded first
    │   ├── packages.yaml                 # roles.<role>.<os>, overlays.personal.<os>
    │   └── roles.yaml                    # role metadata (allowed OSes, descriptions)
    │
    ├── .chezmoitemplates/                # reusable partials
    │   ├── git-signing                   # GPG block shared by ~/.gitconfig variants
    │   ├── ssh-host                      # per-purpose SSH host stanza
    │   └── package-install-darwin        # brew-bundle render
    │
    ├── .chezmoiscripts/                  # apply-time actions, no target files
    │   ├── common/
    │   │   └── run_onchange_before_00-bootstrap-mise.sh.tmpl
    │   ├── darwin/
    │   │   ├── run_onchange_before_10-install-brew.sh.tmpl
    │   │   ├── run_onchange_20-install-packages.sh.tmpl
    │   │   └── run_onchange_30-install-mas.sh.tmpl
    │   ├── linux/
    │   │   ├── run_onchange_before_10-install-apt.sh.tmpl
    │   │   └── run_onchange_20-install-mise-tools.sh.tmpl
    │   └── windows/
    │       ├── run_onchange_before_10-install-winget.ps1.tmpl
    │       └── run_onchange_20-install-packages.ps1.tmpl
    │
    ├── dot_zshrc.tmpl                    # loads dot_topics/*
    ├── dot_bashrc.tmpl
    ├── dot_gitconfig.tmpl                # includes .chezmoitemplates "git-signing"
    ├── dot_tmux.conf.tmpl
    │
    ├── dot_config/                       # XDG configs (*nix)
    │   ├── ghostty/
    │   ├── wezterm/
    │   ├── starship.toml.tmpl
    │   ├── aerospace/                    # darwin-only; gated in .chezmoiignore
    │   ├── flameshot/                    # role=dev + os=linux; gated in .chezmoiignore
    │   └── claude/                       # personal-only; gated in .chezmoiignore
    │
    ├── dot_ssh/
    │   ├── config.tmpl                   # composes per-purpose host blocks
    │   ├── private_id_personal-github.tmpl   # bitwarden-sourced
    │   └── private_id_work-github.tmpl       # bitwarden-sourced (work only)
    │
    ├── dot_topics/                       # convention: per-tool config bundle
    │   ├── README.md                     # documents the convention
    │   ├── git/
    │   │   ├── path.zsh
    │   │   ├── completion.zsh
    │   │   └── config.zsh
    │   ├── mise/
    │   │   ├── path.zsh
    │   │   └── eval.zsh
    │   └── ...
    │
    ├── private_dot_gnupg/                # GPG seed; bitwardenAttachment
    │   └── private_pubring.kbx
    │
    ├── AppData/                          # Windows-only; gated in .chezmoiignore
    │   ├── Local/Microsoft/WindowsTerminal/settings.json.tmpl
    │   ├── Roaming/Code/User/settings.json.tmpl
    │   ├── Roaming/Elgato/StreamDeck/ProfilesV2/
    │   └── Local/Packages/.../profile.ps1.tmpl
    │
    ├── etc/                              # WSL only (root-target paths)
    │   └── wsl.conf.tmpl                 # via sudo apply or seed-script pattern
    │
    └── bootstrap/                        # bootstrap-kit fallback
        ├── encrypted_essentials.age      # age-encrypted recovery payload
        └── run_once_recover.sh.tmpl      # only when role=lite OR --force-bootstrap
```

### Structure Rationale

- **`home/` as `.chezmoiroot`** — Frees the repo root for README, docs, `keyboard/`, install bootstraps, and CI without chezmoi mistaking them for dotfiles. Already in place; carries forward.
- **`.chezmoidata/` split into multiple files** — `packages.yaml` for fleet-wide gated package data, `roles.yaml` for role metadata. They merge at root in lexical order, so name them deliberately. Keep each under a few hundred KB; chezmoi parses everything every apply.
- **`.chezmoiscripts/` partitioned by OS subdir** — Subdirs aren't magic but make the file tree readable. Combined with `.chezmoiignore` gating (`{{ if ne .chezmoi.os "darwin" }}.chezmoiscripts/darwin/**{{ end }}`), only the active OS's scripts even exist on disk. Numeric prefixes (10/20/30) inside each OS provide deterministic ordering without colliding across OSes.
- **`dot_topics/<tool>/` retained** — Already proven in the repo, but currently undocumented. Phase 0.5 adds the README documenting `path.zsh` / `eval.zsh` / `completion.zsh` / `config.zsh` semantics. This is *Teague's* convention, not chezmoi-blessed — chezmoi has no opinion about per-tool grouping. Document it so future-self and AI collaborators don't have to reverse-engineer.
- **`.chezmoitemplates/` for cross-file partials** — GPG signing block, per-purpose SSH host stanza, brew-bundle renderer. Cuts duplication for blocks that appear in more than one target file.
- **`AppData/` mirrors Windows layout literally** — chezmoi follows the source tree to compute the target. Files under `AppData/Local/.../foo` apply to `%LOCALAPPDATA%/.../foo` via `~/AppData/Local/...` on Windows (since `~` is `%USERPROFILE%`). Stage the literal Windows layout under `home/AppData/`.
- **`bootstrap/`** — The age-encrypted recovery kit. Lives in the source tree (private repo unlocks this), gated to only run when VaultWarden is unreachable. The age identity itself stays out of the repo (recovered from a printed/offline backup).

## Architectural Patterns

### Pattern 1: Data-driven package manifest

**What:** Single source of truth for packages is a structured YAML keyed by `roles.<role>.<os>` and `overlays.personal.<os>`. Templates and install scripts iterate the relevant subtree.

**When to use:** Always, for managed packages. Avoids the current shape where the same tool can be in `core` (everywhere) or `darwin.casks` (one OS) or `work.core.brews` (work-only) with no consistent axis.

**Trade-offs:**
- Pro: One file to scan for "what does this machine install?"; trivially diff-able.
- Pro: Install scripts become content-driven — change a list, hash changes, `run_onchange_` re-runs.
- Con: Sprig templating over deep YAML can get noisy; mitigate with `.chezmoitemplates/` partials.

**Target shape:**

```yaml
# .chezmoidata/packages.yaml
packages:
  roles:
    dev:
      darwin:
        taps:    ['anomalyco/tap', 'jesseduffield/lazygit']
        brews:   ['neovim', 'ripgrep', 'fzf', 'gh', 'mise', ...]
        casks:   ['ghostty', 'wezterm', 'docker-desktop']
      linux:
        apt:     ['build-essential', 'curl', 'git', 'xclip']
        mise:    ['node@lts', 'python@3.12', 'go@latest']
      windows:
        winget:  ['Microsoft.WindowsTerminal', 'JanDeDobbeleer.OhMyPosh']
    gaming:
      windows:
        winget:  ['Valve.Steam', 'Discord.Discord', 'OBSProject.OBSStudio']
    lite:
      windows:
        winget:  ['Mozilla.Firefox', 'Bitwarden.Bitwarden', 'NGWIN.PicPick']
  overlays:
    personal:
      darwin:
        casks: ['arc', 'microsoft-office', 'utm']
        brews: ['ollama']
        mas:
          - {name: 'Final Cut Pro', id: 424389933}
      windows:
        winget: ['Mullvad.MullvadVPN']
    work:
      darwin:
        taps:    ['snyk/tap', 'localstack/tap']
        brews:   ['awscli', 'localstack-cli', 'stern', 'sqlc', 'dotnet@8']
        casks:   ['postman', 'microsoft-teams']
```

**Consumption (install script template):**

```sh
# .chezmoiscripts/darwin/run_onchange_20-install-packages.sh.tmpl
#!/bin/bash
set -euo pipefail
{{- $role := .role }}
{{- $os := .chezmoi.os }}
{{- $rolePkgs := index .packages.roles $role $os }}
{{- $overlay := dict }}
{{- if .personal }}{{ $overlay = index .packages.overlays.personal $os }}{{ end }}
{{- if not .personal }}{{ $overlay = index .packages.overlays.work $os }}{{ end }}

brew bundle --no-lock --file=/dev/stdin <<EOF
{{- range $rolePkgs.taps }}
tap "{{ . }}"
{{- end }}
{{- range $overlay.taps }}
tap "{{ . }}"
{{- end }}
{{- range $rolePkgs.brews }}
brew "{{ . }}"
{{- end }}
{{- range $overlay.brews }}
brew "{{ . }}"
{{- end }}
{{- range $rolePkgs.casks }}
cask "{{ . }}"
{{- end }}
{{- range $overlay.casks }}
cask "{{ . }}"
{{- end }}
EOF
```

Because the script is `run_onchange_`, chezmoi only re-runs it when the rendered content changes — which only happens when `packages.yaml` (or the role/os/personal facts) change.

### Pattern 2: Two-layer gating (`.chezmoiignore` first, in-file `{{ if }}` second)

**What:** Use `.chezmoiignore` to exclude *whole files or subtrees* by OS/role/personal. Use in-file conditionals only for *within-file* deltas.

**When to use:** If a file is irrelevant on this machine, ignore it. If a file is relevant everywhere but one section differs, conditional it.

**Trade-offs:**
- Pro: `.chezmoiignore` produces a smaller target footprint and lets you scan `chezmoi managed` to see what actually applies here.
- Pro: Files don't appear partially rendered or broken on machines that shouldn't see them.
- Con: One more file to maintain. Mitigated by keeping `.chezmoiignore` as the single gating decision point.

**Example:**

```gotmpl
# .chezmoiignore  (interpreted as a template — no .tmpl needed)

# OS-gated subtrees
{{- if ne .chezmoi.os "darwin" }}
dot_config/aerospace/**
{{- end }}
{{- if ne .chezmoi.os "windows" }}
AppData/**
{{- end }}
{{- if or (ne .chezmoi.os "linux") (and .wsl true) }}
dot_config/flameshot/**
{{- end }}

# Role-gated subtrees
{{- if ne .role "dev" }}
dot_topics/neovim/**
dot_topics/mise/**
{{- end }}
{{- if ne .role "gaming" }}
AppData/Roaming/Elgato/StreamDeck/**
{{- end }}

# Personal-only
{{- if not .personal }}
dot_config/claude/**
dot_dev/CLAUDE.md
{{- end }}

# Per-OS script trees
{{- if ne .chezmoi.os "darwin" }}
.chezmoiscripts/darwin/**
{{- end }}
{{- if ne .chezmoi.os "linux" }}
.chezmoiscripts/linux/**
{{- end }}
{{- if ne .chezmoi.os "windows" }}
.chezmoiscripts/windows/**
{{- end }}

# Always-ignored caches
.oh-my-zsh/cache/**
```

**Important rule:** *excludes always win over includes*. If `dot_config/aerospace/**` is excluded on Linux, an `!dot_config/aerospace/keep-this` won't override it. Plan the include-then-exclude flow accordingly.

### Pattern 3: Script execution model — `run_onchange_` is the workhorse

**What:** Three script types form a deliberate hierarchy:
- `run_` — every apply (rare; use only when you genuinely need it)
- `run_once_` — once per unique content hash, ever (true bootstrap actions)
- `run_onchange_` — once per unique content hash *per filename* (the default for package installs / system configs)

Combined with `before_` (executes before file/external updates) and `after_` (executes after).

**When to use which:**

| Need | Script type |
|------|-------------|
| Install Homebrew itself the first time | `run_once_before_00-install-brew.sh.tmpl` |
| Install packages from `packages.yaml` (re-run when list changes) | `run_onchange_20-install-packages.sh.tmpl` |
| Bootstrap mise plugins (re-run when plugin list changes) | `run_onchange_20-install-mise-tools.sh.tmpl` |
| Refresh tmux plugin manager state after tpm external lands | `run_onchange_after_50-tmux-plugins.sh.tmpl` |
| Rotate something every apply (rare; `chezmoi apply` becomes slow) | `run_30-refresh-something.sh.tmpl` |

**Trade-offs:**
- Pro: Content-hashed re-execution means `chezmoi apply` stays cheap on no-op runs.
- Con: Scripts MUST be idempotent — even `run_once_`. If the user wipes `chezmoistate.boltdb`, scripts re-run.
- Con: `run_before_` scripts CANNOT depend on externals (externals apply during the update phase, after `before` scripts). Use `run_after_` for anything that consumes an external.

**Naming convention:**

```
run_<once|onchange>_<before|after>?_NN-description.{sh,ps1}.tmpl
```

Numeric prefix (`10`, `20`, `30`) within an OS subdir gives deterministic intra-OS ordering. Pad with leading zero so `20` sorts after `9` correctly.

### Pattern 4: Secret integration via `bitwarden*` template functions

**What:** chezmoi ships `bitwarden`, `bitwardenFields`, `bitwardenAttachment`, and `bitwardenSecrets` functions that shell out to the Bitwarden CLI. Output is cached within a single apply, so calling `bitwardenFields` twice with the same args only invokes `bw` once.

**Where to call them:**

| Use case | Where | Why |
|----------|-------|-----|
| Render `~/.ssh/private_id_personal-github` | `dot_ssh/private_id_personal-github.tmpl` (target template) | File only exists when role/personal allow; cleanest binding to filesystem state. |
| Inject GPG private key | `private_dot_gnupg/private_*` via `bitwardenAttachment` | Attachment retrieval is the natural primitive for binary key material. |
| Set up a token used at install-script time | `.chezmoi.toml.tmpl` data prompt OR script template | Avoid: caching only lives one apply, so binding into config keeps it accessible cross-script. |
| Render `~/.netrc` or `~/.aws/credentials` | Target file template, gated by role | Same logic as SSH keys. |

**VaultWarden specifics:** chezmoi's bw functions wrap the standard `bw` CLI, which works against VaultWarden when `bw config server <url>` points at the VaultWarden URL. No chezmoi-side config needed; just ensure `bw login` and `bw unlock` have been run (or set `bitwarden.unlock = "auto"` in chezmoi config so chezmoi unlocks-and-relocks each apply).

**Session model:** `BW_SESSION` is the env var. With `auto`, chezmoi handles it. Without, the user must `export BW_SESSION=$(bw unlock --raw)` per shell. For daily use, `auto` is the right default — apply re-prompts for master password once per run, then locks.

**Bootstrap kit fallback:** When VaultWarden is unreachable, `bitwarden*` calls fail and `chezmoi apply` halts. Mitigation:
- Stage essentials (GPG key, one SSH key, BW master credentials hint) in `bootstrap/encrypted_essentials.age`.
- age identity lives offline (printed paper or hardware token).
- `bootstrap/run_once_recover.sh.tmpl` is gated by a `--data='{"bootstrap":true}'` flag (or role=lite) so it only fires in disaster recovery.
- Once VaultWarden is reachable again, normal flow resumes; bootstrap script's `run_once_` hash means it stays dormant.

### Pattern 5: Cross-OS shell-and-script symmetry

**What:** Bash for *nix (`*.sh.tmpl`), PowerShell for Windows (`*.ps1.tmpl`). Same script *intent* (install packages, configure dock, etc.) exists under each OS subdir. The `.chezmoiignore` template ensures only the active OS's tree applies.

**Why not one templated script that branches internally:** Possible but unreadable. PowerShell and Bash have different syntax, escaping, and idioms — keeping them as parallel files (mirrored under OS subdirs) is the maintenance win.

**File-layout convention for the windows tree (Phase 1):**

```
AppData/
├── Local/
│   ├── Microsoft/WindowsTerminal/settings.json.tmpl
│   └── Packages/Microsoft.WindowsTerminal_*/LocalState/settings.json.tmpl
└── Roaming/
    ├── Code/User/settings.json.tmpl
    ├── Elgato/StreamDeck/ProfilesV2/                  # gaming role only
    └── Microsoft/Windows/PowerShell/PSReadLine/
private_Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl
```

`~` on Windows = `%USERPROFILE%`, so `AppData/Local/...` under source resolves to `%LOCALAPPDATA%/...`. The `Documents/PowerShell/...` path is the PowerShell 7+ profile location.

## Data Flow

### `chezmoi apply` execution order

```
1. Read .chezmoiroot
       └─ Determine source state root (./home/)

2. Load static data layer
       └─ Read all .chezmoidata.* files and .chezmoidata/*  (lexical order)
       └─ Merge into root data dict   (dicts merge; lists/scalars replace)

3. Load per-machine config
       └─ Read ~/.config/chezmoi/chezmoi.toml
       └─ [data] table overlays prior data  (config wins on conflicts)

4. Compute built-in facts
       └─ .chezmoi.os / .chezmoi.arch / .chezmoi.hostname
       └─ .chezmoi.kernel / .chezmoi.osRelease  (Linux + WSL detection)

5. Evaluate .chezmoiignore as a template
       └─ Produce active set of source entries

6. Plan target state
       └─ Walk active source entries
       └─ For each .tmpl, render with full data context
       └─ Hash for entryState comparison vs destination

7. Run BEFORE scripts (alphabetical, within their type)
       └─ run_before_*, run_once_before_*, run_onchange_before_*
       └─ MUST NOT depend on externals (those apply in step 8)

8. Apply target updates (alphabetical by target name; dirs before contents)
       └─ Files, symlinks, encrypted files, externals (archive fetch/extract),
          scripts in .chezmoiscripts (no target file produced),
          modifies, removes

9. Run AFTER scripts (alphabetical)
       └─ run_after_*, run_once_after_*, run_onchange_after_*
       └─ Safe to depend on files/externals from step 8

10. Update chezmoistate.boltdb
       └─ Record run_once content hashes
       └─ Record run_onchange (hash, filename) pairs
       └─ Record external refresh times
```

Key invariants:
- Steps 2-4 happen ONCE per apply. The full data context is frozen before any template renders.
- `.chezmoidata/*` files **cannot be templates** because they must exist before the engine starts. For dynamic data, use the `[data]` table in `.chezmoi.toml.tmpl` (which IS a template).
- External archives are unpacked in step 8, so `run_*_before_*` scripts cannot consume them. Move "I need the unpacked oh-my-zsh tree" work into `run_*_after_*`.

### Template → data → output (concrete example)

```
~/.zshrc creation on a Mac, role=dev, personal=true, wsl=false:

  Inputs:
    ├─ data layer
    │   ├─ from .chezmoidata/packages.yaml: .packages.roles.dev.darwin (list)
    │   └─ from .chezmoidata/roles.yaml:    .roles.dev.description
    ├─ config layer (~/.config/chezmoi/chezmoi.toml)
    │   ├─ .personal = true
    │   ├─ .role = "dev"
    │   ├─ .name = "James Teague"
    │   ├─ .email = "jtteague13@gmail.com"
    │   └─ .wsl = false
    └─ facts
        ├─ .chezmoi.os = "darwin"
        ├─ .chezmoi.arch = "arm64"
        └─ .chezmoi.homeDir = "/Users/jteague"

  Source:  home/dot_zshrc.tmpl
  Render:  Go template engine + sprig + chezmoi extensions
  Output:  ~/.zshrc

  Sprinkled gates:
    {{ if .personal }}     → conda init block included
    {{ if not .personal }} → mise activate + terraform completion included
    {{ if eq .chezmoi.os "darwin" }} → /opt/homebrew paths
```

### Key data flows in the modernized repo

1. **Bootstrap (new machine):** `chezmoi init --apply jamesteague/dotfiles` → clone repo → run `.chezmoi.toml.tmpl` prompts → write `~/.config/chezmoi/chezmoi.toml` → fully apply (including `run_once_before_*` for brew/winget bootstrap, `run_onchange_*` for packages).
2. **Daily update:** Edit a file in source repo → `chezmoi apply` → static data unchanged → template re-renders → most file hashes unchanged (no-op) → changed file diff applied → if changed file was a `run_onchange_` script template, the script re-runs because its rendered content hash changed.
3. **Package list change:** Edit `.chezmoidata/packages.yaml` → `chezmoi apply` → the rendered `run_onchange_20-install-packages.sh.tmpl` content changes (the YAML feeds the script template via the data layer) → chezmoi re-runs that one script → packages install/update → state DB updated.
4. **Secret rotation:** Rotate token in VaultWarden → `chezmoi apply` → `bitwarden*` template fn fetches the new value → file with the secret re-renders with new content → file written → since the *next* apply will fetch the same value, content hash stable, no re-run unless rotated again.

## Scaling Considerations

| Scale | Architecture adjustments |
|-------|--------------------------|
| Current fleet (3-7 machines, 1 user) | Single repo, single `.chezmoidata/packages.yaml`. This research's target shape. |
| 10-20 machines (still 1 user) | Add per-host overrides via `.chezmoi.toml.tmpl` prompts on `hostname`. Use `roles.<role>.<os>.<host>` only if a host genuinely diverges. |
| Multi-user fork | Move per-user secrets out of repo entirely; share role/os/packages structure as a chezmoi *template repo* + each user has their own thin overlay. |

### Performance ceilings (chezmoi-specific)

1. **First bottleneck — `.chezmoidata/*` size.** YAML parsing happens every apply. Stay under ~100 KB combined and parsing is sub-100ms. Multi-MB YAML starts to drag.
2. **Second bottleneck — externals.** Each external refresh is an HTTP fetch + extract. Use `refreshPeriod` (already set to `168h` for oh-my-zsh / tpm) to avoid hitting GitHub on every apply.
3. **Third bottleneck — template rendering.** Sprig is fast; the only real risk is calling `bitwarden*` functions excessively. Each call is a `bw` CLI spawn (~hundreds of ms). Cache via `bitwardenFields` (chezmoi caches results within a single apply).

For this project's scale, none of these will bite. Worth documenting so the constraints aren't a mystery later.

## Anti-Patterns

### Anti-pattern 1: In-file `{{ if eq .chezmoi.os "X" }}` blocks for entire-file gating

**What people do:** Wrap a whole file's contents in `{{ if eq .chezmoi.os "linux" }}...{{ end }}` so the file renders empty on other OSes.
**Why it's wrong:** Empty files still apply, still get listed in `chezmoi managed`, still confuse the user. Diff noise.
**Do this instead:** Gate the whole file in `.chezmoiignore` based on OS/role. Reserve in-file `{{ if }}` for *within-file* deltas only.

### Anti-pattern 2: Putting install scripts inside `dot_topics/<tool>/install.sh`

**What people do:** Co-locate install logic with config under the tool's topic dir.
**Why it's wrong:** chezmoi will treat `install.sh` as a target file to copy to `~/.topics/<tool>/install.sh` instead of executing it. To get execution, you'd need `run_onchange_install.sh`, but that doesn't compose cleanly with the topic structure (it'd write to `~/run_onchange_install.sh`).
**Do this instead:** Keep install scripts under `.chezmoiscripts/<os>/`. Reference the topic by name in the script (`run_onchange_20-install-mise.sh.tmpl`). The topic dir stays config-only.

### Anti-pattern 3: Templating `.chezmoidata/*.yaml`

**What people do:** Add `.tmpl` to a data file to compute values dynamically.
**Why it's wrong:** chezmoi explicitly loads `.chezmoidata/*` BEFORE starting the template engine. The `.tmpl` will be loaded as literal YAML containing `{{` characters and parsing will fail.
**Do this instead:** Use the `[data]` table in `.chezmoi.toml.tmpl` (which IS templated) for dynamic values. Use `.chezmoidata/*` for static configuration.

### Anti-pattern 4: One mega-script that installs everything

**What people do:** `run_onchange_install-everything.sh.tmpl` that loops through every package type for every OS.
**Why it's wrong:** Any change to any package re-runs the whole thing. Slow apply, no isolation when one step fails.
**Do this instead:** Split by phase (`10-install-package-manager`, `20-install-packages`, `30-install-mas`) and per OS. Each has its own content hash and re-runs independently.

### Anti-pattern 5: Storing the age recovery key in the repo

**What people do:** Bundle the age identity in `bootstrap/` so apply "just works."
**Why it's wrong:** Defeats the purpose of encryption. Anyone with the repo can decrypt everything.
**Do this instead:** Print the age identity on paper, store offline. The repo holds only the encrypted payload. Recovery is a manual two-step: type in the identity → `chezmoi apply --data='{"bootstrap":true}'`.

### Anti-pattern 6: Relying on `.chezmoiroot` being templated

**What people do:** Try to have `.chezmoiroot` switch based on OS.
**Why it's wrong:** `.chezmoiroot` is read before any templating. It's a plain string file. (This was a discussion item in the chezmoi project; the answer is "no" — it's intentionally static.)
**Do this instead:** Use one source state root and gate per-OS subtrees via `.chezmoiignore`.

## Integration Points

### External Services

| Service | Integration pattern | Notes |
|---------|---------------------|-------|
| VaultWarden (Bitwarden CLI) | `bitwarden`, `bitwardenFields`, `bitwardenAttachment` template fns | Point `bw config server <url>` at the VaultWarden URL once; chezmoi calls are identical to cloud Bitwarden. Set `bitwarden.unlock = "auto"` in chezmoi config. Single point of failure on apply; mitigate with bootstrap kit. |
| GitHub (clone/push) | HTTPS+PAT for first clone, SSH after key material lands | Chicken-and-egg avoided: first apply renders SSH keys from VaultWarden, subsequent operations use SSH. Repo is private; PAT must have `repo` scope. |
| oh-my-zsh / tpm archives | `.chezmoiexternal.toml` with `refreshPeriod = "168h"` | Already in place; no change. |
| Homebrew (darwin/linux) | `run_once_before_*` installs brew itself, `run_onchange_*` installs packages from `packages.yaml` | `brew bundle --file=/dev/stdin` heredoc pattern keeps the brewfile-equivalent inside the template. |
| apt (linux) | `run_onchange_*` invokes `sudo apt-get install -y` from the rendered list | Requires sudo; install scripts must `set -e` and bail clearly if password prompt fails. |
| mise (cross-platform) | `run_onchange_*` invokes `mise install` on the declared tool list | mise is preferred over Homebrew for Linux per project constraints. |
| winget (windows) | `run_once_before_*` ensures winget is installed; `run_onchange_*` installs packages | Some packages need `winget install --accept-source-agreements --accept-package-agreements`. |
| MAS (mac App Store) | `run_onchange_30-install-mas.sh.tmpl`, iterates `.packages.overlays.personal.darwin.mas` dict | Requires user signed into App Store; script must skip cleanly when not signed in. |
| age (encryption) | `encrypted_*` source files; chezmoi decrypts on apply | Age identity stays off-repo. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `.chezmoidata/*` → templates | Static data injected into template context | Read once, frozen. Use `.packages.roles.dev.darwin` style access. |
| `.chezmoi.toml.tmpl` → all templates | Renders `~/.config/chezmoi/chezmoi.toml`; its `[data]` table becomes template variables | Promptable on init; values persist until rerun with `chezmoi init` or manual edit. |
| `.chezmoitemplates/<name>` → target templates | `{{ template "name" . }}` or `includeTemplate` | Pass `.` explicitly or partials see `nil`. |
| `.chezmoiignore` → source walker | Excluded entries are skipped entirely | Excludes always beat includes; cannot un-ignore a directory's children if parent is excluded. |
| `.chezmoiscripts/` → state DB | Content-hash recorded after success | Wiping `chezmoistate.boltdb` causes all `run_once_*` to re-fire. |
| Externals → file applies | Fetched + extracted during step 8 | `run_after_*` can read them; `run_before_*` cannot. |
| `chezmoi diff` → workflow safety net | Read-only render of pending changes | Use before every multi-machine landed change. |
| `chezmoi managed` → audit | Lists every target chezmoi owns on this machine | Use during refactor to verify nothing dropped accidentally. |

## Migration Build Order (Phase 0.5 → Phase 4)

This is the architecture-driven sequencing. Each phase ends in a state where every active machine has a clean `chezmoi diff`.

### Phase 0.5 — Audit & cleanup (in-place, current shape)

Goal: make the existing repo defensible before restructuring.

**Order matters within the phase:**

1. **Document `dot_topics/<tool>/` convention** (`docs/dot_topics.md`). Pure additive; zero apply risk.
2. **Drop dead config** (orphaned flameshot, unused taps, dead casks). Each drop = one `chezmoi diff` per active machine to confirm no surprise.
3. **Normalize nesting inconsistencies in current `packages.yaml`** without restructuring axes yet. E.g., if some tools live under `core.brews` and morally belong under `darwin.brews`, move them. Verify with `chezmoi diff` on both Mac machines.
4. **Add `docs/conventions.md`** capturing the existing structural decisions (`.chezmoiroot = home`, dot_topics, `.chezmoiscripts/` not yet used heavily, externals).

Exit criterion: `chezmoi diff` on Mac personal AND Mac work both produce zero diff.

### Phase 0 — Structural refactor (on branch, atomic)

Goal: land the new taxonomy without functional change on currently-active machines.

**Atomic ordering inside Phase 0 (single branch, single PR/merge):**

1. **Extend `.chezmoi.toml.tmpl`** to add `role` prompt (with `dev` as default to preserve current behavior on existing machines). Auto-detect WSL already in place; keep.
2. **Add `.chezmoidata/roles.yaml`** declaring role metadata.
3. **Rewrite `.chezmoidata/packages.yaml`** to `roles.<role>.<os>` + `overlays.personal.<os>` shape. The current `core/darwin/linux + personal/work` content maps cleanly to `roles.dev.<os>` + `overlays.personal.<os>` + `overlays.work.<os>`.
4. **Add `.chezmoiscripts/` skeleton** with `common/`, `darwin/`, `linux/`, `windows/` subdirs. Initial population: extract any current install logic from ad-hoc `*.sh` files into `run_onchange_*.sh.tmpl` form.
5. **Update `.chezmoiignore`** to gate per-OS scripts and prepare for role-based gating (most rules no-op for current Mac machines but architecturally ready).
6. **Add `.chezmoitemplates/`** with the first 2-3 partials (git-signing block, brew-bundle renderer).

Validation gate: `chezmoi diff` on Mac personal AND Mac work both produce zero functional diff (or only the intended additive script work, which is `run_onchange_` and self-resolving). This is the per-machine sign-off before merging the refactor branch.

### Phase 1 — Windows-host support (additive)

Goal: gaming rig and spiral index laptop onboard cleanly.

**New artifacts:**
- `AppData/` subtree (Windows-specific target files)
- `.chezmoiscripts/windows/run_once_before_10-install-winget.ps1.tmpl`
- `.chezmoiscripts/windows/run_onchange_20-install-packages.ps1.tmpl`
- `private_Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl`
- `AppData/Roaming/Elgato/StreamDeck/ProfilesV2/` (gaming role only)
- `.chezmoidata/packages.yaml` additions: `roles.gaming.windows`, `roles.dev.windows`, `roles.lite.windows`

Why additive: nothing in this phase changes existing Mac behavior. `.chezmoiignore` already excludes `AppData/**` on non-Windows.

### Phase 2 — WSL accommodations (additive, crosses host/WSL boundary)

Goal: WSL-on-gaming-rig becomes a viable `role=dev` Linux machine.

**Where things land:**
- **In WSL source tree:** `etc/wsl.conf.tmpl` (root-target via sudo apply or staged-script pattern), `dot_topics/*` Linux variants where divergent.
- **On Windows host source tree:** `private_dot_wslconfig.tmpl` (renders to `%USERPROFILE%\.wslconfig`). Note: this is a *Windows host* file, NOT a WSL file. It belongs in the Windows-host application.
- **`.chezmoidata/packages.yaml`:** `roles.dev.linux` includes apt + mise lists.
- **Gating:** `.chezmoiignore` distinguishes WSL from native Linux via `.wsl` boolean (already auto-detected in `.chezmoi.toml.tmpl`).

The two-application reality: chezmoi runs once on the Windows host (to land `.wslconfig`) and separately inside WSL (to land everything else). Document this clearly — single application can't span the boundary.

### Phase 3 — role=lite (additive, minimum-viable)

Goal: spiral index laptop onboards with browser + Office + Bitwarden + PicPick.

**New artifacts:**
- `.chezmoidata/packages.yaml`: `roles.lite.windows` with the minimal list.
- `.chezmoiignore` adds `{{ if eq .role "lite" }}` exclusions for everything dev/gaming.
- Possibly a `bootstrap/run_once_recover.sh.tmpl` gated to `role=lite` for the printer-driver-style manual `.msi` reminder.

Phase 3 is intentionally small. It validates that the role axis works for the lightest-weight case.

### Phase 4 — Lonestar onboarding (cross-cutting generalization)

Goal: any new machine (whatever OS) reaches working state via single `chezmoi init --apply` plus VaultWarden login.

**New artifacts:**
- `README.md` "new machine bootstrap" section, OS-specific.
- `bootstrap/encrypted_essentials.age` + recovery script (if not landed earlier).
- Optional: GitHub Actions or local CI hook to lint `.chezmoidata/packages.yaml` schema.

This phase mostly hardens what's already there. If Phases 0-3 are clean, Phase 4 is documentation + the bootstrap kit + the "first run" experience polish.

## Cross-OS File Layout Gotchas

| Gotcha | Manifestation | Mitigation |
|--------|---------------|------------|
| Path separators | `\` in Windows paths vs `/` everywhere else | Use `.chezmoi.homeDir | replace "\\" "/"` in templates when emitting paths for tools that want forward-slashes (git config, JSON configs). Tested pattern. |
| Config locations | `~/.config/<app>` on *nix vs `%APPDATA%\<app>` or `%LOCALAPPDATA%\<app>` on Windows | Mirror the literal layout under source. Don't try to "abstract" via templating; the file-tree clarity is more valuable. |
| Line endings | chezmoi writes LF by default; some Windows apps want CRLF | Use the `crlf` template function or set `textConvWindows = "CRLF"` in chezmoi config. Most modern Windows apps tolerate LF. |
| Executable bit | `executable_` prefix is a no-op on Windows (NTFS doesn't carry that bit the same way) | PowerShell scripts run from `.ps1` extension; bash scripts in WSL keep the bit via the prefix. Fine in practice. |
| Symlinks | `symlink_` works cross-OS but Windows needs Developer Mode or admin to create unprivileged | Prefer file copies (default) over symlinks unless symlink semantics matter (e.g., live-reloading a config dir). |
| File permissions | `private_` (0600) works on all OSes but Windows ACLs differ | chezmoi sets NTFS ACLs to mimic Unix mode. SSH on Windows OpenSSH is picky about key file ACLs — `private_` is required for `~/.ssh/private_id_*`. |
| Case sensitivity | macOS HFS+/APFS default case-insensitive; Linux ext4 case-sensitive; Windows NTFS case-insensitive | Be consistent. Don't have `dot_topics/Git/` and `dot_topics/git/` thinking they're different. |
| Long paths on Windows | 260-char MAX_PATH default; chezmoi tree depth can exceed | Enable long paths via Windows policy or registry on gaming rig setup; document in Phase 1 README. |
| `~` resolution on Windows | chezmoi maps `~` to `%USERPROFILE%`; `~/AppData/Local` → `C:\Users\X\AppData\Local` | Just write source paths relative to `~` (so `AppData/...` under source) and the resolution is automatic. |
| Sudo-target files on Linux/WSL | `/etc/wsl.conf` isn't under `~` | Use a staged-script pattern: ship the file as `dot_config/wsl/wsl.conf.tmpl` (in $HOME) and a `run_onchange_after_*.sh.tmpl` that sudo-copies it to `/etc/wsl.conf`. Avoids `chezmoi apply --sudo`. |

## Sources

- [chezmoi — Source state attributes](https://www.chezmoi.io/reference/source-state-attributes/) — prefix grammar, script type semantics, ordering rules. HIGH confidence (official).
- [chezmoi — Special files reference](https://www.chezmoi.io/reference/special-files/) — `.chezmoiroot`, `.chezmoiignore`, `.chezmoidata.<format>`, `.chezmoiexternal`. HIGH confidence (official).
- [chezmoi — `.chezmoidata/` directory](https://www.chezmoi.io/reference/special-directories/chezmoidata/) — merge order, format support, template engine ordering constraint. HIGH confidence (official).
- [chezmoi — `.chezmoitemplates/` directory](https://www.chezmoi.io/reference/special-directories/chezmoitemplates/) — partial inclusion, naming. HIGH confidence (official).
- [chezmoi — Application order](https://www.chezmoi.io/reference/application-order/) — the canonical 1-9 step sequence used in the data-flow diagram. HIGH confidence (official).
- [chezmoi — Use scripts to perform actions](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/) — `run_`/`run_once_`/`run_onchange_`, before/after, `.chezmoiscripts/` semantics. HIGH confidence (official).
- [chezmoi — Templating user guide](https://www.chezmoi.io/user-guide/templating/) — data context layering, conditional patterns, partials. HIGH confidence (official).
- [chezmoi — Bitwarden integration](https://www.chezmoi.io/user-guide/password-managers/bitwarden/) — `bw` CLI requirements, `unlock = "auto"`, session model. HIGH confidence (official).
- [chezmoi — Bitwarden template functions reference](https://www.chezmoi.io/reference/templates/bitwarden-functions/) — `bitwarden`, `bitwardenFields`, `bitwardenAttachment`, caching. HIGH confidence (official).
- [recca0120 — chezmoi: One Dotfiles Repo Across macOS, Linux, and Windows](https://recca0120.github.io/en/2026/04/13/chezmoi-dotfiles-management/) — practitioner write-up confirming `home/`-rooted layout, `.chezmoiscripts/<os>/` convention, `run_onchange_` for package installs, age + offline-key footgun. MEDIUM confidence (single source, but matches official patterns).
- [twpayne/chezmoi#3083 — Multi OS Support with `.chezmoiroot` as a template?](https://github.com/twpayne/chezmoi/discussions/3083) — confirms `.chezmoiroot` is intentionally non-templated. HIGH confidence (project maintainer thread).
- [twpayne/chezmoi#1734 — Order of script execution by `.chezmoiscripts`](https://github.com/twpayne/chezmoi/issues/1734) — confirms alphabetical-within-type ordering. HIGH confidence (project issue).
- [Bitwarden CLI docs](https://bitwarden.com/help/cli/) — `bw config server` for VaultWarden, `BW_SESSION` model. HIGH confidence (official Bitwarden docs).
- Existing repo files read: `.chezmoi.toml.tmpl`, `.chezmoidata/packages.yaml`, `.chezmoiexternal.toml`, `.chezmoiignore`, `dot_zshrc.tmpl`, `.planning/PROJECT.md`. HIGH confidence (direct observation).

---
*Architecture research for: chezmoi multi-OS, role-based dotfiles repo*
*Researched: 2026-05-27*
