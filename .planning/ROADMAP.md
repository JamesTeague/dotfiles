# Roadmap: chezmoi Modernization

**Created:** 2026-05-27
**Granularity:** coarse
**Parallelization:** true
**Phase count:** 6 (non-standard numbering: 0.5, 0, 1, 2, 3, 4)
**Coverage:** 69/69 v1 requirements mapped

## Core Value

A new machine — any OS in the fleet — can be set up day-1 via a single `chezmoi init --apply` flow (plus VaultWarden login + GitHub PAT for HTTPS clone bootstrap) and arrive at a fully-configured, identity-signed, role-appropriate state without artisanal touch-up.

## Phases

- [x] **Phase 0.5: Audit & Documentation** — Defensible baseline of conventions + dead-config removal before any structural change (zero apply risk) — **CLOSED 2026-05-29** (6/6 plans, 6 requirements, both-Mac gate PASS via 1 justified escalation)
- [ ] **Phase 0: Structural Refactor** — Land the `role × personal × os × wsl` taxonomy on a branch with `chezmoi diff` empty on both Macs as merge gate
- [ ] **Phase 1: VaultWarden + Secret Plane + Bootstrap Kit** — Credential plane (GPG canonical + per-purpose SSH) AND disaster-recovery fallback land together
- [ ] **Phase 2: Windows-Native Support** — pwsh + winget + Stream Deck + role=gaming + role=lite all share Windows infrastructure
- [ ] **Phase 3: WSL Greenfield** — Two-application boundary (`.wslconfig` on host + `wsl.conf` inside WSL) + Linux apt/mise
- [ ] **Phase 4: Lonestar Onboarding + Polish** — Hardening, docs, first end-to-end onboarding as the real acceptance test

## Phase Details

### Phase 0.5: Audit & Documentation

**Goal**: Repo conventions are documented, dead packages dropped, line-ending hygiene enforced, and existing active machines confirm zero diff — defensible baseline before any structural change touches templates.

**Depends on**: Nothing (first phase)

**Requirements**: AUD-01, AUD-02, AUD-03, AUD-04, AUD-05, SS-01

**Success Criteria** (what must be TRUE):
  1. `docs/dot_topics.md` and `docs/conventions.md` exist and document the `dot_topics/<tool>/{path,eval,config,install}.zsh|sh` convention + the inherited structural decisions (`.chezmoiroot = home`, `.chezmoiscripts/` layout, externals refresh policy)
  2. Orphaned `home/private_dot_config/flameshot/` is removed; dead `packages.yaml` entries (abandonware taps/casks/brews) are removed; `personal/work.{core,darwin,linux}` nesting inconsistencies inside the current shape are normalized (NO axis restructuring yet)
  3. `.gitattributes` exists at repo root enforcing `*.tmpl text eol=lf` (Windows line-ending hygiene precondition for Phase 2)
  4. Shottr remains installed on Mac via existing `darwin.casks.personal` (baseline verified untouched)
  5. `chezmoi diff` on Mac personal AND Mac work both produce zero functional diff after the audit pass — this is the phase exit gate

**Pitfall mitigations baked in**:
- Pitfall 22 (`dot_topics/` undocumented) → resolved by docs/dot_topics.md
- Pitfall 4 / line-ending drift → `.gitattributes` lands here so source files are LF-clean before any Windows work begins

