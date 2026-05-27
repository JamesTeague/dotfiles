# chezmoi Repo Conventions

> Inherited structural decisions in this chezmoi repo, derived from live-tree inspection.
> Last verified against tree state: **2026-05-27**.
> See also: [`dot_topics.md`](./dot_topics.md) for the per-tool loader convention.

This document captures **how this repo is shaped today**, not how it should ideally be shaped. Several items are flagged as "Phase 0 will change this" — those are intentional forward-references to the upcoming structural refactor. Read alongside `.planning/phases/00.5-audit-documentation/` for the broader audit context.

---

## 1. `.chezmoiroot`

**File:** `/Users/jteague/.local/share/chezmoi/.chezmoiroot`
**Content:** `./home/`

This single 8-byte file is load-bearing. It tells chezmoi that the **source root** is `home/` (relative to the file's location, i.e. the git repo root). Everything outside `home/` is **invisible to chezmoi** — no apply, no diff, no state.

**What sits OUTSIDE `home/` in this repo:**

- `keyboard/` — Keychron keymaps (intentionally non-managed; carried in the same git repo for convenience)
- `README.md` — repo-level readme
- `docs/` — this directory (Phase 0.5 doc artifacts)
- `.planning/` — GSD planning workspace
- `.gitignore`, `.stylua.toml`, `.DS_Store` — repo-level metadata / formatter config / macOS junk
- `.chezmoiroot` itself

**Why this matters:** if you put a file at the repo root expecting chezmoi to apply it, **chezmoi will not see it.** This is the protection that lets `docs/` and `.planning/` coexist with the source tree.

---

## 2. `.chezmoiscripts/` — current FLAT layout

**Path:** `home/.chezmoiscripts/`
**Layout:** FLAT (no OS subdirectories). Phase 0 will introduce `common/`, `darwin/`, `linux/`, `windows/` subdirs as part of the OS-routing refactor.

**Naming convention:** `run_[once|onchange]_[before|after]_NN-name.sh.tmpl`

| Token | Meaning |
|-------|---------|
| `run_once_` | runs once per machine; recorded in `chezmoistate.boltdb` scriptState |
| `run_onchange_` | runs whenever the rendered content hash changes |
| `before` / `after` | runs before / after `chezmoi apply` of the source tree |
| `NN-` | two-digit numeric prefix orders scripts within the same lifecycle bucket |
| `.sh.tmpl` | shell script with chezmoi templating |

**Six scripts present:**

| Filename | Bucket | Purpose |
|----------|--------|---------|
| `run_once_before_00-prep-clean-machine.sh.tmpl` | once / before | clean-machine prep |
| `run_once_before_01-install-brew.sh.tmpl` | once / before | bootstrap Homebrew |
| `run_onchange_before_02-install-packages.sh.tmpl` | onchange / before | renders `brew bundle` from `home/.chezmoidata/packages.yaml` via the `brew` partial |
| `run_onchange_before_03-mas.sh.tmpl` | onchange / before | Mac App Store installs |
| `run_onchange_after_03-install-topics.sh.tmpl` | onchange / after | finds & runs every `install.sh` under `~/.topics/` (see `dot_topics.md`) |
| `run_onchange_after_darwin-configure.sh.tmpl` | onchange / after | darwin defaults / config |

**Note:** `run_onchange_after_darwin-configure.sh.tmpl` lacks a numeric prefix; it routes by OS via the filename. This is a transitional pattern — Phase 0 will replace OS-in-filename with the OS-nested subdir layout above.

---

## 3. `.chezmoidata/` — declarative data, NO templating

**Path:** `home/.chezmoidata/`
**Files:**

- `packages.yaml` — Homebrew + MAS package lists (current asymmetric `personal/work` nesting; Phase 0.5 normalizes within current shape, Phase 0 restructures to a role × OS axis)
- `tmux-languages.yaml`
- `tmux-tools.yaml`

**Hard constraint:** files in `.chezmoidata/` are loaded into the chezmoi data tree **before** the template engine starts. **No `{{ ... }}` interpolation works inside these files.** They are plain YAML/TOML/JSON, evaluated literally. If you need templating, render to a different file and read it from there.

---

## 4. `.chezmoitemplates/` — partials

**Path:** `home/.chezmoitemplates/`
**Invocation:** `{{ template "name" . }}` from any `.tmpl` file.

**Three partials present, all currently consumed:**

| Name | Purpose |
|------|---------|
| `brew` | renders `brew bundle` output from `packages.yaml` (loops taps/brews/casks across darwin & linux for each axis) |
| `utils` | bash logging helpers used by the install scripts |
| `work-go-debug` | go DAP-config snippet (work-machine only) |

Partials are unprefixed — no `.tmpl` extension; the partial name is its filename. The trailing `.` in the invocation passes the full data context.

---

## 5. `.chezmoiexternal.toml` — externals refresh policy

**Path:** `home/.chezmoiexternal.toml`

**Two externals declared:**

| Destination | Source | Refresh |
|-------------|--------|---------|
| `~/.oh-my-zsh/` | `github.com/ohmyzsh/ohmyzsh` (archive zip, `stripComponents=1`, `exact=true`) | `refreshPeriod = "168h"` (weekly) |
| `~/.tmux/plugins/tpm/` | `github.com/tmux-plugins/tpm` (archive zip, `stripComponents=1`, `exact=true`) | `refreshPeriod = "168h"` (weekly) |

**Both externals use `exact = true`** — chezmoi will prune local files not present in the upstream archive on each refresh.

**Forced refresh:** `chezmoi apply --refresh-externals` (re-downloads regardless of `refreshPeriod`).

**Operational consequence:** `chezmoi diff` (without `-x externals`) will frequently surface 30+ files of pending external churn that is NOT source drift. See section 9 below for the canonical "is my repo clean?" command.

---

## 6. `dot_topics/<tool>/` convention

`home/dot_topics/` is a load-bearing loader convention that is NOT documented in chezmoi itself — it is repo-local. See [`dot_topics.md`](./dot_topics.md) for the full description (file-type rules, load order, install.sh handling, adding a new tool).

**Short version:** `dot_topics/` lands at `~/.topics/` on apply. `home/dot_zshrc.tmpl` sources every `~/.topics/*/*.zsh` in three passes (path → completion → middle). Install scripts (`install.sh`) are NOT auto-sourced; they are discovered + executed by `run_onchange_after_03-install-topics.sh.tmpl`.

---

## 7. Attribute prefixes used in THIS repo

chezmoi uses **filename prefixes** as attributes that control destination naming, mode, and behavior. Every one used in this repo is enumerated below with a literal example.

| Prefix | Example (this repo) | Effect at destination |
|--------|----------------------|------------------------|
| `dot_` | `home/dot_gitconfig.tmpl` → `~/.gitconfig` | rewrites the destination filename `dot_X` → `.X` (handles dotfile naming without the source tree being itself dotfile-cluttered) |
| `private_` | `home/private_dot_config/` → `~/.config/` (mode `0700`) | sets the destination's permissions to `0700` (owner-only) |
| `executable_` | `home/exact_bin/executable_tmux-sessionizer` → `~/bin/tmux-sessionizer` (mode `+x`) | sets the executable bit on the destination |
| `exact_` | `home/exact_bin/` → `~/bin/` with pruning | chezmoi removes any destination entries NOT declared in the source tree (this is how `~/bin/` stays clean of stale scripts) |
| `modify_` | `home/modify_dot_gitconfig.local` → mutates `~/.gitconfig.local` in place | the file is executed as a script that reads the existing destination on stdin and writes the new content on stdout (so existing content is preserved, e.g. per-machine `[user]` blocks) |

**Combined prefixes** stack: `private_dot_config/` is both `private_` (0700 mode) AND `dot_` (rename to `.config/`).

**Not an attribute prefix:** `.tmpl` is the **template extension** — appended to indicate the file should be processed by the template engine. It can combine with any attribute prefix (e.g. `dot_gitconfig.tmpl`, `executable_path.zsh.tmpl`).

---

## 8. Line endings

**Source storage:** LF everywhere in the git index, enforced by the repo-root `.gitattributes` (`* text=auto` + `*.tmpl text eol=lf` + `*.sh text eol=lf` + `*.ps1 text eol=lf` — landed in Phase 0.5 Plan 03).

**Render-time control:** chezmoi has a separate `chezmoi:template:line-ending=native` directive that can be embedded in template files to control the **rendered output's** line endings independently of source storage. This is Phase 2 (Windows-native) territory — when `.ps1.tmpl` files need to render with CRLF for legacy PowerShell tooling even though the source is LF.

**Pitfall context:** see [`PITFALLS.md` Pitfall 4](../.planning/research/PITFALLS.md) for the broader line-ending drift discussion. The TL;DR: source = LF (via `.gitattributes`), destination = whatever the template directive says (defaults to OS-native).

---

## 9. Canonical "is my repo clean?" command

```bash
chezmoi diff -x externals
```

**Exit 0 with empty stdout = your repo and machine are in sync** modulo external refresh churn.

**Why `-x externals`:** `chezmoi diff` without the flag will surface every pending external refresh as a diff entry (see section 5 — externals refresh weekly). That churn is by design, not source drift. Filter it out unless you specifically want to see external updates.

This command is the load-bearing **exit gate** for Phase 0.5 and the **merge gate** for Phase 0's refactor. Use it as your "did my edit do what I think it did?" check.

---

## 10. Known inconsistencies (flagged for Phase 0 normalization)

These are real-tree inconsistencies surfaced during the Phase 0.5 audit. They are documented here so a reader is not confused; they are deliberately NOT normalized in this phase because doing so would change destination file modes and produce a non-empty `chezmoi diff` (breaking the phase exit gate).

1. **`home/dot_topics/rust/path.zsh`** lacks the `executable_` prefix that every other `path.zsh` in this tree carries. Phase 0 normalization will rename to `executable_path.zsh`.
2. **`home/dot_topics/system/path.zsh.tmpl`** lacks the `executable_` prefix. Phase 0 normalization will rename to `executable_path.zsh.tmpl`.
3. **`run_onchange_after_darwin-configure.sh.tmpl`** lacks a numeric `NN-` prefix and routes by OS via its filename rather than via the (not-yet-existing) OS subdirectory structure. Phase 0 will move OS routing into subdirectory layout.
4. **`packages.yaml` `personal.{taps,brews,casks}` at top level AND nested `personal.darwin.{...}` block** — the top-level entries are dead code at the template level (the `brew` partial only ranges over `personal.darwin.*` and `personal.linux.*`). Phase 0.5 Plan 05 normalizes these moves; Phase 0 restructures the whole role × OS axis.
5. **`packages.yaml` `work.core.{taps,brews,casks}`** — also dead code at the template level (template ranges over `work.darwin.*` and `work.linux.*`, not `work.core`). Phase 0.5 Plan 05 handles the move.
6. **`.DS_Store` at repo root** is a macOS Finder artifact and probably should be in `.gitignore` if it isn't already; not in scope for Phase 0.5.

---

*Document populated from live-tree inspection per Phase 0.5 CONTEXT.md decision: "inspect the actual tree to derive content — do not invent conventions."*
