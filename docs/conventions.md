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

## 10. Phase 0 Patterns, Follow-up Pitfalls, and AUD-02 Remainder

This section captures Phase 0 goal amendments, the employer-local pattern, the Linux package management locked decision, five follow-up pitfall/pattern notes from the Phase 0.5 disposition table, and the six AUD-02 LIGHT inconsistencies with their Phase 0 resolution status.

---

### 10.1 Phase 0 Goal Amendments (supersede ROADMAP Success Criteria)

#### 10.1.1 `generate-gpg-key.sh`: DEFERRED to Phase 1 (NOT deleted in Phase 0)

The ROADMAP Phase 0 SC #5 reads "`home/scripts/generate-gpg-key.sh` is DELETED from the source tree." This was **amended before Phase 0 code work began** (see `0-CONTEXT.md` Amendment #1).

**Rationale:** The script is load-bearing. `home/modify_dot_gitconfig.local` is a chezmoi `modify_` template (line 6): on every `chezmoi apply` it executes this script, captures stdout, and writes the result as `~/.gitconfig.local`. Deleting the script in Phase 0 breaks `git commit -S` on the next apply. Phase 1 owns the atomic VaultWarden-canonical-GPG-key landing — delete + `modify_dot_gitconfig.local` rewrite happen together as part of SEC-* requirements.

The Phase 0 Wave 0 harness (`.planning/phases/0-structural-refactor/checks/quick.sh`) includes a positive assertion that `home/scripts/generate-gpg-key.sh` is STILL PRESENT, ensuring no accidental deletion slips through Phase 0.

#### 10.1.2 `.chezmoiignore`: FILE PRESENCE only (not template-internal logic)

The ROADMAP Phase 0 SC #2 calls `.chezmoiignore` "the single gating decision point." This was **reframed** (see `0-CONTEXT.md` Amendment #3/2):

**Interpretation:** `home/.chezmoiignore` gates whether a **file exists at the destination at all**. Template-internal runtime logic — for example, `{{ if eq .chezmoi.os "darwin" }}` blocks inside a script body — stays in templates. `.chezmoiignore` cannot gate logic inside a file; it can only gate the file's presence.

**Phase 0 gates in `home/.chezmoiignore` (file-presence only):**
- `~/.oh-my-zsh/cache/**` — inherited externals cache noise
- `home/private_dot_config/aerospace/` → darwin only
- `home/private_dot_config/flameshot/` → `role=dev + os=linux + not wsl`
- `home/.chezmoiscripts/run_onchange_after_darwin-configure.sh.tmpl` → darwin only
- `home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl` → darwin + not wsl

---

### 10.2 Employer-Local Pattern: `~/.localrc` + `~/.local/bin/`

This is the resolution for Phase 0.5 follow-ups #6 (employer `NODE_EXTRA_CA_CERTS` escalation) and #9 (`exact_bin` teardown); the **code-side resolutions** live in Plan 01's `exact_bin` teardown and the `cutover-phase-0.sh` migration step. This section documents the pattern.

**Pattern:** Personal-identity content stays chezmoi-managed. Employer/site-local content stays per-machine in:

- `~/.localrc` — sourced by `home/dot_zshrc.tmpl` lines 4-7 (already in source tree). Add employer-specific env vars here (e.g., `export NODE_EXTRA_CA_CERTS=/Users/jteague/.certs/CAcerts.pem` for Bluebeam corporate Node TLS). Not chezmoi-managed.
- `~/.local/bin/` — first on PATH via mise. Employer-specific scripts go here (e.g., `start-aws-mcp.sh` for Bluebeam AWS tooling, moved here in Phase 0.5 Plan 06). Not chezmoi-managed.

**Why this beats a 5th templated axis (employer/site axis):**
1. Content (e.g., `NODE_EXTRA_CA_CERTS` path) references employer-IT-provisioned files out-of-band — templating one line of indirection adds nothing.
2. Dotfiles are personal-identity; employer config leaks and contaminates the repo over time.
3. Pattern is half-adopted already (Phase 0.5 Plan 06 confirmed `~/.local/bin/` on PATH via mise; `start-aws-mcp.sh` was already moved there).

**Mac work cutover:** the `cutover-phase-0.sh` script autodetects Mac work via `grep -q NODE_EXTRA_CA_CERTS ~/.zshrc` and migrates the line to `~/.localrc` before `chezmoi init --apply` runs.