**Plans**: 6 plans
- [x] 00.5-01-wave0-harness-PLAN.md — Wave 0 harness (lib.sh/quick.sh/full.sh) + candidate-list + state-preview scaffolds + SS-01 verification (completed 2026-05-27)
- [x] 00.5-02-docs-PLAN.md — docs/conventions.md + docs/dot_topics.md (AUD-05; live-tree-grounded, with Teague accuracy review) (completed 2026-05-28)
- [x] 00.5-03-gitattributes-statepeek-PLAN.md — .gitattributes Mac personal (AUD-04 partial) + Mac personal chezmoi state capture into 00.5-state-preview.md (completed 2026-05-27)
- [x] 00.5-04-flameshot-removal-PLAN.md — AUD-03: source delete + Mac personal destination cleanup (Pitfall C resolution) (completed 2026-05-27; state-only cleanup per Teague approval to preserve Plan 06's .zshrc reconciliation territory)
- [x] 00.5-05-packages-audit-PLAN.md — AUD-01 + AUD-02 LIGHT: candidate analysis (Teague-reviewed), packages.yaml pruned/moved/renamed, approved-brew-bundle snapshot captured (completed 2026-05-28; decision-merge fallback applied — Decision overrides Recommendation, blank → Recommendation)
- [ ] 00.5-06-exit-gate-PLAN.md — Mac personal drift reconciliation + Mac work CRLF pre-check + Mac work state capture + HARD exit-gate diff on both Macs

---

### Phase 0: Structural Refactor

**Goal**: The `role × personal × os × wsl` taxonomy lands atomically on a branch with no functional change on currently-active Mac machines. `generate-gpg-key.sh` is DELETED (not renamed). Per-machine cutover ritual is documented.

**Depends on**: Phase 0.5 (audit must complete before structural change)

**Requirements**: TAX-01, TAX-02, TAX-03, TAX-04, TAX-05, TAX-06, TAX-07, TAX-08, SEC-05, LNX-05, SS-03

**Success Criteria** (what must be TRUE):
  1. User runs `chezmoi init --apply` on Mac personal and Mac work, is prompted ONCE for `role` (default `dev`), and the persisted `~/.config/chezmoi/chezmoi.toml` on each gains the `role` key without re-prompting on subsequent applies — `promptStringOnce` discipline verified
  2. `.chezmoidata/packages.yaml` is restructured around `roles.<role>.<os>` + `overlays.personal.<os>` + `overlays.work.<os>`; `.chezmoiignore` is templated and acts as the single gating decision point for OS / role / personal / wsl
  3. `chezmoi apply --dry-run --verbose | grep -i 'no value'` returns nothing on BOTH active Macs (no template renders against a missing key)
  4. `chezmoi diff` on Mac personal AND Mac work both produce zero functional diff after the refactor branch is applied — this is the merge gate
  5. `home/scripts/generate-gpg-key.sh` is DELETED from the source tree (not renamed); the per-machine cutover ritual documents how to verify `chezmoistate.boltdb` won't re-fire it
  6. Flameshot config preserved at `private_dot_config/flameshot/` is gated to `role=dev + os=linux + not wsl` in the templated `.chezmoiignore` (dormant until a real Linux laptop materializes)
  7. Explicit decision recorded: NO Linux Homebrew anywhere — `.chezmoiscripts/linux/` skeleton uses apt + mise only

**Pitfall mitigations baked in**:
- Pitfall 1 (`promptStringOnce` discipline) → every new key uses `promptStringOnce`; documented `chezmoi init --apply` re-run ritual per existing machine
- Pitfall 2 (`chezmoi diff` blind to script side-effects) → cutover ritual pairs `diff` with `apply --dry-run --verbose`
- Pitfall 9 (renaming variables → silent `<no value>`) → pre-flight grep + `chezmoi execute-template` pass on fixture data documented as part of cutover
- Pitfall 11 (`run_once_` state survives refactors) → `generate-gpg-key.sh` is DELETED, not renamed; script-state audit is a line-item

**Plans:** 3 plans (sequential — three commits paralleling three plans; mas-guard MUST land after structural so the merge-gate diff stays pure)

Plans:
- [x] 0-01-structural-PLAN.md — structural taxonomy cut (role × personal × os × wsl): packages.yaml restructure, .chezmoiignore templating, brew/03-mas consumer rewrite, exact_bin teardown, hasKey loud-fail guard, flameshot re-stage, Wave 0 harness, cutover-phase-0.sh artifact
- [x] 0-02-mas-guard-PLAN.md — `03-mas.sh.tmpl` `/Applications/<App>.app` pre-check around `mas install` (resolves 0.5 follow-up #4 + Pitfall mas-list-Apple-ID-invisibility)
- [x] 0-03-docs-PLAN.md — `docs/conventions.md` § 10 update: AUD-02 LIGHT remainder + goal amendments + 5 follow-up pitfall notes + `.localrc`/`~/.local/bin/` pattern + LNX-05 locked decision (completed 2026-06-03)

**Goal amendments (from 0-CONTEXT.md — supersede Success Criteria above):**
- SC #5 (generate-gpg-key.sh deletion) DEFERRED to Phase 1 — script is load-bearing via home/modify_dot_gitconfig.local:6 modify-template
- SC #2 (.chezmoiignore single gating point) reframed to FILE PRESENCE ONLY; template-internal runtime logic stays in templates
- Add .localrc + ~/.local/bin/ employer-local pattern documentation (resolves 0.5 follow-ups #6 + #9)

---

### Phase 1: VaultWarden + Secret Plane + Bootstrap Kit

**Goal**: User can `git commit -S` and `ssh -T git@github-personal` on first machine setup. VaultWarden is the credential plane; the age-encrypted bootstrap kit is the documented fallback for when the Cloudflare tunnel is down. Vault-offline drill is executed before phase close — not deferred.

**Depends on**: Phase 0 (taxonomy must resolve before `bitwarden*` template gating fires)

**Requirements**: SEC-01, SEC-02, SEC-03, SEC-04, SEC-06, SEC-07, SEC-08, SEC-09, SEC-10, BOOT-01, BOOT-02, BOOT-03, BOOT-04, BOOT-05

**Success Criteria** (what must be TRUE):
  1. User unlocks the machine, runs `chezmoi apply`, and chezmoi auto-unlocks VaultWarden via `bitwarden.unlock = "auto"` — no manual `BW_SESSION` ritual
  2. Canonical GPG signing key is retrieved from VaultWarden via `bitwardenAttachment`, ownertrust is imported via `run_once_after_*` hook, and `git commit -S` actually produces a signed commit (verified via `git log --show-signature`) on first setup
  3. Per-purpose SSH keys (`personal-github` + `work-github` minimum) are retrieved from VaultWarden; `~/.ssh/config` uses `Host github-personal` / `Host github-work` aliases; chezmoi's own git remote is rewritten to `git@github-personal:JamesTeague/dotfiles.git`; `ssh -vT git@github-personal` shows the correct fingerprint
  4. `bw` CLI version is PINNED in `packages.yaml` against the live VaultWarden 1.36.0; the working CLI/server pair is documented (anti-Pitfall-3)
  5. `bootstrap/encrypted_essentials.age` exists in the repo containing canonical GPG key + primary SSH key + GitHub PAT; age identity is stored OFF-repo (paper backup + hardware token strategy documented in `bootstrap/README.md`); an offline known-good `bw` binary is embedded in the bootstrap kit
  6. **Vault-offline drill executed**: with cloudflared deliberately stopped, `chezmoi apply` either falls back via the bootstrap-kit recovery path OR fails loud with an actionable message (NO silent failure). Drill outcome documented before phase close.

**Pitfall mitigations baked in**:
- Pitfall 3 (VaultWarden ↔ bw CLI drift) → version pin + documented compat pair + offline known-good binary in bootstrap kit
- Pitfall 10 (VaultWarden unreachable bricks routine apply) → bootstrap kit lands in THIS phase, not deferred to Phase 4; vault-offline drill is a phase-exit requirement
- Pitfall 14 (GPG key imported without trust) → `run_once_after_*` ownertrust import is part of the GPG ceremony
- Pitfall 15 (per-purpose keys + remote URL mismatch) → chezmoi repo's git remote is rewritten as part of phase close

**Plans**: TBD

---

### Phase 2: Windows-Native Support

**Goal**: A fresh Windows VM bootstraps end-to-end via `chezmoi init --apply` from an elevated pwsh 7+ terminal. Covers `role=gaming` (gaming rig) and `role=lite` (spiral index) together because they share PowerShell profile, winget plumbing, and the Windows package list infrastructure.

**Depends on**: Phase 1 (SSH keys must exist for the Windows machines to pull the private repo; GPG must be available for signing on Windows dev work)

**Requirements**: WIN-01, WIN-02, WIN-03, WIN-04, WIN-05, WIN-06, WIN-07, WIN-08, WIN-09, WIN-10, GAM-01, GAM-02, GAM-03, GAM-04, LIT-01, LIT-02, LIT-03, LIT-04, SS-02, PAR-01, PAR-02

**Success Criteria** (what must be TRUE):
  1. `.chezmoi.toml.tmpl` includes `[interpreters.ps1]` with `-ExecutionPolicy Bypass` flag; every `.ps1.tmpl` includes the chezmoi line-ending directive at top in the SINGULAR form `chezmoi:template:line-ending=native` (verified by inspection; Pitfall 4 doc/code drift mitigated)
  2. Windows bootstrap README documents the three prerequisites pwsh 7+ pre-installed, ExecutionPolicy configured, elevated first-run — and the fresh-VM dry-run is executed and recorded
  3. `winget configure --file winget-configure.yaml` runs from `.chezmoiscripts/windows/run_onchange_*.ps1.tmpl` and produces installs for `roles.gaming.windows` (Steam, OBS, Discord, Chrome, GIMP, Audacity, Handbrake, HWiNFO64, CPU-Z, GPU-Z, WezTerm, Claude desktop, Epic, EA, Rockstar Launcher, Google Drive, Office, GeForce Experience, Stream Deck, 7-Zip, VLC, MullvadVPN, Bitwarden, PicPick) AND `roles.lite.windows` (Chrome, Office, Bitwarden, PicPick) — installs succeed end-to-end with explicit exit-code checking (anti-Pitfall-8)
  4. PowerShell profile at `Documents/PowerShell/Microsoft.PowerShell_profile.ps1` loads cleanly on a fresh pwsh session with starship prompt + PSReadLine predictive history; the SAME `~/.config/starship.toml` works across zsh, bash, and pwsh (cross-OS prompt parity, PAR-01); PSReadLine ships bundled with pwsh 7.6.x (do NOT `Install-Module PSReadLine -Force`)
  5. PicPick installs on every Windows role; Stream Deck binary `.streamDeckProfile` files at `AppData/Roaming/Elgato/StreamDeck/ProfilesV2/` are gated to `role=gaming` and actually load in the Stream Deck app post-apply (not just placed at the right path)
  6. Vendor-only software (RODE Central, RODECaster Pro, Insta360 Link Controller) is documented as manual-install in README; spiral-index `.msi` flash-drive workflow is documented; both gaming rig AND spiral index successfully bootstrap from `chezmoi init --apply` end-to-end as the phase exit gate

**Pitfall mitigations baked in**:
- Pitfall 4 (line-ending directive drift) → singular form `chezmoi:template:line-ending=native` mandated; `.gitattributes` from Phase 0.5 already keeps source LF
- Pitfall 7 (PowerShell execution policy blocks apply) → `[interpreters.ps1]` configured with `-ExecutionPolicy Bypass`; pwsh 7+ prerequisite documented
- Pitfall 8 (winget UAC swallowed) → elevated-first-run documented; explicit exit-code checking in install loop; `--silent --accept-*` flags used
- Pitfall 12 (Windows AppData paths outside `%USERPROFILE%`) → literal `AppData/` layout mirrored under source; Stream Deck placement uses the same pattern

**Plans**: TBD

---

### Phase 3: WSL Greenfield

**Goal**: WSL on the gaming rig is rebuilt from a clean `wsl --unregister Ubuntu` → `wsl --install -d Ubuntu` → `chezmoi init --apply` flow. `role=dev + os=linux + wsl=true` produces a working dev environment with shell parity to Mac dev, signed-git-commits via Gpg4win on the Windows host, and `code .` interop.

**Depends on**: Phase 2 (`.wslconfig` is a Windows-host artifact; the Windows source tree must exist before the host-side application can land it)

**Requirements**: LNX-01, LNX-02, LNX-03, LNX-04, WSL-01, WSL-02, WSL-03, WSL-04, WSL-05, WSL-06, WSL-07, WSL-08, WSL-09

**Success Criteria** (what must be TRUE):
  1. `private_dot_wslconfig.tmpl` lives in the Windows source tree and renders to `%USERPROFILE%\.wslconfig` (Windows-host apply) with memory/processors/swap limits + `networkingMode=mirrored` + `autoMemoryReclaim` + `sparseVhd=true`
  2. `etc/wsl.conf.tmpl` lives in the WSL source tree and configures `[boot] systemd=true`, `[automount] options="metadata,umask=22,fmask=11"`, and a deliberate `[interop] appendWindowsPath` decision (recorded in commit message + docs); if `appendWindowsPath=false` is chosen, a narrow re-add list for `code`, `clip.exe`, `explorer.exe` is shipped in WSL `.zshrc.tmpl` (anti-Pitfall-5)
  3. `wsl --version` is the first thing the WSL bootstrap script checks; bootstrap fails loud with "upgrade WSL: `wsl --update`" if < 0.67.6 (systemd requires it)
  4. `packages.yaml roles.dev.linux` includes the apt list + the mise tool list (separate keys); `run_onchange_*.sh.tmpl` installs apt packages idempotently (re-run trigger = SHA of packages.yaml) and `run_onchange_*.sh.tmpl` installs mise tools from `~/.config/mise/config.toml`
  5. WSL inherits Mac dev's shell config (zsh + starship + atuin + tmux + topics); SSH keys in WSL live in the WSL native filesystem (NOT under `/mnt/c/`) and survive `wsl --shutdown` with `0600` permissions intact (anti-Pitfall-6)
  6. Canonical-agent rule: Gpg4win on the Windows host is the single ssh-agent; WSL routes `SSH_AUTH_SOCK` via `wsl-ssh-pageant` (or current best-practice equivalent) — the three-agents-pick-one decision is documented
  7. Phase-exit acceptance: `code .` from WSL launches Windows VS Code; `systemctl status` works inside WSL; `git commit -S` from WSL signs via Gpg4win agent on the host

**Pitfall mitigations baked in**:
- Pitfall 5 (`appendWindowsPath=false` breaks `code` / `clip` / `explorer`) → decision is explicit; if false, narrow re-add list is shipped
- Pitfall 6 (`/mnt/c` strips key permissions; three-agents confusion) → SSH key in WSL native fs; canonical Gpg4win agent rule documented
- Pitfall 16 (WSL < 0.67.6 silently ignores `systemd=true`) → `wsl --version` gate as first bootstrap step

**Plans**: TBD

---

### Phase 4: Lonestar Onboarding + Polish

**Goal**: Documentation, Claude Code integration, and the first real end-to-end Lonestar onboarding as the actual acceptance test of the whole modernization. If Phases 0-3 are clean, this is hardening + polish.

**Depends on**: Phase 3 (all role/OS axes must exist; Lonestar's OS is TBD and could exercise any of them)

**Requirements**: LON-01, LON-02, LON-03, LON-04

**Success Criteria** (what must be TRUE):
  1. README has OS-specific "new machine bootstrap" sections — one each for darwin, linux, windows, wsl — each documenting the manual prerequisites (pwsh 7+ install, ExecPolicy, elevated first-run for Windows; `wsl --version` for WSL; HTTPS PAT for first clone everywhere)
  2. `ROLES.md` exists describing each role's purpose, package inventory, what's included vs excluded — the documentation `chezmoi managed` can be cross-checked against
  3. Session 59's Claude Code integration is folded in: `settings.json.tmpl` for hook paths + `~/dev/CLAUDE.md` for project conventions, gated by `personal` flag in `.chezmoiignore` (does NOT appear on work machines)
  4. Lonestar machine (when received) bootstraps end-to-end via the documented procedure on first try — the "Looks Done But Isn't" checklist from PITFALLS.md is run as final acceptance and any gaps discovered feed back into the relevant README

**Pitfall mitigations baked in**:
- "Looks Done But Isn't" checklist from PITFALLS.md is run as a phase-exit ritual
- Lonestar onboarding is treated as a real test (not "it built means it works"); discovered gaps trigger doc updates in earlier phases

**Plans**: TBD

---

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 0.5. Audit & Documentation | 5/6 | In progress | - |
| 0. Structural Refactor | 3/3 | In progress (awaiting cutover verification) | - |
| 1. VaultWarden + Secret Plane + Bootstrap Kit | 0/? | Not started | - |
| 2. Windows-Native Support | 0/? | Not started | - |
| 3. WSL Greenfield | 0/? | Not started | - |
| 4. Lonestar Onboarding + Polish | 0/? | Not started | - |

## Phase Ordering Rationale

**Strict hard orderings:**
- **0.5 → 0 → 1 is strict.** Audit before refactor (establish defensible baseline); refactor before secret plane (`.role` must resolve before `bitwarden*` template gating fires).
- **Phase 2 (Windows) → Phase 3 (WSL) is strict.** `.wslconfig` is a Windows-host artifact; chezmoi runs once on the host AND separately inside WSL — a single apply cannot span the boundary.
- **Bootstrap kit lives in Phase 1, NOT Phase 4.** Treating disaster recovery as "later" is the failure mode. The vault-offline drill is a Phase 1 exit requirement.
- **`generate-gpg-key.sh` DELETION is a Phase 0 line-item, not a footnote.** Renaming = old hash re-fires on machines that have it in state = NEW canonical key on every existing machine = security incident.

**Combined roles in Phase 2 rationale:**
- `role=gaming` (gaming rig) and `role=lite` (spiral index) are NOT split into separate phases because they share Windows-native infrastructure: same package list mechanism, same PowerShell profile primitives, same winget + DSC YAML plumbing, same line-ending directive discipline. Splitting them would create artificial phase boundaries and duplicate work.

## Coverage Validation

| Phase | Requirement Count | IDs |
|-------|-------------------|-----|
| 0.5 | 6 | AUD-01, AUD-02, AUD-03, AUD-04, AUD-05, SS-01 |
| 0 | 11 | TAX-01..08, SEC-05, LNX-05, SS-03 |
| 1 | 14 | SEC-01, SEC-02, SEC-03, SEC-04, SEC-06, SEC-07, SEC-08, SEC-09, SEC-10, BOOT-01..05 |
| 2 | 21 | WIN-01..10, GAM-01..04, LIT-01..04, SS-02, PAR-01, PAR-02 |
| 3 | 13 | LNX-01..04, WSL-01..09 |
| 4 | 4 | LON-01..04 |

**Total v1 requirements:** 69
**Mapped to phases:** 69
**Unmapped (orphaned):** 0
**Coverage:** 100% ✓

---
*Roadmap created: 2026-05-27*
*Granularity: coarse | Parallelization: enabled*
