# `dot_topics/` — Per-Tool Loader Convention

> Load-bearing convention that is **not** documented in chezmoi itself — it is repo-local.
> Last verified against tree state: **2026-05-27**.
> See also: [`conventions.md`](./conventions.md) for the broader structural decisions in this repo.

`home/dot_topics/` is a per-tool dotfile-loader convention wired through `home/dot_zshrc.tmpl`. Each tool gets a directory under `dot_topics/<tool>/` with conventionally-named files. On apply, `dot_topics/` lands at `~/.topics/` (chezmoi strips `dot_` prefix), and `~/.zshrc` sources `~/.topics/*/*.zsh` in three carefully-ordered passes.

---

## 1. What it is — the loader pattern

**Wiring lives in `home/dot_zshrc.tmpl` lines 32-77.** Verbatim relevant excerpt:

```zsh
# all of our zsh files
typeset -U config_files
config_files=({{.chezmoi.homeDir}}/.topics/*/*.zsh)

# load the path files
for file in ${(M)config_files:#*/path.zsh}
do
  source $file
done


autoload -U compinit add-zsh-hook
compinit -u add-zsh-hook chpwd
compaudit | xargs chmod g-w,o-w

# load every completion after autocomplete loads
for file in ${(M)config_files:#*/completion.zsh}
do
  source $file
done

# ...fzf helper block omitted...

# load everything but the path and completion files
for file in ${${config_files:#*/path.zsh}:#*/completion.zsh}
do
  source $file
done

unset config_files
```

**Three load passes (in order):**

| Pass | Glob filter | When |
|------|-------------|------|
| **1. path** | `${(M)config_files:#*/path.zsh}` | FIRST, before anything else |
| **(compinit)** | — | between pass 1 and pass 2 |
| **2. completion** | `${(M)config_files:#*/completion.zsh}` | AFTER `compinit` runs |
| **3. middle (everything else)** | `${${config_files:#*/path.zsh}:#*/completion.zsh}` | LAST |

**Why load order matters:**

- `path.zsh` must run **first** so that any subsequent tool's `eval $(tool init)` or `tool completions zsh` finds the binary on `$PATH`.
- `completion.zsh` must run **after `compinit`** because completion functions register against the live completion engine; sourcing them before `compinit` would have no effect.
- Middle pass runs **last** so it sees both the populated `$PATH` and the live completion engine — safe place for aliases, evals, and per-tool config.

**Destination-side note:** chezmoi strips the `dot_` prefix on apply, so the source tree's `dot_topics/` lands at `~/.topics/` (lowercase, no underscore). The loader glob (`~/.topics/*/*.zsh`) matches the destination, not the source.

---

## 2. File-type conventions present in this tree

| Filename | Load pass | Convention |
|----------|-----------|------------|
| `path.zsh` | **1 (path)** | sets `$PATH` or `$PATH`-adjacent env. Sourced FIRST. |
| `completion.zsh` | **2 (completion)** | registers completion functions. Sourced AFTER `compinit`. |
| `eval.zsh` | **3 (middle)** | `eval "$(tool init zsh)"` or similar shell-hook installer. Examples: `atuin/executable_eval.zsh`, `starship/executable_eval.zsh`. |
| `aliases.zsh` | **3 (middle)** | shell aliases. Convention name; no special loader treatment beyond `.zsh` extension. (Used by `zsh/executable_aliases.zsh`.) |
| `config.zsh` | **3 (middle)** | per-tool zsh config (options, keybinds). Convention name; no special loader treatment beyond `.zsh` extension. (Used by `zsh/executable_config.zsh`.) |
| `install.sh` | **(not auto-sourced)** | extension is `.sh`, not `.zsh` — the loader's glob does NOT pick it up. Discovered + executed by `home/.chezmoiscripts/run_onchange_after_03-install-topics.sh.tmpl`. |

**Verbatim install-topics script body:**

```bash
#!/bin/bash

# find all installers and run them iteratively
find {{.chezmoi.homeDir}}/.topics -name install.sh | while read installer ; do /bin/bash -c "${installer}" ; done
```

