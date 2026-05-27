# Feature Research

**Domain:** Multi-OS dotfile management (chezmoi-based fleet, 7 machines, 3 OS families, 3 roles + personal flag)
**Researched:** 2026-05-27
**Confidence:** HIGH (chezmoi capabilities verified against official docs; cross-OS quirks verified against real-world dotfile repos)

## Orientation

This research catalogues the feature surface a chezmoi-based fleet manager must cover. The fleet shape (Mac dev × 2, Windows gaming, Windows lite, WSL dev, Linux dev future, Lonestar TBD) means **the bar for "table stakes" is set by the union of all 3 OS families' minimum viable configs, NOT by what's easy on any one OS**. A feature that's trivial on Mac (Homebrew bundle) and hard on Windows (winget + manual .msi blend) is still table stakes — it just gets a HIGH complexity tag.

Categorization legend:
- **Table stakes** — if the system can't do this, one or more machines in the fleet fall off it
- **Differentiator** — quality-of-life or trust-multiplier; product is usable without it, but noticeably worse
- **Anti-feature** — surface-attractive things that have been deliberately ruled out (with rationale and alternative)

---

## Feature Landscape

### Table Stakes (Fleet Falls Off Without These)

| Feature | Why Table Stakes | Complexity by OS | Notes |
|---------|------------------|-------------------|-------|
| **Templated package list per role × OS** (brew on darwin, apt+mise on linux, winget on windows) | Three machines (gaming, lite, future Linux laptop, WSL greenfield) cannot be brought up without it; this is the central reason for the modernization | macOS: LOW (brew bundle mature), Linux/apt: LOW, Windows/winget: MEDIUM (winget less mature than brew, post-install registry tweaks common) | Replaces current `personal` boolean. Structure: `roles.<role>.<os>` + `overlays.personal.<os>`. Use `run_onchange_install-packages.sh.tmpl` so installer re-runs only when the rendered list changes (SHA256-tracked). |
| **OS + WSL + role + personal conditional gating** | Single repo serves 7 disparate machines; without conditionals every file forks into 4-7 variants | LOW everywhere (chezmoi templates are the same syntax) | Pattern: `.chezmoiignore` (machine-level: "this whole file doesn't apply here") + in-file `{{ if eq .chezmoi.os ... }}` (file-level: "this section varies"). Prefer `.chezmoiignore` for whole-file decisions (faster, easier to grep). WSL detected via `.chezmoi.kernel.osrelease` contains "microsoft". |
| **Cross-OS git config with signing key + correct email** | Day-1 GitHub commits must sign or they show "unverified"; work email on work machines, personal on personal | LOW (single .gitconfig.tmpl, conditional `email`/`signingkey` blocks) | Already templated in the repo; needs to lift `signingkey` value from VaultWarden's canonical GPG key fingerprint. |
| **SSH config with per-purpose keys** (personal-github, work-github, optional homelab) | Per-purpose key isolation is locked decision; HTTPS-clone-then-SSH bootstrap pattern requires the config to land before keys are useful | LOW on *nix (single ~/.ssh/config with `Host github-personal` / `Host github-work` aliases), MEDIUM on Windows (OpenSSH client path conventions, agent service) | Use `Host github.com-personal` alias pattern + `IdentitiesOnly yes`. Clone URLs become `git@github.com-personal:user/repo.git`. `IdentityFile` paths differ by OS — template them. |
| **Secret retrieval from VaultWarden via `bitwarden*` template fns** | Locked decision; this is the credential plane | MEDIUM all OSes (requires `bw` CLI installed + unlocked session before `chezmoi apply`; `bw unlock --raw` + `BW_SESSION` env var pattern) | `bitwarden.unlock` config var can auto-unlock. For VaultWarden specifically, set `bw config server https://<vw-url>` before login. Cache: chezmoi caches per-item per-apply so multiple template uses don't re-fetch. |
| **Encrypted bootstrap kit (age) for VaultWarden-unreachable scenario** | Locked decision; VaultWarden is single point of failure (Unraid + Cloudflare tunnel); must survive that being down | LOW (chezmoi has builtin age support, no external age binary required) | Critical pitfall: lose the age key, lose every encrypted file forever. Key stewardship strategy needed (e.g., GPG-encrypted in VaultWarden + physical paper backup + iCloud Keychain note). The bootstrap kit should contain *just enough* to reach VaultWarden again (SSH key fragments, VW server URL, master password hint). |
| **Day-1 single-command bootstrap** (`chezmoi init --apply <repo>` flow) | Core value statement; without it the modernization fails its primary justification | macOS: LOW (curl-install + chezmoi init), Linux: LOW, Windows: MEDIUM (winget install chezmoi, then PowerShell-flavored apply path; pwsh.exe may not be present yet — fallback to powershell.exe) | Manual prerequisites that CANNOT be automated: OS install, GitHub PAT (for HTTPS clone of private repo), VaultWarden master password. Everything after those three inputs should be automated. |
| **Drift detection (`chezmoi diff` / `chezmoi managed`)** | Migration safety constraint requires per-machine validation gate; without trust in diff, no machine can safely re-apply | LOW everywhere | Already works. Make it the explicit acceptance criterion for every phase: "Mac personal `chezmoi diff` is empty" gates merge. |
| **Topic-based shell config loader** (`dot_topics/<tool>/{path,eval,config}.zsh`) | Existing convention; not having it would force a rewrite of the working zshrc | LOW on *nix (already implemented), N/A on Windows (PowerShell needs its own loader pattern) | Document the convention (currently undocumented per PROJECT.md). Standardize: `path.zsh` for PATH mutation, `eval.zsh` for shell init (`eval "$(starship init zsh)"`), `config.zsh` for aliases/env, `install.sh` for one-time setup. Add `path.ps1`/`config.ps1` parallel for Windows? See Differentiators. |
| **External asset pinning** (`.chezmoiexternal.toml` for oh-my-zsh, tpm, etc.) | Already in use; not having external pinning means manual clone-and-pray | LOW everywhere | Already works. Add `refreshPeriod` to avoid hammering GitHub on every apply. Don't use git submodules (chezmoi docs explicitly warn against — loses executable permissions). |
| **Atomic commit + branch-based migration** | Migration safety: Mac personal + Mac work must keep working through refactor | N/A (git workflow, not OS-specific) | Phase 0 refactor lives on a branch, validated via `chezmoi diff` on both Mac machines before merge. Standard hybrid migration pattern. |