---

### 10.3 LNX-05 Locked Decision: NO Linux Homebrew

**Decision:** Linux install scripts use **apt + mise only**. Homebrew on Linux (`linuxbrew`) is explicitly excluded.

**Rationale:** Homebrew on Linux is a divergence from the platform's native package graph. apt handles system-level tools; mise handles language runtimes and developer tools (already the pattern on Mac for mise-managed tools like Node, Python, Ruby). The `packages.yaml` shape supports this: `roles.dev.linux.brews` keys exist in the YAML (see `home/.chezmoidata/packages.yaml`) but the Phase 3 consumer will use apt + mise to satisfy them — NOT `brew bundle`. The `brew` partial template (`home/.chezmoitemplates/brew`) renders Linux output but Phase 3's apt/mise consumer is the intended runtime.

**Phase 3** owns the apt + mise consumer scripts in `home/.chezmoiscripts/linux/`. Phase 0 commits the YAML shape (`roles.dev.linux.{brews,casks,taps}`) as the declarative inventory; Phase 3 writes the installer that reads it.

---

### 10.4 Phase 0.5 Follow-up Pitfall/Pattern Notes (docs-owned: #1, #2, #3, #5, #8)

These five items were identified during Phase 0.5 reconciliation and disposition-tabled for documentation in Phase 0. The code-side fixes for the related issues (#4 `/Applications/` guard, #6 `.localrc` migration, #7 version floor, #9 `exact_bin` teardown) live in Plans 01 and 02.

#### 10.4.1 `chezmoi state dump` as canonical clean-check utility (follow-up #1)

`chezmoi state dump` prints the full contents of `chezmoistate.boltdb` as JSON. Use it for ad-hoc "is my state bucket clean?" inspection when `chezmoi managed` and `chezmoi diff` are both silent but something feels wrong.

**Example use case:** Phase 0.5 Plan 04 found that `chezmoi managed | grep flameshot` and `chezmoi diff -x externals | grep flameshot` returned nothing after a source-delete, even though flameshot still had stale `entryState` keys in the database. The only discovery surface for orphaned-state-only entries is `chezmoi state dump | grep -i flameshot`.

**NOT a load-bearing gate:** This is a utility for manual investigation, not a Phase 0 verify gate. Do not gate on `chezmoi state dump` output in automated checks — state bucket entries are not consistently structured across chezmoi versions.

#### 10.4.2 `chezmoi apply --dry-run --verbose` exits nonzero on interactive TTY prompts (follow-up #2)

When `home/dot_zshrc.tmpl` line 80 (or equivalent) contains an interactive `DEBUG=1` question, `chezmoi apply --dry-run --verbose` exits nonzero even though the source is otherwise valid. This is a false-positive failure.

**Mitigation options:**
- Filter dry-run output: `chezmoi apply --dry-run --verbose 2>&1 | grep "no value"` — the absence of `"no value"` lines is the actual gate.
- Reconcile pre-existing drift before running (chezmoi apply removes the prompt line, then dry-run passes cleanly).
- Do NOT gate automation on `--dry-run` exit code alone when the source tree may have interactive prompts.

The `cutover-phase-0.sh` script uses the filtered-grep approach (step 8 of the cutover ritual).

#### 10.4.3 `mas list` Apple ID invisibility (follow-up #3)

`mas list` only shows apps under the **currently signed-in Apple ID**. Apps installed under a different Apple ID — or sideloaded/provisioned before `mas` could index them — are visible in `/Applications/` but absent from `mas list`.

**Example:** `Brother iPrint&Scan.app` was in `/Applications/` on Mac personal but invisible to `mas list`. The warning `Warning: Found a likely App Store app that is not indexed in Spotlight in /Applications/Brother iPrint&Scan.app` is the canonical signature.

**Practical fix:** File-presence guard around every `mas install` call — see `home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl` (Plan 02). The guard checks `[[ ! -d "/Applications/${app_name}.app" ]]` and skips the install if the bundle already exists, bypassing the Apple ID mismatch entirely.

#### 10.4.4 `chezmoi state set` (state-forge) pattern (follow-up #5)

`chezmoi state set --bucket=entryState --key=<absolute-path> ...` is the symmetric inverse of `chezmoi state delete`. Use it when the **underlying reality has been verified by another mechanism** but chezmoi's state bucket doesn't reflect it.

**Example:** Phase 0.5 Plan 06 Task 1 used state-forge for `~/.chezmoiscripts/03-mas.sh`. Brother iPrint&Scan was confirmed installed via `ls /Applications/ | grep -i brother`, but `mas install` would fail (Spotlight re-index sudo prompt in non-TTY context). Forging the `contentsSHA256` from the old rendered value to the new one told chezmoi "this scripted intent is already satisfied" — which was TRUE.

**Caveat:** State-forge is legitimate ONLY when reality is verified by another mechanism. Never blind-forge. Document the justification in the commit message or a planning note (see `00.5-drift-reconciliation.md` for the Pattern 06 justification).

**Command form:** `chezmoi state set --bucket=entryState --key /absolute/path/to/file` (space-separated `--key /path` form — see § 10.4.5 for the `=` form pitfall).

#### 10.4.5 Pitfall C re-validation: source-delete does NOT auto-remove destination on either chezmoi 2.69.4 or 2.70.4 (follow-up #8)

**Empirical result (Phase 0.5, both machines):** After `git rm` of a source file and `chezmoi apply`, the destination file remains. This was confirmed on:
- Mac personal: chezmoi 2.70.4 — `chezmoi diff -x externals` silent; destination still present; only entryState retained the orphan.
- Mac work: chezmoi 2.69.4 — same behavior.

**The only mechanism that removes the destination is operator-driven `rm`** (plus optional `chezmoi state delete --bucket=entryState --key /path` for state hygiene; the destination delete is the load-bearing part).

**For bulk source-deletes** (e.g., `home/exact_bin/` teardown in Plan 01): the `exact_` directive on the source directory IS the mechanism — `exact_` enforces that the destination directory contains ONLY entries in the source tree. When you delete the `exact_` source dir and run `chezmoi apply`, the destination dir is pruned. This is the ONLY path where apply auto-removes; a normal (non-`exact_`) source-delete does not.

**CLI form note (from follow-up #7):** On Mac work with chezmoi 2.69.4 + zsh, `chezmoi state delete --bucket=entryState --key=/path` (equals sign) triggers a zsh EQUALS option parse error. Use space-separated form: `chezmoi state delete --bucket=entryState --key /path`.

#### 10.4.6 Shell heredoc terminator must render at column 0 (Phase 0 cutover regression)

**Symptom:** During Mac personal cutover, `chezmoi init --apply` failed at `before_02-install-packages.sh` with:

```
Error: Invalid Brewfile: uninitialized constant Homebrew::Bundle::Dsl::EOF
```

**Cause:** The `brew` chezmoitemplate uses `brew bundle --file=/dev/stdin << EOF ... EOF`. Accumulated trailing whitespace from nested `{{ end -}}` blocks rendered the closing terminator as `      EOF` (six leading spaces). Bash heredocs opened with `<< EOF` (no dash) require the terminator at column 0 — with any leading whitespace the heredoc never closes, and the literal text `EOF` gets piped to `brew bundle` as Brewfile content, where Ruby interprets it as an undefined constant.

**Fix (committed `90e9826`):** Change the final `{{ end -}}` in the brew template to `{{- end }}` so the leading-strip eats accumulated whitespace from inner end-blocks, leaving `EOF` on its own line at column 0.

**Convention:** Any template that emits a shell heredoc with `<< MARKER` (no dash) must guarantee the closing `MARKER` renders at column 0. Patterns that work:
- Use `{{- end }}` (left-strip) on the end-block immediately preceding the terminator line, OR
- Put `{{- "" }}` on the terminator line itself to strip preceding whitespace.

Validate by rendering with `chezmoi execute-template < script.sh.tmpl | sed -n 'l'` and confirming the terminator line begins with `$` (no spaces before it).

Do not use `<<- EOF` as a workaround unless you also convert template indentation to tabs — `<<-` strips leading **tabs only**, not spaces.

#### 10.4.7 Cutover-script chezmoi-diff gate must separate stdout from stderr (Mac work false-positive)

**Symptom:** Mac work Phase 0 cutover failed Step 7 with:

```
gpg: WARNING: server 'keyboxd' is older than us (2.4.9 < 2.5.20)
gpg: Note: Outdated servers may lack important security fixes.
```

`chezmoi diff -x externals 2>/dev/null` returned empty (zero drift), but the script captured `2>&1` and treated any output as drift.

**Cause:** `modify_dot_gitconfig.local` is a modify-script template that invokes `gpg`. During `chezmoi diff` rendering, gpg may emit version-mismatch warnings to stderr (machine-local — depends on installed keyboxd vs gpg versions). Those warnings are not template render failures and not file drift.

**Convention:** Any cutover/verify script that gates on `chezmoi diff` (or `chezmoi apply --dry-run`) emptiness MUST capture stdout separately. Pattern:

```bash
diff_err_log="$(mktemp)"
diff_out=$(chezmoi diff -x externals 2>"${diff_err_log}" || true)
if [[ -n "${diff_out}" ]]; then
  # real drift — fail
  echo "${diff_out}"
  # optional: surface stderr for diagnostic context
  [[ -s "${diff_err_log}" ]] && sed 's/^/  ! /' "${diff_err_log}" >&2
  exit 2
fi
rm -f "${diff_err_log}"
```

Step 8's `grep "no value"` check is naturally robust (greps for a specific string), but the diff-empty check is the high-risk gate.

---

### 10.5 AUD-02 LIGHT Remainder (6 inherited Phase 0.5 inconsistencies)

These six inconsistencies were surfaced during the Phase 0.5 audit and documented in the original § 10. They were deliberately NOT normalized in Phase 0.5 because doing so would change destination file modes and produce a non-empty `chezmoi diff`, breaking the phase exit gate.

Phase 0 disposition is noted for each. Items marked **RESOLVED** were fixed by Plan 01's restructure. Items marked **DEFERRED** remain in the source tree and require a future rename or restructure.

1. **`home/dot_topics/rust/path.zsh`** lacks the `executable_` prefix that every other `path.zsh` in this tree carries.
   **Phase 0 disposition: DEFERRED** — rename to `executable_path.zsh` is Phase 1+ work. The rename would set the executable bit at destination, producing a non-empty `chezmoi diff`. Not touched in Phase 0 to keep the merge gate clean.

2. **`home/dot_topics/system/path.zsh.tmpl`** lacks the `executable_` prefix.
   **Phase 0 disposition: DEFERRED** — same rationale as item 1 above.

3. **`run_onchange_after_darwin-configure.sh.tmpl`** lacks a numeric `NN-` prefix and routes by OS via its filename rather than the (not-yet-existing) OS subdirectory structure.
   **Phase 0 disposition: DEFERRED** — the OS-subdir layout (`darwin/`, `linux/`, `windows/`) is a Phase 3 deliverable. Phase 0 added `.chezmoiignore` gating for this file (darwin-only) which is the clean interim solution.

4. **`packages.yaml` `personal.{taps,brews,casks}` at top level AND nested `personal.darwin.{...}` block** — the top-level entries were dead code at the template level.
   **Phase 0 disposition: RESOLVED** — Plan 01 restructured `packages.yaml` to `roles.dev.{core,darwin,linux}` + `overlays.{personal,work}.darwin`. The old `personal.*` / `work.*` top-level shape is gone. See `home/.chezmoidata/packages.yaml` for current shape.

5. **`packages.yaml` `work.core.{taps,brews,casks}`** — also dead code at the template level (template ranged over `work.darwin.*` and `work.linux.*`, not `work.core`).
   **Phase 0 disposition: RESOLVED** — same Plan 01 restructure as item 4. The `work.core` key no longer exists.

6. **`.DS_Store` at repo root** — macOS Finder artifact; uncertain `.gitignore` coverage.
   **Phase 0 disposition: DEFERRED** — confirmed in `.gitignore` (repo root) as of Phase 0.5 inspection. If Finder re-creates it, the file will be ignored by git. Low priority; no Phase 1+ plan references this.

---

*Document populated from live-tree inspection per Phase 0.5 CONTEXT.md decision: "inspect the actual tree to derive content — do not invent conventions."*
*§ 10 expanded in Phase 0 Plan 03 (2026-06-03): goal amendments, employer-local pattern, LNX-05, follow-up pitfall notes, AUD-02 LIGHT dispositions.*