So `install.sh` files run as a separate post-apply phase, not during shell startup. This is important: they can do **expensive** work (downloads, installers, registry edits) without blocking every new shell.

---

## 3. Attribute prefixes observed in this tree

Most files use chezmoi's `executable_` attribute prefix (which sets the executable bit at the destination). Two exceptions:

| Path | Issue |
|------|-------|
| `home/dot_topics/rust/path.zsh` | LACKS `executable_` prefix (every other `path.zsh` has it) |
| `home/dot_topics/system/path.zsh.tmpl` | LACKS `executable_` prefix |

**Known inconsistency — do NOT normalize in Phase 0.5.** Renaming to `executable_path.zsh` would set the executable bit at the destination, producing a non-empty `chezmoi diff` and breaking the phase exit gate. Phase 0 owns the normalization pass.

(See [`conventions.md` § 10](./conventions.md#10-known-inconsistencies-flagged-for-phase-0-normalization) for the full inconsistency list.)

---

## 4. Template files inside `dot_topics/`

`.tmpl` works inside `dot_topics/` just like anywhere else under `home/` — chezmoi renders the template **before** writing the destination, so by the time the loader sources `~/.topics/<tool>/path.zsh`, it's already plain shell.

**Templates present:**

| Source | Destination | Why templated |
|--------|-------------|---------------|
| `home/dot_topics/dotnet/executable_path.zsh.tmpl` | `~/.topics/dotnet/path.zsh` (executable) | likely OS-conditional `$DOTNET_ROOT` resolution |
| `home/dot_topics/system/path.zsh.tmpl` | `~/.topics/system/path.zsh` (NOT executable — see § 3) | system-level PATH adjustments that vary per machine |

The loader doesn't care that the source was a template — it sees the rendered `.zsh` file at the destination and sources it.

---

## 5. Adding a new tool — concrete 4-line recipe

For a hypothetical new tool `bun`:

```bash
mkdir home/dot_topics/bun/
# If bun needs $PATH adjusted before other tools see it:
echo 'export PATH="$HOME/.bun/bin:$PATH"' > home/dot_topics/bun/executable_path.zsh
# If bun has a shell-hook to eval (e.g. autocompletion):
echo 'eval "$(bun completions zsh)"' > home/dot_topics/bun/executable_eval.zsh
# If bun needs an install step (downloaded once per machine, not every shell):
cat > home/dot_topics/bun/executable_install.sh <<'EOF'
#!/usr/bin/env bash
command -v bun >/dev/null || curl -fsSL https://bun.sh/install | bash
EOF
```

**Then on next `chezmoi apply`:**
1. The four files land at `~/.topics/bun/`.
2. `run_onchange_after_03-install-topics.sh.tmpl` re-runs (its rendered content changed because the `find` would now match a new `install.sh`) and executes the new installer.
3. On next shell start, `~/.zshrc` sources `~/.topics/bun/path.zsh` (pass 1) then `~/.topics/bun/eval.zsh` (pass 3 middle). The install.sh is NOT sourced (extension is `.sh`).

**Conventions to follow:**

- Use `executable_` prefix on every `.zsh` and `.sh` file (the destination needs to be executable for `source` to work cleanly and for `install.sh` to be invoked by `find ... | /bin/bash`).
- If your tool only needs middle-pass treatment (aliases, config, eval), name the file by intent (`aliases.zsh`, `config.zsh`, `eval.zsh`). The loader treats them all identically in pass 3.
- If your tool has nothing to source (install-only), just create the directory + `install.sh` — the loader will glob no `.zsh` and do nothing.

---

## 6. Cross-link

For the broader chezmoi attribute-prefix conventions (`dot_`, `private_`, `executable_`, `exact_`, `modify_`), `.chezmoiscripts/` lifecycle buckets, and externals refresh policy, see [`conventions.md`](./conventions.md).

---

*Document populated from live-tree inspection (Plan 00.5-02 Task 1) per Phase 0.5 CONTEXT.md decision: "describe what is actually in the tree, not the idealized 4-type model."*