### Differentiators (Quality-of-Life Multipliers)

| Feature | Value Proposition | Complexity by OS | Notes |
|---------|-------------------|-------------------|-------|
| **Cross-OS prompt (starship) + history (atuin) parity** | Same prompt, same Ctrl-R, same `cd` behavior on Mac, Linux, WSL, and Windows PowerShell — reduces "which machine am I on" cognitive tax | LOW on *nix, MEDIUM on Windows (starship works in pwsh; atuin works in pwsh as of recent versions; both are single Rust binaries — install via winget) | Already present on Mac. Extension to Windows is the lift. Critically reduces the "Windows feels foreign" tax that currently keeps the gaming rig artisanal. |
| **Stream Deck profile management via external `.chezmoiexternal.toml` archive** (gaming rig only) | Hardware-state-as-code; today the profiles are artisanal on the gaming rig and lost if the SSD dies | MEDIUM Windows-only (Stream Deck stores binary `.streamDeckProfile` archives at `%APPDATA%\Elgato\StreamDeck\ProfilesV2\`; these are zip files containing JSON + assets) | Gate to `role=gaming + os=windows` in `.chezmoiignore`. Profile updates are manual (export from Stream Deck app → commit). Treat the exported `.streamDeckProfile` as the source of truth; chezmoi just puts it back in place. |
| **Bootstrap fallback kit** (encrypted essentials in repo) | Disaster recovery: VaultWarden down + travel + new machine = you can still bootstrap to a working state | LOW (just age-encrypted files; chezmoi has builtin age) | Already listed as table stakes above. Promoting the *contents design* to differentiator: what goes in is the differentiator — too much and the kit becomes a parallel secret store, too little and it doesn't help. Recommendation: SSH key for chezmoi-repo-read, VaultWarden URL + master-password hint, age-decrypt instructions in plaintext README. |
| **VIA keyboard layout at `keyboard/` (outside `.chezmoiroot`)** | Already in repo; keyboard firmware-as-code; survives keyboard reset | LOW (just static JSON files committed in repo) | Document its existence in PROJECT.md — currently load-bearing but undocumented. Not chezmoi-managed; consumed by VIA app manually. |
| **PowerShell profile parity with zshrc** (starship, PSReadLine with predictive history, aliases that mirror *nix muscle memory) | Reduces context-switch tax between Mac/WSL and Windows native; the gaming rig becomes usable for "quick dev poke" without context shift | MEDIUM (PSReadLine config syntax is its own learning curve; pwsh module loading differs from zsh source) | Mirror the topic structure: `dot_topics/<tool>/profile.ps1` loaded by a single `Microsoft.PowerShell_profile.ps1.tmpl`. Aliases: `ls`→`Get-ChildItem -Force`, `grep`→`Select-String`, etc. Don't try for *exact* parity — PowerShell objects are not text streams, and forcing the fiction breaks pwsh's actual strengths. |
| **`run_onchange_` installer scripts that re-run on `packages.yaml` SHA change** | Idempotent package install that's also *responsive* — change a package, next apply installs it, no manual re-run | LOW everywhere | Embed `# packages-hash: {{ include "packages.yaml" \| sha256sum }}` at the top of `run_onchange_install-packages.sh.tmpl`. Chezmoi tracks the hash; rerun trigger is automatic. |
| **`.chezmoiignore` as readable per-machine inventory** | Single grep tells you "what's on this machine?" without spelunking templates | LOW everywhere | Comment liberally. Example: `# === gaming rig only === \n {{- if ne .role "gaming" }} \n streamdeck/ \n {{- end }}`. The `.chezmoiignore` itself becomes documentation. |
| **Per-role README/docs scaffold** (what's on a `dev` machine vs a `lite` machine) | Future-Teague + Lonestar onboarding: a human-readable spec, not just templates | LOW everywhere | `.planning/` is already the home for this. The roadmap should produce `ROLES.md` as a deliverable. |
| **Renovate/Dependabot for `packages.yaml` pinned versions** (if any are pinned) | Catches drift in pinned tool versions automatically | LOW (Renovate config in repo) | Reference: `jwnmulder/dotfiles` does this. Probably overkill for this fleet's scale — defer unless pin-heavy. |
| **Hostname-based fallback in `.chezmoi.toml.tmpl`** for ambiguous machines | When auto-detection isn't enough (e.g., a Mac that could plausibly be `personal` OR `work` based on hostname) | LOW everywhere | The `.chezmoi.toml.tmpl` prompts on first-run can have `{{ promptStringOnce . "role" "Role for this machine?" "dev" }}` with sensible defaults derived from hostname. Reduces "did I answer wrong on init?" anxiety. |

### Anti-Features (Deliberately NOT Built)

| Feature | Why It's Tempting | Why It's Wrong For This Fleet | Alternative |
|---------|-------------------|-------------------------------|-------------|
| **One SSH key, used everywhere** | Simpler to bootstrap, simpler to think about | Locked decision against — per-purpose keys win on rotation hygiene, clean off-boarding (leaving job = revoke the work-github key only), and blast radius if a key leaks | Per-purpose keys (personal-github, work-github, optional personal-homelab) via SSH config Host aliases |
| **Nix / home-manager** | Reproducibility holy grail; declarative everything | No native Windows support → disqualifies for gaming rig + lite + WSL host. PROJECT.md confirms evaluated and rejected | chezmoi + templated package lists. Less pure, covers all OSes |
| **Linux Homebrew on WSL/Linux machines** for cross-OS command parity | "Same `brew install` everywhere" is psychologically attractive | Locked decision against — apt + mise already work, brew commands aren't load-bearing for daily shell time, doubles install surface | apt for system, mise for runtime-version-managed tools |
| **One-key-everywhere GPG identity** | Mirrors the "canonical GPG key" decision, seems consistent | Canonical *signing* key is correct (GitHub knows the one key). Canonical *encryption* key creates collateral when revoking (revoking for work-leaving event also revokes the personal cert) | One canonical GPG signing key; per-purpose SSH keys; no GPG encryption identities (use age for chezmoi encryption — already chosen) |
| **OBS scene/asset management in chezmoi** | "Manage everything!" instinct | Locked out of scope. Scene assets are large binaries scattered across two machines; need portability redesign first | Separate sub-project. When ready, likely git-LFS or external archive, NOT inline in chezmoi |
| **Unraid homelab config in chezmoi** | Same "manage everything" instinct | Locked out of scope. Unraid is an appliance OS configured via Web UI; persistence on USB; Unraid's native flash backup is the right primitive | Unraid flash backup, periodically verified |
| **Auto-apply on `git pull` (post-merge hook to run `chezmoi apply`)** | "Just keep machines in sync automatically" | Removes the human review step; a bad template change cascades across the whole fleet silently. Recovery from drift is harder than the friction it saves | Explicit `chezmoi update` (= pull + apply with diff prompt). Maybe a status bar / shell prompt indicator showing "your chezmoi is N commits behind" |
| **Auto-detected role** (infer dev/gaming/lite from installed-software fingerprint) | Eliminates one init prompt | Brittle (gaming rig also has dev tools transitively; lite laptop might have a browser dev tool). Failure mode is silent miscategorization | Explicit role chosen at init via `promptStringOnce`. The prompt is one-time; the cost is low |
| **Driver installs, BIOS, GPU OC, NVIDIA Control Panel, audio routing, taskbar pinning** | "Make Windows fully turnkey" | Locked out of scope. Vendor-driver / hardware-state surface that doesn't have machine-readable interfaces. Forcing it into chezmoi creates fragile bash-driving-GUI scripts | Document in a `MANUAL-WINDOWS-SETUP.md`; treat as part of the OS install step, not the chezmoi step |
| **Symlink-style "all dotfiles are links into the repo"** (stow-style) | Simpler mental model; edits to live files immediately reflect | chezmoi's template + encrypt + script pipeline is incompatible with raw symlinks. Locked in by tool choice. Trying to bolt on symlinks defeats the templating | Trust the `chezmoi edit` flow (edits source, optionally auto-applies). For "live tweaking" experiments, use `chezmoi cd` + apply loop |
| **OBS-scene-like binary asset versioning for Stream Deck** | Want full restoration | Stream Deck profiles ARE binary archives; treating them as text breaks. Already handled correctly — store as binary `.streamDeckProfile` files via `.chezmoiexternal.toml` or as `private_` binary files | Treat the exported `.streamDeckProfile` as opaque, version it, restore on apply |
| **Custom inline encryption** (rolling your own `gpg`-and-template pipeline) | Seems more flexible | chezmoi has age + gpg + bitwarden* + custom-secret hooks built in. Rolling custom = re-inventing | Use builtin chezmoi encryption + bitwarden template fns |

---

## Feature Dependencies

```
[VaultWarden bitwarden template fns]                     ← table stakes
    └──requires──> [bw CLI installed + initially logged in]
    └──requires──> [Network reachability to vw.<domain> via Cloudflare]
         └──fallback──> [Encrypted bootstrap kit (age)]   ← table stakes

[Per-purpose SSH keys]                                   ← table stakes
    └──requires──> [VaultWarden retrieval OR bootstrap kit (for first key)]
    └──requires──> [SSH config with Host aliases]
         └──enables──> [Canonical GPG signing on day 1]   ← table stakes
              └──requires──> [GPG key in VaultWarden + gpg CLI present]

[Templated packages.yaml]                                ← table stakes
    └──requires──> [3-role taxonomy in .chezmoi.toml.tmpl]
    └──requires──> [OS auto-detection + WSL flag]
    └──drives────> [run_onchange_install-packages.sh.tmpl]

[Cross-OS shell parity (starship/atuin)]                 ← differentiator
    └──requires──> [packages.yaml has them per OS]
    └──requires──> [dot_topics convention extends to PowerShell]

[Stream Deck profile mgmt]                               ← differentiator
    └──requires──> [.chezmoiignore gates to role=gaming + os=windows]
    └──requires──> [Binary file handling in chezmoi (already works)]

[Topic-based shell loader (dot_topics/)]                 ← table stakes (existing)
    └──enables──> [Adding tools is a single directory drop]
    └──enables──> [PowerShell parity differentiator]

[Day-1 bootstrap]                                        ← table stakes
    └──requires──> [Repo private (✓ done 2026-05-27)]
    └──requires──> [GitHub PAT for HTTPS clone (manual)]
    └──requires──> [chezmoi installed (winget/brew/curl)]
    └──requires──> [VaultWarden master password (manual)]
    └──requires──> [Everything else above as transitive deps]

[role=lite]                                              ← table stakes
    └──conflicts-with──> [dev-only topics in dot_topics/]
         └──resolved-by──> [.chezmoiignore gating most dot_topics to role=dev]

[role=gaming]                                            ← table stakes
    └──conflicts-with──> [dev tools in default install lists]
         └──resolved-by──> [packages.yaml roles.gaming.windows is a separate branch]
```

### Dependency Notes

- **VaultWarden ↔ bootstrap kit is the load-bearing edge.** Without the encrypted fallback, any VaultWarden outage = "Teague cannot stand up a new machine." This is the disaster-recovery posture and must be a Phase 0 deliverable, not a "we'll get to it later" item.

- **SSH keys → GPG signing is a chain.** SSH keys come down first (because git operations need them), but the GPG signing key needs to land before any commit on the new machine to avoid retroactive "unverified" tags. Order in bootstrap script matters.

- **3-role taxonomy → packages.yaml structure is the central refactor.** Most other table-stakes features are templated on `role`, so the role enum must land first. Phase 0 of the roadmap.

- **dot_topics convention → PowerShell parity is the bridge.** The differentiator hinges on extending the existing convention to a new shell, not on inventing a Windows-native pattern. The migration unit is "add `*.ps1` siblings to existing topic directories."

- **role=lite and role=gaming both NEED `.chezmoiignore` to be aggressive.** Without it, a `lite` machine would pull down nvim configs, tmux configs, and 30 dev tools it'll never run. The default posture for `dot_topics/<tool>/` should be "ignored unless role=dev OR explicit allow-list."

---

## MVP Definition

### Launch With (Phase 0 + Phase 1-equivalent — the "modernization is done" bar)

The minimum to claim the modernization is real:

- [ ] **3-role × personal × OS × WSL taxonomy** in `.chezmoi.toml.tmpl` — without this, nothing else templates correctly
- [ ] **packages.yaml restructured** around `roles.<role>.<os>` + `overlays.personal.<os>` — load-bearing for every machine
- [ ] **Both Mac machines re-apply with empty `chezmoi diff`** — migration safety gate; proves no regression
- [ ] **VaultWarden integration working** (bitwarden template fns retrieve at least one secret in a live render) — proves the credential plane
- [ ] **Canonical GPG signing key working** via VaultWarden retrieval on both Macs — proves the GPG retirement of `generate-gpg-key.sh`
- [ ] **Per-purpose SSH keys** (personal-github + work-github) deployed and exercised — proves the key-isolation locked decision
- [ ] **Encrypted bootstrap kit** committed (age-encrypted, contains: VaultWarden URL, recovery instructions, SSH key for repo read) — proves disaster-recovery posture
- [ ] **Day-1 bootstrap doc** (`.planning/BOOTSTRAP.md` or similar): exact commands from "fresh OS" to "chezmoi apply complete" per OS family — proves you can repeat the process

### Add After Validation (Phase N — additive)

- [ ] **Windows native support** (winget package list, PowerShell profile, .ps1.tmpl scripts) — gating: gaming rig + lite onboarding
- [ ] **WSL greenfield setup** on gaming rig — gating: Windows native landed so WSL accommodations (`/etc/wsl.conf`, `~/.wslconfig`) have a host to land on
- [ ] **role=gaming Windows package list** + Stream Deck profile management — gating: Windows native support landed
- [ ] **role=lite Windows package list** (browser, Office, Bitwarden, PicPick, manual vendor `.msi` doc) — gating: Windows native support landed
- [ ] **Cross-OS starship + atuin parity** — gating: Windows native support landed
- [ ] **Lonestar onboarding playbook** — gating: applies whichever role/OS combination is needed; mostly a documentation deliverable once the patterns exist
- [ ] **Session 59 Claude Code config integration** (settings.json.tmpl + ~/dev/CLAUDE.md gated by `personal`) — independent of OS work; can land in parallel
- [ ] **dot_topics documentation** (the `path.zsh`/`eval.zsh`/`config.zsh`/`install.sh` convention) — gating: nothing; pure docs

### Future Consideration (Defer Unless Forcing Function Appears)

- [ ] **Future Linux laptop role=dev coverage** — only when the laptop is real
- [ ] **Renovate/Dependabot for pinned versions** — only if pin-heavy patterns emerge
- [ ] **Auto-update prompt in shell** ("chezmoi is N commits behind") — quality-of-life, no forcing function yet
- [ ] **Hostname-based init defaults** — only if the prompt-on-init friction is observed as a real cost
- [ ] **Cross-machine shell history sync via Atuin server** — depends on whether Teague wants self-hosted Atuin server (probably yes given the homelab); defer to a separate decision

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| 3-role × personal × OS × WSL taxonomy | HIGH | MEDIUM | P1 |
| packages.yaml refactor | HIGH | MEDIUM | P1 |
| Mac diff-empty migration validation | HIGH | LOW | P1 |
| VaultWarden bitwarden template fns | HIGH | MEDIUM | P1 |
| Canonical GPG signing via VaultWarden | HIGH | LOW | P1 |
| Per-purpose SSH keys | HIGH | LOW | P1 |
| Encrypted bootstrap kit | HIGH | MEDIUM | P1 |
| Day-1 bootstrap doc per OS | HIGH | LOW | P1 |
| `.chezmoiignore` aggressive gating for role=lite/gaming | HIGH | LOW | P1 (lands with Windows phase) |
| Windows native support (winget + pwsh profile + .ps1.tmpl) | HIGH | HIGH | P2 |
| Stream Deck profile mgmt | MEDIUM | MEDIUM | P2 |
| Cross-OS starship + atuin parity | MEDIUM | MEDIUM | P2 |
| WSL greenfield on gaming rig | HIGH | MEDIUM | P2 |
| role=lite minimal install | MEDIUM | LOW | P2 |
| Session 59 Claude Code integration | MEDIUM | LOW | P2 (parallel-safe) |
| dot_topics convention docs | MEDIUM | LOW | P2 (parallel-safe) |
| Lonestar onboarding playbook | HIGH (when needed) | LOW | P2 (just-in-time) |
| PowerShell topic-loader parity with zshrc | MEDIUM | MEDIUM | P3 |
| Renovate for packages.yaml pins | LOW | LOW | P3 |
| Shell "chezmoi N commits behind" indicator | LOW | LOW | P3 |
| Atuin server self-host for history sync | MEDIUM | MEDIUM | P3 (separate decision) |

**Priority key:**
- **P1** — Must land in the foundational phase; everything else depends on these
- **P2** — Should land in the modernization; additive, ship independently
- **P3** — Nice to have, future consideration

---

## Cross-OS Complexity Hotspots

The planner should know where the rough terrain is. These are the features that look uniform on paper but have very different implementation surfaces per OS:

| Feature | macOS | Linux/WSL | Windows | Why It's Asymmetric |
|---------|-------|-----------|---------|---------------------|
| Package install | LOW (brew bundle is mature, idempotent, single binary) | LOW (apt is mature; mise handles runtime versions; `apt-get install -y` idempotent) | MEDIUM-HIGH (winget exists but: less-mature search/version pinning, some software still only ships as `.msi` from vendor, some software is Microsoft Store-only requiring different invocation, post-install registry tweaks common) | winget is younger; Windows software distribution is more fragmented |
| Shell config | LOW (zshrc, well-trodden) | LOW (bashrc/zshrc) | MEDIUM (PowerShell profile location varies by host: `$PROFILE` resolves to different paths for pwsh vs powershell vs ISE; pwsh module ecosystem is its own world) | PowerShell is object-stream, not text-stream |
| SSH config | LOW (~/.ssh/config standard) | LOW (~/.ssh/config standard) | MEDIUM (OpenSSH client built-in but agent service must be enabled; Windows-Terminal vs cmd vs git-bash all have slightly different conventions) | Windows OpenSSH client lagged behind for years; agent quirks |
| Secret retrieval (`bw` CLI) | LOW (brew install bitwarden-cli) | LOW (npm or direct download) | LOW (winget install bitwarden.cli) | Actually consistent — Node.js CLI runs everywhere |
| GPG | LOW (gpg-suite or brew) | LOW (gnupg standard) | MEDIUM (gpg4win install + agent setup + clearing the Windows credential cache when wrong agent answers) | Windows GPG has historical agent confusion |
| Script execution | LOW (bash/.sh.tmpl native) | LOW (bash/.sh.tmpl native) | MEDIUM (`.ps1.tmpl`; pwsh.exe may or may not be installed — chezmoi falls back to powershell.exe; execution policy must allow scripts) | Pwsh fallback chain + execution policy |
| File paths in templates | LOW (~/.config standard) | LOW (~/.config standard) | MEDIUM-HIGH (`$env:USERPROFILE`, `$env:APPDATA`, `$env:LOCALAPPDATA`, `%APPDATA%` — and chezmoi templates them differently from PowerShell does; mixing `\` and `/` matters) | Windows path semantics |
| `.chezmoiexternal` archives | LOW (tar.gz, zip standard) | LOW | LOW-MEDIUM (zip standard; Windows Defender may quarantine extracted contents from unknown sources) | Defender behavior |
| Symlinks | LOW (Unix native) | LOW (Unix native) | MEDIUM (Windows symlinks require either Developer Mode enabled, or admin token; chezmoi handles `symlink_` source-state prefix but the *target* creation may fail on a stock Windows) | Windows symlink permission model |
| Idempotent re-apply (`chezmoi apply` x N times) | LOW | LOW | LOW-MEDIUM (some Windows scripts have side effects that are idempotent in spirit but noisy in practice — registry tweaks log even when unchanged) | Windows tooling chattier |
| Stream Deck profile placement | N/A (Mac has Stream Deck app; could in theory manage Mac profiles too, but gaming rig is the target) | N/A | MEDIUM (`%APPDATA%\Elgato\StreamDeck\ProfilesV2\<UUID>.streamDeckProfile`; UUIDs are stable per profile but generated on creation — need to commit the UUID directory structure as-is) | Hardware-state surface |

**Implication for the planner:** Phases that touch Windows are *meaningfully* more work than phases that touch only Mac/Linux. Estimate accordingly. The Windows-native phase (winget + pwsh profile + `.ps1.tmpl` patterns + path conventions) is the biggest single lift in the roadmap.

---

## Competitor Feature Analysis

For context — what other tools do that informed which features made the list vs got cut. This fleet is locked on chezmoi (Nix evaluated and rejected upfront per PROJECT.md), so the comparison is to inform feature scope, not tool choice.

| Feature | GNU Stow | yadm | dotbot | Nix / home-manager | chezmoi (our choice) |
|---------|----------|------|--------|---------------------|----------------------|
| Cross-OS templating | None (symlinks only) | Jinja plugin | None | Per-OS module logic | Go templates, builtin |
| Native Windows support | No (Cygwin/MSYS only) | No (relies on shell) | No | No | Yes |
| Secret management | None | gpg/transcrypt | None | sops/agenix | bitwarden*, gpg, age, custom — all builtin |
| Encryption | None | gpg | None | sops/agenix via overlay | age + gpg builtin |
| Package install | None | None | YAML plugin | First-class (the whole point) | run_onchange_ scripts (we wire it) |
| External archives | N/A | git remotes | submodules | flake inputs | `.chezmoiexternal` |
| Single binary | No (Perl) | No (bash + git) | No (Python) | No (Nix + Nixpkgs) | Yes, Go static |
| Idempotent apply | Limited | Yes | Plugin-dependent | Yes (declarative) | Yes |

**Takeaway:** chezmoi covers the union of features we need (cross-OS templating + secrets + encryption + Windows + idempotent scripts + single binary) better than any single competitor on the list, *which is exactly why the locked decision is "stay on chezmoi."* The features above that map to chezmoi capabilities are the table-stakes catalog; the features that don't have a chezmoi equivalent (e.g., Nix's pure-functional package resolution) are correctly absent from this fleet's requirements.

---

## Implications for the Planner

1. **Phase 0 is the foundation and must land first.** 3-role taxonomy + packages.yaml refactor + Mac diff-empty validation + VaultWarden integration + canonical GPG + per-purpose SSH + encrypted bootstrap kit. Everything else depends on this.

2. **Windows-native is the single biggest lift.** Quote it generously. It introduces a new shell (PowerShell), a new package manager (winget), a new scripting dialect (`.ps1.tmpl`), and a new path convention. WSL greenfield depends on Windows-native landing first.

3. **Several P2 items are parallel-safe and can ship out-of-order.** Session 59 Claude Code, `dot_topics/` docs, Lonestar playbook — these don't block each other and don't block anything else. They can be opportunistic.

4. **The encrypted bootstrap kit deserves explicit phase scope.** It's tempting to treat it as "a few files in the repo" but the *contents design* + *key stewardship strategy* is the actual work. Don't underweight.

5. **Cross-OS asymmetry table above is the planner's main estimation aid.** Features that look uniform on paper have a HIGH-complexity tail on Windows. If a phase touches Windows, multiply the estimate.

6. **Anti-features should be referenced from the roadmap explicitly** — they're the "we said no to this" record that prevents scope creep when a future idea surfaces. Link the roadmap's "out of scope" section to this file.

---

## Sources

- [chezmoi: One Dotfiles Repo Across macOS, Linux, and Windows (dev.to)](https://dev.to/recca0120/chezmoi-one-dotfiles-repo-across-macos-linux-and-windows-2o3) — overall cross-OS pattern survey
- [chezmoi Comparison Table (official)](https://www.chezmoi.io/comparison-table/) — competitor analysis
- [chezmoi Bitwarden user guide (official)](https://www.chezmoi.io/user-guide/password-managers/bitwarden/) — VaultWarden integration patterns
- [chezmoi Bitwarden template functions reference (official)](https://www.chezmoi.io/reference/templates/bitwarden-functions/) — bitwarden*/bitwardenFields/bitwardenSecrets API
- [chezmoi Include files from elsewhere (official)](https://www.chezmoi.io/user-guide/include-files-from-elsewhere/) — `.chezmoiexternal.toml` capabilities
- [chezmoi Windows guide (official)](https://www.chezmoi.io/user-guide/machines/windows/) — pwsh.exe vs powershell.exe fallback, path conventions
- [chezmoi Use scripts to perform actions (official)](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/) — `run_onchange_` idempotency, SHA256 tracking
- [chezmoi `.chezmoiignore` reference (official)](https://www.chezmoi.io/reference/special-files/chezmoiignore/) — conditional gating syntax
- [chezmoi Manage machine-to-machine differences (official)](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/) — per-machine variant patterns
- [chezmoi Encryption FAQ (official)](https://www.chezmoi.io/user-guide/frequently-asked-questions/encryption/) — age key stewardship, lose-key-lose-everything warning
- [chezmoi age encryption guide (official)](https://www.chezmoi.io/user-guide/encryption/age/) — bootstrap kit implementation reference
- [chezmoi Template variables reference (official)](https://www.chezmoi.io/reference/templates/variables/) — `.chezmoi.kernel.osrelease` for WSL detection
- [GitHub Issue twpayne/chezmoi#4942 — Test if I am in WSL2 inside a template](https://github.com/twpayne/chezmoi/issues/4942) — WSL detection pattern verified
- [jwnmulder/dotfiles (Linux + WSL2 + Windows reference repo)](https://github.com/jwnmulder/dotfiles) — real-world WSL+Windows+Linux chezmoi patterns
- [karnzx/dotfiles (WSL2 + Linux + macOS reference repo)](https://github.com/karnzx/dotfiles) — cross-OS topic-loader patterns
- [mimikun/dotfiles-windows (Windows-only chezmoi reference)](https://github.com/mimikun/dotfiles-windows) — winget + pwsh + chezmoi patterns
- [Jaykul/dotfiles (PowerShell profile + chezmoi reference)](https://github.com/Jaykul/dotfiles) — pwsh profile management via chezmoi
- [Starship cross-shell prompt (official)](https://starship.rs/) — cross-OS prompt parity
- [Atuin shell history (search results)](https://mylinux.work/guides/modern-linux-shell-toolkit/) — cross-OS history sync option
- [Configuring SSH Keys for Multiple GitHub Accounts (Steven Harman)](https://stevenharman.net/configure-ssh-keys-for-multiple-github-accounts) — Host alias pattern for per-purpose keys
- [Mike Kasberg — Dotfiles Secrets in Chezmoi, Without Password Headaches](https://www.mikekasberg.com/blog/2026/01/31/dotfiles-secrets-in-chezmoi.html) — bitwarden session-unlock pattern

---
*Feature research for: multi-OS dotfile management (chezmoi modernization, 7-machine fleet)*
*Researched: 2026-05-27*
