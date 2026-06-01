# Phase 0: Structural Refactor — Research

**Researched:** 2026-06-01
**Domain:** chezmoi taxonomy refactor — `role × personal × os × wsl` axis lands atomically on a branch with zero functional diff on both active Macs
**Confidence:** HIGH (mechanics verified against current chezmoi docs + local 2.70.4 binary; CONTEXT.md decisions confirmed mechanically sound)

## Summary

Phase 0 is a structural cut, not a feature add. The locked decisions in CONTEXT.md are mechanically sound after cross-verification against current chezmoi documentation and the local 2.70.4 binary: `promptChoiceOnce` does persist via the existing chezmoi.toml data map and re-prompts only on missing keys; `.chezmoiignore` is template-evaluated on every apply (no cache); `chezmoi state delete` documented form `--bucket=X --key=Y` works under zsh on 2.70.4 but breaks on 2.69.4 (the version-skew justifies the cutover-script preflight); `exact_` directives do NOT auto-remove destinations when the source directory is removed wholesale — explicit `rm -rf` of the destination is mandatory; `chezmoi execute-template --init --promptString k=v` is the canonical dry-run validator.

Three operational quantities matter for plan structure: (1) the files-modified inventory is small and bounded (10 source files + 5 file moves + 1 new artifact), (2) the three logical commits identified in CONTEXT.md are sequential (mas-guard MUST land after structural so the merge-gate diff is pure), (3) verification is automated for the merge gate (`chezmoi diff -x externals` + `apply --dry-run --verbose | grep "no value"`) but requires human hands per-machine for cutover (CLAUDE.md "manual work = collaborative mode" rule applies).

**Primary recommendation:** Three plan files paralleling the three commits — Plan 01 (structural + cutover script), Plan 02 (mas guard), Plan 03 (docs). Each plan ends with the cutover-script-runnable invariant intact (chezmoi `diff` clean after a cold `init --apply` on both Macs), but the cutover script itself is RUN only after merge — plans 01-03 land source-tree changes; the actual Mac-personal + Mac-work cutover is operator-driven in main-context collaborative mode per CLAUDE.md, not autonomous.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Goal Amendments to inherited ROADMAP Phase 0 goal:**

1. **DROP SC #5** (`home/scripts/generate-gpg-key.sh` is DELETED from the source tree). The script is load-bearing via `home/modify_dot_gitconfig.local:6` (chezmoi modify-template that runs on every apply, captures script stdout as `~/.gitconfig.local` content). Deleting it in Phase 0 breaks `git commit -S` on next apply. Deferred to Phase 1, which already owns the atomic VaultWarden-canonical-GPG-key landing — script delete + `modify_dot_gitconfig.local` rewrite happen together as part of SEC-* requirements.

2. **DROP Pitfall 11 reference** for `generate-gpg-key.sh`. Pitfall 11 is "`run_once_` state survives refactors." This script is NOT a `run_once_` — `chezmoistate.boltdb` dump (Phase 0.5 capture) confirmed zero `scriptState` entries for it; it lives in `entryState` (regular file). Pitfall 11 still applies generally to Phase 0 script renames, just not to this specific script.

3. **REFRAME SC #2** "`.chezmoiignore` … single gating decision point." Interpretation: FILE PRESENCE only. Template-internal runtime logic (e.g., `{{ if eq .chezmoi.os "darwin" }}` blocks inside scripts) stays in templates; `.chezmoiignore` can only gate whether a file exists at the destination at all.

4. **ADD** `.localrc` + `~/.local/bin/` employer-local pattern documentation. Resolves Phase 0.5 follow-ups #6 (NODE_EXTRA_CA_CERTS escalation) and #9 (`exact_bin` rename / standardize). NOT a 5th axis — `dot_zshrc.tmpl:4-7` already sources `~/.localrc`, and `~/.local/bin/` is already first on PATH via mise. Pattern is "personal-identity stays in chezmoi; employer/site-local stays per-machine."

**Employer Axis (resolves follow-up #6):** Per-machine `~/.localrc` + `~/.local/bin/`. Not a 5th axis. Mac work cutover hand-migrates the existing `NODE_EXTRA_CA_CERTS=...` line from `~/.zshrc` to `~/.localrc`. Cutover script autodetects via `grep -q NODE_EXTRA_CA_CERTS ~/.zshrc`.

**exact_bin Teardown (resolves follow-up #9):** Delete `home/exact_bin/`; move 5 scripts to `home/private_dot_local/bin/`. The 5 utilities (`dot.tmpl`, `git-bare-clone`, `git-wtf`, `tmux-cht.sh`, `tmux-sessionizer`) are personal-identity — keep chezmoi-managed. Both tmux scripts invoked by bare command name; `~/.local/bin/` is first on PATH via mise. Per-machine cutover side effect: `~/bin/` directory becomes unmanaged but files persist (chezmoi's `exact_` directive only enforced while source carries `exact_bin/`). Cutover script does `rm -rf ~/bin/` followed by 5× `chezmoi state delete --bucket=entryState --key /Users/jteague/bin/<entry>` for state hygiene. Use space-separated `--key /path` form (follow-up #7: `--key=` triggers zsh CLI parsing pitfall on 2.69.4).

**packages.yaml Restructure (new shape):**
```yaml
packages:
  roles:
    dev:
      core: {brews, taps}       # cross-OS dev essentials
      darwin: {brews, casks, taps}
      linux: {brews, casks, taps}
  overlays:
    personal:
      darwin: {brews, casks, mas, taps}
    work:
      darwin: {brews, casks, taps}
```
- Q1: Push current `core` into `roles.dev.core` (cross-OS dev-role-universal). Name continuity preserved.
- Q2: Current `core.casks` lands in `roles.dev.darwin.casks` (Mac casks misfile resolved as Q1 side-effect).
- Q3: Drop move-history comments. Keep only the load-bearing `localstack-cli` warning (trimmed).
- Q4: Prune empty placeholders; consumer uses `hasKey`. Overlays don't get a cross-OS `core` layer.
- Q5: ~131 line packages.yaml + ~123 line brew partial rewrite (6 copy-pasted personal/else-work branches kept — DRY refactor YAGNI for 6 branches) + 7→12 line 03-mas.sh.tmpl. **4 latent Linux-overlay bugs fixed inline** (`brew` template lines 70-78 say `tap` when they mean `brew`; lines 110-118 say `tap` when they mean `cask`).

**Role Prompt:**
- Values: `dev | gaming | lite`
- Default: `dev`
- Function: `promptChoiceOnce` (built-in typo validation; persists once)
- Enum DRY: Hardcode in `.chezmoi.toml.tmpl` + consumer templates (3 values, factoring YAGNI)
- Loud-fail guard: `{{ if not (hasKey . "role") }}{{ fail "Role not set. Run: chezmoi init --apply" }}{{ end }}` in `02-install-packages.sh.tmpl`
- Chezmoi version floor: ≥ 2.70.4 enforced as cutover preflight (Mac work currently 2.69.4 — bump is part of cutover, not optional)

**.chezmoiignore Templating (file-presence only; runtime logic stays in templates):**
- `home/private_dot_config/aerospace/` → darwin only
- `home/private_dot_config/flameshot/` → linux + not wsl + role=dev (per SC #6)
- `home/.chezmoiscripts/run_onchange_after_darwin-configure.sh.tmpl` → darwin only
- `home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl` → darwin + not wsl
- Preserve existing `.oh-my-zsh/cache/**` line
- Style: conditional-include grouped by gate
- No pre-stubbing of Windows/gaming/lite files — Phase 2/3 land those.
- Consolidation payoff: drop template-internal OS gates from gated templates. `03-mas.sh` body simplifies from full and-chain to `{{ if .personal }}` (presence guarantees darwin + not-wsl).

**Cutover Ritual:**
- Scope: Mac work + Mac personal only. Lonestar status unclear; fresh `chezmoi init` when it lands (no cutover applicable).
- Artifact: `.planning/phases/0-structural-refactor/cutover-phase-0.sh`, versioned with phase.
- Per-machine usage: `cd ~/.local/share/chezmoi && git checkout <phase-0-branch> && git pull` → `bash .planning/phases/0-structural-refactor/cutover-phase-0.sh` → answer role prompt interactively (`dev`).
- **Script steps (locked, 8-step):**
  1. Print snapshot path FIRST (before any mutation) — failure mid-script leaves known restore point: `~/dotfiles-cutover-snapshot-<timestamp>/`
  2. Preflight: `chezmoi --version` ≥ 2.70.4; die loud if not
  3. Snapshot (targeted, not full `~/.config/`): `chezmoi.toml`, `.zshrc`, `.localrc` (if exists), `.gitconfig.local`, `-a ~/bin/`
  4. Pre-pull migration (autodetect Mac work): if `grep -q NODE_EXTRA_CA_CERTS ~/.zshrc`, append line to `~/.localrc` and `sed` delete from `~/.zshrc`; print "Detected Mac work: migrated NODE_EXTRA_CA_CERTS"
  5. `chezmoi init --apply` — role prompt fires interactively (intentional; one keystroke per machine acknowledges role). Pre-existing prompts skipped via `*Once`.
  6. exact_bin teardown: `rm -rf ~/bin/`; 5× `chezmoi state delete --bucket=entryState --key /Users/jteague/bin/<entry> || true` (space-separated `--key /path` form per follow-up #7)
  7. Verify SC #4: `chezmoi diff -x externals` empty
  8. Verify SC #3: `chezmoi apply --dry-run --verbose 2>&1 | grep "no value"` empty
- `set -euo pipefail`. On verify-gate failure, exit non-zero — manual recovery from snapshot. No auto-rollback.

**Three-Commit Breakdown:**
1. **Structural commit** — packages.yaml restructure + role prompt + `.chezmoiignore` templating + `exact_bin` teardown + brew/03-mas consumer rewrite + 4 inline Linux-overlay bug fixes + cutover script. Merge gate runs against THIS.
2. **Mas guard commit** — `03-mas.sh` `/Applications/<App>.app` presence pre-check (follow-up #4). Separate so structural diff is pure.
3. **Docs commit** — `docs/conventions.md` § 10 update: AUD-02 LIGHT remainder + follow-ups #1, #2, #3, #5, #8 as pitfall/pattern notes.

**Phase 0.5 Follow-ups Disposition:**

| # | Disposition |
|---|---|
| 1 | docs commit: `chezmoi state dump` as canonical clean-check utility |
| 2 | docs commit: pitfall — `chezmoi apply --dry-run --verbose` exits nonzero on interactive TTY prompts |
| 3 | docs commit: pitfall — `mas list` Apple ID visibility (mas guard from #4 is the practical fix) |
| 4 | code: separate commit, `03-mas.sh` `/Applications/` guard |
| 5 | docs commit: state-forge pattern documentation |
| 6 | absorbed: `.localrc` + Mac-work NODE_EXTRA_CA_CERTS migration in cutover script |
| 7 | code: cutover script preflight (≥2.70.4) + `--key /path` space-separated form |
| 8 | docs commit: Pitfall C re-validation note |
| 9 | absorbed: `exact_bin` teardown → `private_dot_local/bin/` in structural commit |

### Claude's Discretion

- Plan-file split: structural + mas guard + docs as separate plan files vs. one plan with internal commit boundaries (lean: three plans, parallels the three commits)
- Exact cutover-script filename if `cutover-phase-0.sh` is awkward
- Exact format of snapshot directory layout
- Exact wording of `docs/conventions.md` § 10 additions
- Order of plan execution (lean: structural → mas guard → docs; cutover script is committed with structural but RUN after merge)
- Whether the cutover script lives only in `.planning/` or also gets a symlink/copy in `scripts/` for discoverability (lean: `.planning/` only — phase-scoped, not permanent tool)

### Deferred Ideas (OUT OF SCOPE)

- **Apple ID provenance audit script** (follow-up #3 strong form) — file-presence guard from #4 is the practical fix
- **`chezmoi state dump` automated assertion** (follow-up #1 strong form) — useful pattern, documented as utility; not a load-bearing assertion in Phase 0 verify gates
- **DRY refactor of brew template's 6 copy-pasted personal/else-work branches** — YAGNI; revisit if a 7th branch surfaces
- **Pre-stubbing Windows/gaming/lite files** — Phase 2/3 own these; pre-stubs would be dead code in Phase 0
- **Lonestar-specific bootstrap path** — status unclear; defer until Lonestar work resumes
- **`home/scripts/generate-gpg-key.sh` deletion + `modify_dot_gitconfig.local` rewrite** → Phase 1 (atomic with VaultWarden landing)
- **VaultWarden, GPG canonical key, SSH per-purpose keys, bootstrap kit** → Phase 1
- **Windows files, pwsh, winget, Stream Deck, `role=gaming`, `role=lite` stubs** → Phase 2
- **WSL-specific `.wslconfig` / `wsl.conf` work** → Phase 3
- **Lonestar onboarding** → Phase 4
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| TAX-01 | User can configure `role` via `chezmoi init` prompt (dev / gaming / lite) using `promptStringOnce` | Verified: `promptChoiceOnce` is the correct function (typo-validates AND persists-once); semantics match `promptStringOnce` for persistence. See "promptChoiceOnce semantics" below. |
| TAX-02 | `personal` flag works orthogonally to `role` | Verified: `personal` already exists as `promptBoolOnce` in `.chezmoi.toml.tmpl:1`; new `role` joins as separate axis in same `[data]` block. No coupling required. |
| TAX-03 | chezmoi auto-detects OS via `.chezmoi.os` | Verified: already in use throughout `brew` template (lines 9, 26, 48, 65, 88, 105). No new work — chezmoi built-in. |
| TAX-04 | chezmoi auto-detects WSL via `.wsl` from `.chezmoi.kernel.osrelease` containing "microsoft" | Verified: already implemented at `.chezmoi.toml.tmpl:4-9`. No new work. |
| TAX-05 | `.chezmoidata/packages.yaml` restructured around `roles.<role>.<os>` + `overlays.personal.<os>` + `overlays.work.<os>` | Locked shape in CONTEXT.md "packages.yaml Restructure". Brew template rewrite + 4 latent Linux-overlay bug fixes inline. Structural commit. |
| TAX-06 | `.chezmoiignore` templated, gates whole-file/subtree by role + personal + os + wsl (single gating decision point) | Verified: `.chezmoiignore` IS template-evaluated on every apply (no cache). Reframed per CONTEXT.md to FILE PRESENCE only — template-internal logic stays in templates. 5 gates locked. |
| TAX-07 | Existing Mac personal + Mac work produce zero functional diff after refactor | Merge gate: `chezmoi diff -x externals` empty on BOTH Macs (per Phase 0.5 conventions § 9). Mac work carries the single justified `.zshrc NODE_EXTRA_CA_CERTS` escalation from Phase 0.5 → resolved IN Phase 0 by `.localrc` migration in cutover script (step 4). |
| TAX-08 | `dot_topics/<tool>/` convention documented in `docs/dot_topics.md` | Already complete in Phase 0.5 Plan 02. Phase 0 inherits — no new work. **Verify by inspection** in plan 03 (docs commit). |
| SEC-05 | `home/scripts/generate-gpg-key.sh` DELETED (not renamed) — avoids `run_once_` re-fire | **DEFERRED to Phase 1** per CONTEXT.md Goal Amendment #1. Script is load-bearing via `modify_dot_gitconfig.local:6`. Phase 0 plans MUST NOT delete it. (Pitfall 11 baseline assumption was wrong — script is in entryState not scriptState; verified in Phase 0.5 state preview.) |
| LNX-05 | NO Linux Homebrew — `.chezmoiscripts/linux/` skeleton uses apt + mise only | Documented in docs commit (plan 03) as locked decision. No Linux skeleton lands in Phase 0 (Phase 3 territory). 4 latent Linux-overlay-bugs-in-brew-template fixed inline anyway because they're in active `brew` partial. |
| SS-03 | Flameshot config preserved in `private_dot_config/flameshot/` gated to `role=dev + os=linux` (dormant until Linux laptop) | Locked .chezmoiignore gate per CONTEXT.md. Phase 0.5 Plan 04 deleted Mac destinations; source not re-added in 0.5. Phase 0 re-stages from `00.5-04-flameshot-baseline.md` capture (verbatim `.ini` content + SHA + mode). |
</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| chezmoi | ≥ 2.70.4 | source-of-truth dotfile manager | Already the project tool; version floor enforced because state-delete CLI behavior diverges on 2.69.4 under zsh (follow-up #7) |
| Bash | 5.x | cutover script interpreter | macOS ships 3.2 by default; `01-install-brew.sh.tmpl` already pulls 5.x via brew; cutover script runs at end of bootstrap when 5.x is available |
| Go text/template + sprig | bundled with chezmoi | template engine for all `.tmpl` files | Built-in; no install. `hasKey`, `fail`, `quote`, `dig` are the relevant primitives for Phase 0. |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `chezmoi execute-template --init` | bundled | dry-run template validation against fixture data | Pitfall 9 defense — run on `.chezmoi.toml.tmpl` and key consumers with `--promptString role=dev`, `--promptBool personal=true` to verify rendering BEFORE cutover |
| `chezmoi state get-bucket` | bundled | inspect entryState before/after cutover script step 6 | Mid-cutover verification that 5 `~/bin/<entry>` keys are gone |
| `chezmoi state dump` | bundled | canonical clean-check utility (follow-up #1) | Documented in plan 03 docs commit as utility; not a load-bearing assertion in verify gates |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `promptChoiceOnce` for role | `promptStringOnce` (ROADMAP language) | `promptStringOnce` accepts any string — typos like `Dev` or `divv` silently pollute config. `promptChoiceOnce` enforces enum at prompt time, fails loud on typo. **`promptChoiceOnce` wins** — typo validation is free. |
| Inline `{{ if eq .role "dev" }}` gates in each script | `.chezmoiignore` file-presence gates | Inline gates leave dead rendered files at destinations (e.g., empty mas script on Linux). `.chezmoiignore` removes the file entirely — cleaner destination tree. **`.chezmoiignore` wins** for whole-file routing. |
| Auto-rollback on cutover-script verify-gate failure | Manual recovery from snapshot | Auto-rollback can mask the real failure cause and leaves destination in an unknown state mid-restore. **Manual recovery wins** — `set -euo pipefail`, exit non-zero, operator restores from documented snapshot path. Per CLAUDE.md "manual work = collaborative mode". |
| Full `~/.config/` snapshot | Targeted 5-path + `~/bin/` snapshot | Full `.config/` is 10s of MB and 100s of files; targeted captures the things cutover script actually mutates. Restore is a 30-second cp operation, not a 5-minute archive expand. **Targeted wins.** |
| One plan with internal commit boundaries | Three plans paralleling three commits | Three plans give the gsd-planner natural task boundaries and let plan-check Dimension 8 score validation gates per-commit. **Three plans wins** per CONTEXT.md lean. |

**Installation (cutover preflight on Mac work):**
```bash
brew upgrade chezmoi  # 2.69.4 → 2.70.4+
chezmoi --version  # verify ≥ 2.70.4 before running cutover script
```

## Architecture Patterns

### Recommended Project Structure (Phase 0 source-tree shape)

```
home/
├── .chezmoi.toml.tmpl              # +role promptChoiceOnce; keep *Once for personal/name/email/wsl
├── .chezmoidata/
│   └── packages.yaml               # RESTRUCTURED: roles.dev.{core,darwin,linux} + overlays.{personal,work}.<os>
├── .chezmoiignore                  # TEMPLATED: 5 conditional-include gates
├── .chezmoitemplates/
│   └── brew                        # REWRITTEN consumer + 4 latent Linux bug fixes
├── .chezmoiscripts/
│   ├── run_onchange_before_02-install-packages.sh.tmpl  # +loud-fail hasKey guard
│   └── run_onchange_before_03-mas.sh.tmpl               # 7→12 lines + /Applications/ guard (mas-guard commit)
├── private_dot_local/
│   └── bin/                        # NEW: 5 utilities migrated from exact_bin/
│       ├── executable_dot.tmpl
│       ├── executable_git-bare-clone
│       ├── executable_git-wtf
│       ├── executable_tmux-cht.sh
│       └── executable_tmux-sessionizer
└── exact_bin/                      # DELETED
```

```
docs/
└── conventions.md                  # § 10 expanded: AUD-02 LIGHT remainder + 5 follow-up notes
```

```
.planning/phases/0-structural-refactor/
├── 0-CONTEXT.md                    # already exists
├── 0-RESEARCH.md                   # this file
├── 0-01-structural-PLAN.md         # Plan 01 (proposed)
├── 0-02-mas-guard-PLAN.md          # Plan 02 (proposed)
├── 0-03-docs-PLAN.md               # Plan 03 (proposed)
└── cutover-phase-0.sh              # NEW operational artifact (committed in plan 01)
```

### Pattern 1: `promptChoiceOnce` for enum config keys with persistence

**What:** Use `promptChoiceOnce . "key" "prompt" $choices [$default]` for any data field with a small, validated enum domain.

**When to use:** Whenever the value is one of N known options, AND should be asked ONCE per machine and never re-prompted on subsequent `chezmoi init --apply` runs.

**Example:**
```go-template
{{- /* Source: chezmoi docs — promptChoiceOnce + init-functions reference */ -}}
{{ $personal := promptBoolOnce . "personal" "Is this a personal install?" true }}
{{ $name := promptStringOnce . "name" "Name" }}
{{ $email := promptStringOnce . "email" "Email Address" }}
{{ $role := promptChoiceOnce . "role" "Machine role" (list "dev" "gaming" "lite") "dev" }}
{{ $wsl := false }}
{{ if eq .chezmoi.os "linux" }}
{{   if (.chezmoi.kernel.osrelease | lower | contains "microsoft") }}
{{-    $wsl = true -}}
{{   end }}
{{ end }}

[data]
  personal = {{ $personal }}
  name = {{ $name | quote }}
  email = {{ $email | quote }}
  role = {{ $role | quote }}
  wsl = {{ $wsl }}
```

**Semantics:**
- First `chezmoi init` on a fresh machine: prompts interactively, validates against `(list "dev" "gaming" "lite")`, persists to `~/.config/chezmoi/chezmoi.toml`.
- Subsequent `chezmoi init --apply`: reads `.role` from existing chezmoi.toml via the `--data` default-true flow, skips prompt.
- The `Once` semantics are: function checks for an existing value at the path before prompting; if string and present, return it; else prompt.

### Pattern 2: Templated `.chezmoiignore` for file-presence routing

**What:** Use `.chezmoiignore` as the single point of decision for "does this file even render at the destination?" Conditionally include patterns based on `.chezmoi.os`, `.personal`, `.role`, `.wsl`.

**When to use:** When an entire file/subtree is meaningless on certain axes (e.g., `darwin-configure.sh.tmpl` on Linux). DO NOT use for runtime branching inside a file — that stays in the template.

**Example:**
```go-template
{{- /* Source: chezmoi reference/special-files/chezmoiignore + verified semantics: template re-evaluated on every apply, no cache */ -}}
{{ if ne .chezmoi.os "darwin" }}
private_dot_config/aerospace/**
.chezmoiscripts/run_onchange_after_darwin-configure.sh.tmpl
.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl
{{ end }}

{{ if or (ne .chezmoi.os "linux") .wsl (ne .role "dev") }}
private_dot_config/flameshot/**
{{ end }}

# Pre-existing
.oh-my-zsh/cache/**
```

**Semantics:**
- Template evaluated on EVERY `chezmoi apply`, `diff`, `status` etc. — no cache.
- Patterns use `doublestar.Match` glob; matched against TARGET path (destination), not source.
- Excludes (`!`) take priority over includes.
- Excluded files: not rendered, not applied. Already-applied destinations are NOT auto-removed when added to ignore — destination cleanup is operator-driven (this is the same Pitfall C dynamic that bit flameshot in Phase 0.5).

### Pattern 3: Loud-fail template guard for required keys

**What:** Surface missing-key bugs at template-render time with an actionable error instead of silently rendering `<no value>`.

**When to use:** At the top of any template that REQUIRES a data key. Mandatory for keys introduced by this refactor (`role`) where pre-cutover machines would otherwise silently render empty.

**Example:**
```go-template
{{- /* Source: sprig fail function + chezmoi sprig inclusion */ -}}
#!/bin/bash
{{ if not (hasKey . "role") }}{{ fail "Role not set. Run: chezmoi init --apply" }}{{ end }}

{{ template "utils" . }}
# ... rest of script
```

**Why:** Go's `text/template` default for missing-key indexing is `"<no value>"` — script renders to `--role=<no value>` and brew bundle errors miles downstream. `hasKey` + `fail` surfaces the bug at the right layer with a fix-instruction.

### Pattern 4: Cutover ritual as versioned artifact

**What:** A `bash` script that lives alongside the phase plan, owns the per-machine state migration that the source-tree change alone can't accomplish.

**When to use:** Whenever a chezmoi refactor mutates entryState ownership (deletions, renames with `exact_` directives) — chezmoi alone won't reconcile this; operator runs the script ONCE per machine post-merge.

**Example structure:**
```bash
#!/usr/bin/env bash
# Source: CONTEXT.md cutover-phase-0.sh 8-step design
set -euo pipefail

SNAP_DIR="$HOME/dotfiles-cutover-snapshot-$(date +%Y%m%d-%H%M%S)"
echo "Snapshot path (BEFORE any mutation): $SNAP_DIR"
mkdir -p "$SNAP_DIR"

# 2. Preflight
chezmoi_ver=$(chezmoi --version | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | tr -d v)
required="2.70.4"
if [ "$(printf '%s\n%s\n' "$required" "$chezmoi_ver" | sort -V | head -n1)" != "$required" ]; then
  echo "FATAL: chezmoi $chezmoi_ver < required $required. Run: brew upgrade chezmoi" >&2
  exit 1
fi

# 3. Snapshot
for f in ~/.config/chezmoi/chezmoi.toml ~/.zshrc ~/.localrc ~/.gitconfig.local; do
  [ -e "$f" ] && cp -a "$f" "$SNAP_DIR/"
done
cp -a ~/bin "$SNAP_DIR/bin"

# 4. Pre-pull migration (Mac work autodetect)
if grep -q NODE_EXTRA_CA_CERTS ~/.zshrc 2>/dev/null; then
  line=$(grep NODE_EXTRA_CA_CERTS ~/.zshrc)
  echo "$line" >> ~/.localrc
  sed -i.bak "/NODE_EXTRA_CA_CERTS/d" ~/.zshrc
  echo "Detected Mac work: migrated NODE_EXTRA_CA_CERTS to ~/.localrc"
fi

# 5. chezmoi init --apply (interactive role prompt)
chezmoi init --apply

# 6. exact_bin teardown
rm -rf ~/bin/
for entry in dot git-bare-clone git-wtf tmux-cht.sh tmux-sessionizer; do
  chezmoi state delete --bucket=entryState --key "/Users/jteague/bin/$entry" || true
done

# 7. Verify SC #4
diff_out=$(chezmoi diff -x externals)
if [ -n "$diff_out" ]; then
  echo "FAIL: chezmoi diff -x externals not empty. Restore from $SNAP_DIR." >&2
  echo "$diff_out" >&2
  exit 2
fi

# 8. Verify SC #3
if chezmoi apply --dry-run --verbose 2>&1 | grep "no value"; then
  echo "FAIL: '<no value>' surfaced in dry-run output. Restore from $SNAP_DIR." >&2
  exit 3
fi

echo "Cutover complete. Snapshot retained at $SNAP_DIR for 30 days."
```

### Anti-Patterns to Avoid

- **Renaming `generate-gpg-key.sh` instead of leaving alone.** It is load-bearing via `modify_dot_gitconfig.local:6`. Goal Amendment #1 defers deletion to Phase 1 (atomic with VaultWarden). Phase 0 plans MUST NOT touch this file.
- **Auto-rollback inside the cutover script.** Per CLAUDE.md, manual work is collaborative mode — operator restores from snapshot. Auto-rollback masks failure cause.
- **Using `--key=/path` in `chezmoi state delete` in shell scripts.** Triggers zsh EQUALS-option parsing pitfall on 2.69.4 (verified Phase 0.5 Plan 06). Always use space-separated `--key /path`.
- **Pre-stubbing Windows/gaming/lite files in source.** Phase 2/3 own those. Dead code in Phase 0.
- **Inline OS gates inside `03-mas.sh.tmpl` AFTER `.chezmoiignore` gates it.** The whole point of the `.chezmoiignore` consolidation is so `03-mas.sh` simplifies from full and-chain to `{{ if .personal }}` — keeping both is double-gating that obscures intent.
- **DRY-refactoring brew template's 6 copy-pasted personal/else-work branches.** YAGNI per CONTEXT.md Q5. The 4 latent Linux-overlay bugs ARE fixed (those are wrong-keyword bugs, not duplication). The 6 branches stay copy-paste until a 7th surfaces.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Persistent role prompt | Custom yq/python script that reads/writes `chezmoi.toml` | `promptChoiceOnce . "role" ...` | Built-in, validates against enum, persists via chezmoi's own data flow, integrates with `--data` flag default-true. |
| Typo validation on enum prompt | Custom case-statement validator in bash | `promptChoiceOnce` (vs `promptStringOnce`) | The `Choice` variant inherits typo-validation from `promptChoice` for free. |
| Cutover script's "is chezmoi new enough" check | Custom `awk`-vs-version-string comparison | `printf '%s\n%s\n' required actual \| sort -V \| head -1` test, OR `chezmoi --version` numeric parse | sort -V is POSIX-portable and handles `v` prefix correctly when stripped first. |
| Dry-run template fixture | Custom go-script that imports `text/template` | `chezmoi execute-template --init --promptString k=v --promptBool k=v --promptChoice k=v < file` | Chezmoi ships the exact-same template engine used by apply; `--init` flag enables init-only functions; `--promptX` flags simulate prompts with fixture values. |
| State surgery for the 5 `~/bin/` entries | Direct boltdb edit | `chezmoi state delete --bucket=entryState --key /path` (space-sep `--key`) | Chezmoi's documented surface; survives chezmoi version upgrades. |
| Snapshot/restore primitive | Custom tar pipeline | `cp -a` of 5 specific paths into a timestamped directory | Targeted scope (5 paths + `~/bin/`) makes tar overkill. `cp -a` preserves perms + mtimes; restore is trivial `cp -a $SNAP_DIR/* ~/`. |

**Key insight:** Every "don't hand-roll" above maps to a chezmoi-bundled primitive that's already been battle-tested by the chezmoi user base. Building custom equivalents introduces version-skew bugs (Mac work 2.69.4 vs Mac personal 2.70.4 already showed this surface area).

## Common Pitfalls

### Pitfall 1: `promptStringOnce` discipline (Phase 0 root pitfall)
**What goes wrong:** Switching to `promptString` (non-`Once` variant) for `role` means every `chezmoi init --apply` re-prompts and ALWAYS overwrites the persisted value with whatever the user typed (or default, if non-interactive). Mac work and Mac personal silently disagree on `role` because the user typed different things one machine vs the other.
**Why it happens:** `Once` family of functions is opt-in. Easy to drop the `Once` suffix by accident.
**How to avoid:** ALL new prompts in `.chezmoi.toml.tmpl` use `Once` variants. Existing prompts are already `Once` (verified at `.chezmoi.toml.tmpl:1-3`). Plan 01 explicit verification step: `grep promptString home/.chezmoi.toml.tmpl | grep -v Once` returns empty.
**Warning signs:** Re-running `chezmoi init --apply` re-prompts for any field that should be persistent.

### Pitfall 2: `chezmoi diff` blind to script side-effects
**What goes wrong:** `chezmoi diff -x externals` shows empty after refactor, BUT the next `chezmoi apply` re-fires `run_onchange_before_02-install-packages.sh` because the brew partial renders new content → 22nd → 23rd hash in scriptState on Mac personal, 27th → 28th on Mac work (Pitfall D from RESEARCH; verified Phase 0.5).
**Why it happens:** `diff` compares destination vs rendered-source for file contents; it doesn't compare scriptState SHAs. A script's rendered content can change (e.g., new package list) without changing any tracked-file destination — diff stays silent.
**How to avoid:** Cutover script pairs `diff -x externals` (step 7) WITH `apply --dry-run --verbose | grep "no value"` (step 8). The dry-run surface DOES include script re-fire signals. Plan 01 verify-step lists `chezmoi status` as additional check.
**Warning signs:** Diff empty, but `chezmoi apply` log mentions `run_onchange` activity beyond the expected packages.yaml re-fire.

### Pitfall 9: Renaming variables → silent `<no value>`
**What goes wrong:** Refactor renames a key in `packages.yaml` (e.g., `packages.core` → `packages.roles.dev.core`); a consumer template (`brew` partial) still references the old path; chezmoi's Go template engine substitutes `<no value>` (default missing-key behavior) for the missing key; brew bundle gets `tap "<no value>"` lines and errors miles downstream.
**Why it happens:** Go's `text/template` default `missingkey=default` makes missing-key lookups silently return the string `<no value>`. Chezmoi doesn't override this.
**How to avoid:**
1. Loud-fail `hasKey` guard at top of `02-install-packages.sh.tmpl` for the new `role` key.
2. Cutover script step 8: `chezmoi apply --dry-run --verbose 2>&1 | grep "no value"` exits non-zero if found.
3. Plan 01 pre-merge: run `chezmoi execute-template --init --promptString name=test --promptString email=t@t --promptBool personal=true --promptChoice role=dev < home/.chezmoi.toml.tmpl` to verify fixture rendering.
**Warning signs:** Brew bundle reports `tap "<no value>"`; install scripts log empty install commands.

### Pitfall 11: `run_once_` state survives refactors (applies to script renames)
**What goes wrong:** Phase 0 renames or reorganizes any `.chezmoiscripts/run_once_*.sh.tmpl` — chezmoi computes a new SHA from the new content, sees no matching scriptState entry, RE-FIRES the script on next apply. For `00-prep-clean-machine.sh.tmpl` (the only `run_once_` here), this would re-run clean-machine prep on a machine that's already prepped.
**Why it happens:** scriptState is keyed by template-render SHA, not by filename. Any content change = new SHA = re-fire.
**How to avoid:** Plan 01 does NOT rename `00-prep-clean-machine.sh.tmpl` content. If structural commits ARE done on a script's content (e.g., 02-install-packages adds hasKey guard), accept that scriptState gets a new entry — that's expected. Cutover script step 5 (`chezmoi init --apply`) will re-fire affected scripts; that's by design.
**Warning signs:** `chezmoi state get-bucket --bucket=scriptState` shows new entries post-cutover that surprise the operator.

### Pitfall C: Source-delete leaves destination
**What goes wrong:** Phase 0 deletes `home/exact_bin/` source — operator expects `~/bin/` to disappear on next apply. Reality: only the `exact_` directive enforcement is removed; the 5 destination files PERSIST in `~/bin/`. Mac work also has `start-aws-mcp.sh` Bluebeam-specific tooling already there (verified Phase 0.5 Plan 06).
**Why it happens:** chezmoi by design does NOT track removal history. Source delete = chezmoi no longer manages the file; destination file is untouched. This applies regardless of chezmoi version (verified on 2.69.4 AND 2.70.4 in Phase 0.5).
**How to avoid:** Cutover script step 6 explicitly: `rm -rf ~/bin/` then 5× `chezmoi state delete --bucket=entryState --key /Users/jteague/bin/<entry>`. The `state delete` is for state hygiene — even after `rm -rf`, entryState retains the 5 stale keys; they don't cause user-visible bugs but they pollute future state dumps.
**Warning signs:** `chezmoi state get-bucket --bucket=entryState | grep /Users/jteague/bin` returns entries after cutover.

### Pitfall Mac-work-version-skew: chezmoi 2.69.4 state-delete CLI parsing
**What goes wrong:** Cutover script's step 6 `chezmoi state delete --bucket=entryState --key=/Users/jteague/bin/dot` form crashes at the zsh layer on chezmoi 2.69.4 (Mac work currently) because zsh EQUALS-option treats `=/path` as a command-path lookup. Same form works on 2.70.4.
**Why it happens:** Combination of chezmoi version + zsh parser interaction. Verified Phase 0.5 Plan 06 Task 5.
**How to avoid:**
1. Preflight check (cutover step 2) refuses to run on chezmoi < 2.70.4.
2. Use space-separated `--key /path` (NOT `--key=/path`) in ALL state-delete invocations.
**Warning signs:** zsh-level "no such file or directory: --key=/..." errors during cutover.

### Pitfall mas-list-Apple-ID-invisibility (follow-up #3, resolved by mas guard)
**What goes wrong:** `03-mas.sh` invokes `mas install 1193539993` (Brother iPrint) every time content changes; the app IS installed but under a different Apple ID, so `mas list` doesn't see it; `mas install` triggers Spotlight re-index → `sudo` prompt → fails non-TTY.
**Why it happens:** `mas` only introspects apps under the currently-signed-in Apple ID. Sideloaded or different-Apple-ID apps are invisible to `mas list` but visible to `/Applications/`.
**How to avoid:** Plan 02 (mas guard commit) adds a `[[ ! -d "/Applications/${app_name}.app" ]]` guard before `mas install`. App-name resolution via `dig "name"` from the packages.yaml mas dict.
**Warning signs:** Apply log warnings like "Found a likely App Store app that is not indexed in Spotlight".

## Code Examples

Verified patterns from official sources:

### `.chezmoi.toml.tmpl` with all prompt variants
```go-template
{{- /* Source: chezmoi reference/templates/init-functions/ + local .chezmoi.toml.tmpl read 2026-06-01 */ -}}
{{ $personal := promptBoolOnce . "personal" "Is this a personal install?" true }}
{{ $name := promptStringOnce . "name" "Name" }}
{{ $email := promptStringOnce . "email" "Email Address" }}
{{ $role := promptChoiceOnce . "role" "Machine role" (list "dev" "gaming" "lite") "dev" }}
{{ $wsl := false }}
{{ if eq .chezmoi.os "linux" }}
{{   if (.chezmoi.kernel.osrelease | lower | contains "microsoft") }}
{{-    $wsl = true -}}
{{   end }}
{{ end }}

[data]
  personal = {{ $personal }}
  name = {{ $name | quote }}
  email = {{ $email | quote }}
  role = {{ $role | quote }}
  wsl = {{ $wsl }}
```

### Brew template — new shape consumer (excerpt, illustrating role × os × overlay shape)
```go-template
{{- /* Source: locked structure from CONTEXT.md packages.yaml restructure + verified existing brew partial */ -}}
brew bundle --file=/dev/stdin << EOF

# Role-level taps (cross-OS)
{{ range .packages.roles.dev.core.taps -}}
tap {{ . | quote }}
{{ end -}}

# Role × OS taps
{{ if eq .chezmoi.os "darwin" -}}
  {{ if hasKey .packages.roles.dev "darwin" -}}
    {{ range .packages.roles.dev.darwin.taps -}}
tap {{ . | quote }}
    {{ end -}}
  {{ end -}}
{{ end -}}

# Overlay × OS taps
{{ if eq .chezmoi.os "darwin" -}}
  {{ if .personal -}}
    {{ if hasKey .packages.overlays "personal" -}}
      {{ range .packages.overlays.personal.darwin.taps -}}
tap {{ . | quote }}
      {{ end -}}
    {{ end -}}
  {{ else -}}
    {{ if hasKey .packages.overlays "work" -}}
      {{ range .packages.overlays.work.darwin.taps -}}
tap {{ . | quote }}
      {{ end -}}
    {{ end -}}
  {{ end -}}
{{ end -}}

# ... repeat copy-paste pattern for brews + casks
# (DRY refactor of 6 branches is YAGNI per CONTEXT.md Q5)
#EOF
EOF
```

### Loud-fail guard in `02-install-packages.sh.tmpl`
```go-template
{{- /* Source: sprig fail + hasKey + chezmoi templating reference */ -}}
#!/bin/bash
{{ if not (hasKey . "role") }}{{ fail "Role not set. Run: chezmoi init --apply" }}{{ end }}

{{ template "utils" . }}

{{ if eq .chezmoi.os "darwin" -}}
eval "$(/opt/homebrew/bin/brew shellenv)"
{{ else if eq .chezmoi.os "linux" -}}
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
{{ end -}}

# ... existing logic
{{ template "brew" . }}
```

### Mas guard (plan 02 commit)
```go-template
{{- /* Source: follow-up #3 + #4 resolution. CONTEXT.md mas guard commit */ -}}
#!/bin/bash
{{ if .personal -}}
  {{ range $k, $v := .packages.overlays.personal.darwin.mas }}
    app_name={{ dig "name" "" $v | quote }}
    if [ ! -d "/Applications/${app_name}.app" ]; then
      /opt/homebrew/bin/mas install {{ dig "id" "" $v }}
    else
      echo "Skipping mas install: ${app_name}.app already present"
    fi
  {{ end -}}
{{ end -}}
```
(Outer `darwin + not-wsl` gate moved to `.chezmoiignore` per consolidation — see Pattern 2.)

### Templated `.chezmoiignore` (new content, replaces 1-line stub)
```go-template
# .oh-my-zsh cache (pre-existing)
.oh-my-zsh/cache/**

# Darwin-only files
{{ if ne .chezmoi.os "darwin" }}
private_dot_config/aerospace/**
.chezmoiscripts/run_onchange_after_darwin-configure.sh.tmpl
.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl
{{ end }}

# Linux-dev-non-wsl-only files (flameshot)
{{ if or (ne .chezmoi.os "linux") .wsl (ne .role "dev") }}
private_dot_config/flameshot/**
{{ end }}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual `mas install` without app-presence guard | `[[ -d /Applications/<App>.app ]]` pre-check | Phase 0 plan 02 | Eliminates Pitfall mas-list-Apple-ID-invisibility surfaced Phase 0.5 |
| `home/exact_bin/` strict directive for personal utilities | `home/private_dot_local/bin/` (non-exact) | Phase 0 structural commit | Decouples employer-local tooling from chezmoi exact-pruning; resolves follow-up #9 |
| `--key=/path` syntax (works on 2.70.4, breaks on 2.69.4 under zsh) | Space-separated `--key /path` | Phase 0 cutover script + docs commit | Version-portable; documented in plan 03 |
| Single top-level `personal` flag | `role × personal` orthogonal axes | Phase 0 (this phase) | Enables role=gaming, role=lite phases without nesting work into personal |
| `core` / `darwin` / `linux` flat with personal/work mixed in | `roles.dev.{core,darwin,linux}` + `overlays.<axis>.<os>` | Phase 0 (this phase) | Clear ownership; Lonestar lands `role=dev` cleanly |

**Deprecated/outdated:**
- The Phase 0 ROADMAP-language SC #5 ("generate-gpg-key.sh DELETED") is deprecated; superseded by CONTEXT.md Goal Amendment #1 (deferred to Phase 1).
- The Phase 0 ROADMAP-language SC #2 (".chezmoiignore as single gating decision point") is reframed to FILE PRESENCE only; template-internal logic stays in templates.

## Open Questions

1. **Does `chezmoi state delete` on chezmoi 2.70.4 successfully remove the 5 `~/bin/<entry>` entryState keys?**
   - What we know: command syntax works (verified via `chezmoi state delete --help` locally on 2.70.4). Exit code is 0 if key absent (verified Phase 0.5 Plan 04 with `|| true`).
   - What's unclear: whether the 5 entries actually exist in Mac personal's entryState today (they were tracked Phase 0.5 capture, but Mac personal hasn't yet been cutover). Probably yes.
   - Recommendation: Plan 01 cutover script uses `|| true` (CONTEXT.md step 6 already specifies this). Verify post-cutover via `chezmoi state get-bucket --bucket=entryState | grep /Users/jteague/bin` → empty.

2. **What is the exact list of files Mac work currently has in `~/bin/` outside chezmoi source?**
   - What we know: `start-aws-mcp.sh` was migrated to `~/.local/bin/` in Phase 0.5 Plan 06.
   - What's unclear: whether other ad-hoc files have accumulated in `~/bin/` since Phase 0.5 close (2026-05-29 → 2026-06-01, 3 days). Low probability of new files.
   - Recommendation: Cutover script step 3 (snapshot) captures `cp -a ~/bin "$SNAP_DIR/bin"` — any unmigrated files survive in snapshot and can be hand-restored post-cutover.

3. **Does `chezmoi init --apply` on a machine that ALREADY has chezmoi.toml re-render the config or merge?**
   - What we know (verified via chezmoi/issues/570 thread + promptOnce semantics): with `--data` default-true (the default), existing chezmoi.toml data IS available in `.` when re-rendering. `promptOnce` family checks for existing key in `.` BEFORE prompting. So: existing personal/name/email skip; new `role` prompts.
   - What's unclear: whether `chezmoi init --apply` writes the chezmoi.toml even when no new prompts fire (i.e., is there an idempotent-write side effect?). Probably yes (re-renders template to disk), but the rendered content should be identical modulo new `role` key.
   - Recommendation: Cutover script step 3 snapshots chezmoi.toml BEFORE step 5. If step 5 produces an unexpected toml mutation, snapshot enables instant restore.

4. **Does Mac work have any `~/.localrc` content TODAY?**
   - What we know: Phase 0.5 Plan 06 escalation noted Mac work `~/.zshrc` has `NODE_EXTRA_CA_CERTS` line. Plan 06 did NOT migrate to `.localrc` — escalation deferred to Phase 0.
   - What's unclear: whether Teague hand-migrated between 2026-05-29 and 2026-06-01.
   - Recommendation: Cutover script step 4 uses `grep -q` to autodetect; if `NODE_EXTRA_CA_CERTS` is gone from `.zshrc`, step 4 is a no-op. Safe either way.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Phase-0.5-era Wave 0 harness pattern: `lib.sh` + `quick.sh` + `full.sh` shell scripts (no Python/Ruby/Node test framework). chezmoi has no formal "test suite" — validation is shell-driven against chezmoi CLI primitives. |
| Config file | New: `.planning/phases/0-structural-refactor/checks/` directory (mirrors `00.5-audit-documentation/checks/`) |
| Quick run command | `bash .planning/phases/0-structural-refactor/checks/quick.sh` |
| Full suite command | `bash .planning/phases/0-structural-refactor/checks/full.sh` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TAX-01 | `role` prompt fires once via `promptChoiceOnce`; persists; subsequent applies don't re-prompt | unit (template-render) | `chezmoi execute-template --init --promptString name=t --promptString email=t@t --promptBool personal=true --promptChoice role=dev < home/.chezmoi.toml.tmpl \| grep -E '^  role = "dev"$'` | ❌ Wave 0 — create `checks/quick.sh` step |
| TAX-02 | `personal` flag orthogonal to `role` (work × dev possible) | unit (template-render) | `chezmoi execute-template --init --promptBool personal=false --promptChoice role=dev < home/.chezmoi.toml.tmpl \| grep -E '^  (personal = false\|role = "dev")$' \| wc -l` returns 2 | ❌ Wave 0 |
| TAX-03 | `.chezmoi.os` consumed in `brew` template | smoke (grep on rendered output) | `grep -E '^(tap\|brew\|cask) ' <(chezmoi execute-template < home/.chezmoitemplates/brew)` returns lines | ❌ Wave 0 |
| TAX-04 | `.wsl` flag computed from osrelease | unit (template-render) | `chezmoi execute-template --init --promptString name=t --promptString email=t@t --promptBool personal=true --promptChoice role=dev < home/.chezmoi.toml.tmpl \| grep -E '^  wsl = (true\|false)$'` | ❌ Wave 0 |
| TAX-05 | packages.yaml has new shape (`roles.dev.core` + `overlays.{personal,work}.<os>`) | unit (yaml structure) | `ruby -r yaml -e 'h = YAML.load_file("home/.chezmoidata/packages.yaml"); raise unless h.dig("packages","roles","dev","core") && h.dig("packages","overlays","personal","darwin") && h.dig("packages","overlays","work","darwin")'` | ❌ Wave 0 |
| TAX-06 | `.chezmoiignore` is templated with `.chezmoi.os` and `.role` references | unit (file content) | `grep -l '{{' home/.chezmoiignore && grep -E '(\.chezmoi\.os\|\.role\|\.personal\|\.wsl)' home/.chezmoiignore` | ❌ Wave 0 |
| TAX-07 | `chezmoi diff -x externals` empty on both Macs after cutover | integration (merge gate) | `chezmoi diff -x externals \| wc -c` returns 0 | ❌ Wave 0 — automated per-machine, but RUN is operator-driven |
| TAX-08 | `docs/dot_topics.md` exists (inherited from 0.5) | smoke (file existence) | `test -f docs/dot_topics.md && grep -q "dot_topics/<tool>" docs/dot_topics.md` | ✅ Phase 0.5 created |
| SEC-05 | DEFERRED to Phase 1 — `generate-gpg-key.sh` still present | smoke (file existence) | `test -f home/scripts/generate-gpg-key.sh` (REQUIRED true in Phase 0) | ✅ Existing baseline |
| LNX-05 | NO Linux Homebrew — documented in conventions | smoke (file content) | `grep -q "NO Linux Homebrew\|apt + mise" docs/conventions.md` | ❌ Wave 0 — docs commit (plan 03) creates content |
| SS-03 | flameshot source preserved AND `.chezmoiignore` gates it to linux+dev+not-wsl | unit (file + gate) | `test -d home/private_dot_config/flameshot && grep -A2 "flameshot" home/.chezmoiignore \| grep -E '(linux\|role.*dev\|wsl)'` | ❌ Wave 0 — Phase 0 re-stages from baseline + adds gate |
| Loud-fail guard | `02-install-packages.sh.tmpl` has `hasKey "role"` + `fail` guard | unit (file content) | `grep -E 'hasKey.*"role".*fail.*Role not set' home/.chezmoiscripts/run_onchange_before_02-install-packages.sh.tmpl` | ❌ Wave 0 |
| No `<no value>` | `chezmoi apply --dry-run --verbose` doesn't surface `<no value>` for any rendered file | integration | `chezmoi apply --dry-run --verbose 2>&1 \| grep "no value" \| wc -l` returns 0 | ❌ Wave 0 — RUN is per-machine post-cutover |
| Cutover script idempotency | Re-running cutover script after success is a no-op | integration | Second run: snapshot dir created with new timestamp, step 4 grep returns empty (already migrated), step 5 init re-prompts nothing, steps 7+8 still empty | ❌ Manual-only — RUN by operator on one Mac as smoke test |

**Manual-only behaviors with justification:**
- **Per-machine cutover run.** Mac personal and Mac work cutovers are physically separate operations the human runs. Plans 01-03 don't run the script — they land the source artifact and verify it's executable. Per CLAUDE.md: "manual work = collaborative mode."
- **Cross-machine merge gate.** SC #4 (`chezmoi diff -x externals` empty on BOTH Macs) requires two physical machines. Verifier runs each machine separately; merge-gate report aggregates both captures (mirroring Phase 0.5 Plan 06 pattern).
- **Role-prompt interactive answer.** `chezmoi init --apply` (step 5) prompts for `role` interactively (intentional acknowledgment). Cutover script captures the answer; verification happens via post-step check of `~/.config/chezmoi/chezmoi.toml`.

### Sampling Rate
- **Per task commit:** `bash .planning/phases/0-structural-refactor/checks/quick.sh` — runs file-existence + YAML structure + template-render-fixture checks (under 30 seconds; no Mac-specific state required).
- **Per wave merge:** `bash .planning/phases/0-structural-refactor/checks/full.sh --no-diff-gate` — adds `chezmoi execute-template` fixture dry-run for both `personal=true,role=dev` and `personal=false,role=dev` scenarios. Diff-gate is operator-driven (per-machine).
- **Phase gate (merge gate):** Both Macs run cutover script → `chezmoi diff -x externals` empty (Mac personal must be EMPTY; Mac work must be EMPTY since `.localrc` migration resolves the Phase-0.5 escalation). Full suite green BEFORE `/gsd:verify-work`.

### Wave 0 Gaps
- [ ] `.planning/phases/0-structural-refactor/checks/lib.sh` — assert helpers (copy/adapt from `00.5-audit-documentation/checks/lib.sh`)
- [ ] `.planning/phases/0-structural-refactor/checks/quick.sh` — covers TAX-01..06, TAX-08, SS-03, loud-fail-guard, no-`<no value>` (template-render scope only; no machine-state assertions)
- [ ] `.planning/phases/0-structural-refactor/checks/full.sh` — adds dry-run-fixture scenarios; `--no-diff-gate` flag for harness use; `--no-quick` flag for full-only invocation
- [ ] `.planning/phases/0-structural-refactor/checks/fixtures/` (optional) — fixture data files if `--promptString k=v` CLI flags exceed sane inline length (probably not needed; 4 prompts max)
- [ ] No new framework install required — Bash + chezmoi CLI suffice. (Ruby YAML stdlib confirmed available on Mac personal per Phase 0.5 Plan 01.)

## Sources

### Primary (HIGH confidence)
- chezmoi reference docs: [promptChoiceOnce](https://www.chezmoi.io/reference/templates/init-functions/promptChoiceOnce/), [promptChoice](https://www.chezmoi.io/reference/templates/init-functions/promptChoice/), [promptBoolOnce](https://www.chezmoi.io/reference/templates/init-functions/promptBoolOnce/), [init](https://www.chezmoi.io/reference/commands/init/), [execute-template](https://www.chezmoi.io/reference/commands/execute-template/), [.chezmoiignore](https://www.chezmoi.io/reference/special-files/chezmoiignore/), [source-state-attributes](https://www.chezmoi.io/reference/source-state-attributes/) — all read 2026-06-01
- Local `chezmoi --version` (2.70.4, commit 64583685, built 2026-05-19) + `chezmoi state delete --help` + `chezmoi apply --help` — direct binary introspection
- Source tree inspection (2026-06-01): `home/.chezmoi.toml.tmpl`, `home/.chezmoiignore`, `home/.chezmoidata/packages.yaml`, `home/.chezmoitemplates/brew`, `home/.chezmoiscripts/run_onchange_before_{02,03}-*.sh.tmpl`, `home/modify_dot_gitconfig.local`, `home/exact_bin/`
- Phase 0.5 artifacts: `00.5-exit-gate-report.md`, `00.5-state-preview.md`, `00.5-drift-reconciliation.md`, `docs/conventions.md`
- chezmoi GitHub issue #570 (via `gh issue view`) — confirms `promptOnce` family as the resolution to re-init merge behavior

### Secondary (MEDIUM confidence)
- sprig docs: [dicts.html#hasKey](https://masterminds.github.io/sprig/dicts.html), [flow_control.html#fail](https://masterminds.github.io/sprig/flow_control.html) — chezmoi includes all sprig functions
- chezmoi discussions #1446 (source-delete behavior — confirms Pitfall C across versions)
- Go `text/template` reference — missingkey=default produces `<no value>` (default behavior chezmoi does not override)

### Tertiary (LOW confidence)
- Speculation that `chezmoi init --apply` rewrites chezmoi.toml even when no new prompts fire — Open Question #3, low impact (snapshot covers).
- Mac work hand-migration status between 2026-05-29 close and 2026-06-01 research — Open Question #4, autodetect in cutover script handles both branches.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every primitive is chezmoi-bundled or Bash stdlib; versions verified.
- Architecture: HIGH — CONTEXT.md decisions cross-verified against chezmoi docs; brew partial structure + .chezmoiignore semantics confirmed from primary sources.
- Pitfalls: HIGH — Pitfalls 1, 2, 9, 11, C all have Phase 0.5 empirical verification; Pitfall mas-list documented in Phase 0.5 drift-reconciliation; Pitfall version-skew documented in Phase 0.5 Plan 06 Task 5.
- Validation architecture: HIGH — pattern inherited from Phase 0.5 Wave 0 harness; chezmoi `execute-template` confirmed sufficient for unit-level checks; `diff -x externals` confirmed sufficient for merge gate (per Phase 0.5 close).

**Research date:** 2026-06-01
**Valid until:** 2026-07-01 (chezmoi releases monthly; if 2.71+ ships and changes state-delete syntax, refresh)
