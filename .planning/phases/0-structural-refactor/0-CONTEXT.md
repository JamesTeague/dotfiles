# Phase 0: Structural Refactor — Context

**Gathered:** 2026-05-31 / 2026-06-01
**Status:** Ready for planning
**Source:** Pre-plan discussion (continuation of Phase 0.5 close 2026-05-29)
**Predecessor:** Phase 0.5 closed 2026-05-29 with both-Mac `chezmoi diff -x externals` PASS (Mac personal empty; Mac work via single justified `.zshrc` NODE_EXTRA_CA_CERTS escalation). 9 follow-ups captured for Phase 0 consumption.

<domain>
## Phase Boundary

Land the `role × personal × os × wsl` taxonomy atomically on a branch with `chezmoi diff -x externals` empty on BOTH active Macs as merge gate. Cutover ritual is itself part of the phase — Mac work + Mac personal cut over together via a versioned script before merge. Lonestar is OUT of scope (status unclear, fresh-init when it lands won't need cutover).

No secret-plane work (Phase 1 owns). No Windows files (Phase 2 owns). No WSL work beyond the `not wsl` filter (Phase 3 owns).
</domain>

<decisions>
## Implementation Decisions

### Goal Amendments (from inherited ROADMAP Phase 0 goal)

The roadmap goal language has two misframings to correct in planning:

1. **DROP SC #5** ("`home/scripts/generate-gpg-key.sh` is DELETED from the source tree"). The script is load-bearing via `home/modify_dot_gitconfig.local:6` (chezmoi modify-template that runs on every apply, captures script stdout as `~/.gitconfig.local` content). Deleting it in Phase 0 breaks `git commit -S` on next apply. **Defer to Phase 1**, which already owns the atomic VaultWarden-canonical-GPG-key landing — script delete + `modify_dot_gitconfig.local` rewrite happen together as part of SEC-* requirements.

2. **DROP Pitfall 11 reference** for `generate-gpg-key.sh`. Pitfall 11 is "`run_once_` state survives refactors." This script is NOT a `run_once_` — `chezmoistate.boltdb` dump (Phase 0.5 capture) confirmed zero `scriptState` entries for it; it lives in `entryState` (regular file). Pitfall 11 still applies generally to Phase 0 script renames, just not to this specific script.

3. **REFRAME SC #2** "`.chezmoiignore` … single gating decision point." Interpretation: FILE PRESENCE only. Template-internal runtime logic (e.g., `{{ if eq .chezmoi.os "darwin" }}` blocks inside scripts) stays in templates; `.chezmoiignore` can only gate whether a file exists at the destination at all.

4. **ADD** `.localrc` + `~/.local/bin/` employer-local pattern documentation. Resolves Phase 0.5 follow-ups #6 (NODE_EXTRA_CA_CERTS escalation) and #9 (`exact_bin` rename / standardize). NOT a 5th axis — `dot_zshrc.tmpl:4-7` already sources `~/.localrc`, and `~/.local/bin/` is already first on PATH via mise. Pattern is "personal-identity stays in chezmoi; employer/site-local stays per-machine."

### Employer Axis (resolves follow-up #6)

**Decision: Option B — per-machine `~/.localrc` + `~/.local/bin/`. Not a 5th axis.**

Three reasons B wins over a templated employer axis: (i) content (e.g., NODE_EXTRA_CA_CERTS path) references employer-IT-provisioned files out-of-band — templating one line of indirection isn't substance; (ii) dotfiles are personal-identity, not workplace artifacts — employer config leaks + contaminates over time; (iii) pattern is half-adopted already (Phase 0.5 put `start-aws-mcp.sh` at `~/.local/bin/` outside chezmoi).

Mac work cutover work: hand-migrate the existing `NODE_EXTRA_CA_CERTS=...` line from `~/.zshrc` to `~/.localrc`. Cutover script autodetects via `grep -q NODE_EXTRA_CA_CERTS ~/.zshrc`.

### exact_bin Teardown (resolves follow-up #9)

**Decision: delete `home/exact_bin/`; move 5 scripts to `home/private_dot_local/bin/`.**

The 5 utilities (`dot`, `git-bare-clone`, `git-wtf`, `tmux-cht.sh`, `tmux-sessionizer`) are personal-identity — keep chezmoi-managed. Both tmux scripts are invoked by bare command name (`bindkey -s "^f" "tmux-sessionizer\n"`; `tmux neww tmux-cht.sh`); bare-name resolution Just Works because `~/.local/bin/` is first on PATH via mise.

Per-machine cutover side effect: `~/bin/` directory becomes unmanaged but files persist (chezmoi's `exact_` directive only enforced while source carries `exact_bin/`). Cutover script does `rm -rf ~/bin/` followed by 5× `chezmoi state delete --bucket=entryState --key /Users/jteague/bin/<entry>` for state hygiene. Use space-separated `--key /path` form (follow-up #7: `--key=` triggers zsh CLI parsing pitfall).

### packages.yaml Restructure

**Current shape (131 lines):** `packages.{core, darwin, linux, personal.{core, darwin, linux}, work.{darwin, linux}}` — no role concept.

**New shape:**
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

Decisions on each question:
- **Q1 (core resolution):** push current `core` into `roles.dev.core` (cross-OS). Teague confirmed "core had things needed on MacOS and Linux on any dev machine" — that's the dev-role-universal semantic. Name continuity preserved.
- **Q2 (Mac casks misfile):** resolved as side-effect of Q1 — current `core.casks` (fonts, bitwarden, docker-desktop, etc.) lands in `roles.dev.darwin.casks`.
- **Q3 (move-history comments):** drop all. Keep ONLY the load-bearing `localstack-cli` warning (trimmed).
- **Q4 (empty placeholders):** prune; consumer uses `hasKey`. Overlays don't get a cross-OS `core` layer (asymmetric with roles is fine).
- **Q5 (consumer rewrite scope):** ~131 lines `packages.yaml` + ~123 lines `home/.chezmoitemplates/brew` rewrite (6 copy-pasted personal/else-work branches) + 7→12 lines `03-mas.sh.tmpl`. Keep copy-paste pattern in brew template (DRY refactor is YAGNI for 6 branches). 4 latent Linux-overlay bugs fixed inline (`brew` template lines 70-78 say `tap` when they mean `brew`; lines 110-118 say `tap` when they mean `cask`).

### Role Prompt

- **Values:** `dev | gaming | lite` (per PROJECT.md + ROADMAP — Lonestar adopts `role=dev`; WSL is orthogonal axis)
- **Default:** `dev`
- **Function:** `promptChoiceOnce` — built-in typo validation; persists once
- **Enum DRY:** hardcode in `.chezmoi.toml.tmpl` + consumer templates (3 values, factoring is YAGNI)
- **Loud-fail guard:** template-level `{{ if not (hasKey . "role") }}{{ fail "Role not set. Run: chezmoi init --apply" }}{{ end }}` in `02-install-packages.sh.tmpl` to prevent silent-skip on partial cutover
- **Chezmoi version floor:** ≥ 2.70.4 enforced as cutover preflight (Mac work currently 2.69.4 — bump is part of cutover, not optional)

**Existing prompts in `.chezmoi.toml.tmpl`** (16 lines, verified 2026-06-01): all use `*Once` variants (`promptBoolOnce` for `personal`; `promptStringOnce` for `name` + `email`). Plus a computed `wsl = ...` from osrelease. Means `chezmoi init --apply` on existing machines re-prompts ONLY for the new `role` field. Confirmed via chezmoi/init docs: `--data` defaults true, `promptChoiceOnce` returns existing value if path present.

### .chezmoiignore Templating

**Files needing Phase 0 gates** (file-presence only — runtime logic stays in templates):
- `home/private_dot_config/aerospace/` → darwin only
- `home/private_dot_config/flameshot/` → linux + not wsl + role=dev (per SC #6)
- `home/.chezmoiscripts/run_onchange_after_darwin-configure.sh.tmpl` → darwin only
- `home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl` → darwin + not wsl
- Preserve existing `.oh-my-zsh/cache/**` line

**Consolidation payoff:** drop template-internal OS gates from the gated templates. `03-mas.sh` body simplifies from full and-chain to `{{ if .personal }}` (presence guarantees darwin + not-wsl).

**Style:** conditional-include grouped by gate.

**No pre-stubbing** of Windows/gaming/lite files — Phase 2/3 land those.

### Cutover Ritual

**Scope:** Mac work + Mac personal only. Lonestar status unclear; when it lands it's a fresh `chezmoi init` (no cutover applicable).

**Artifact:** `cutover-phase-0.sh` lives at `.planning/phases/0-structural-refactor/cutover-phase-0.sh`, versioned with the phase. Per-machine usage:
1. `cd ~/.local/share/chezmoi && git checkout <phase-0-branch> && git pull`
2. `bash .planning/phases/0-structural-refactor/cutover-phase-0.sh`
3. Answer role prompt interactively (`dev`)

**Script steps (in order):**
1. **Print snapshot path FIRST** (before any mutation) so failure mid-script leaves a known restore point: `~/dotfiles-cutover-snapshot-<timestamp>/`
2. **Preflight:** `chezmoi --version` ≥ 2.70.4; die loud if not
3. **Snapshot (targeted, not full `~/.config/`):** `chezmoi.toml`, `.zshrc`, `.localrc` (if exists), `.gitconfig.local`, `-a ~/bin/`
4. **Pre-pull migration (autodetect Mac work):** if `grep -q NODE_EXTRA_CA_CERTS ~/.zshrc`, append line to `~/.localrc` and `sed` delete from `~/.zshrc`; print "Detected Mac work: migrated NODE_EXTRA_CA_CERTS"
5. **`chezmoi init --apply`** — role prompt fires interactively (intentional; one keystroke per machine acknowledges role). Pre-existing prompts skipped via `*Once`.
6. **exact_bin teardown:** `rm -rf ~/bin/`; 5× `chezmoi state delete --bucket=entryState --key /Users/jteague/bin/<entry> || true` (space-separated `--key /path` form per follow-up #7)
7. **Verify SC #4:** `chezmoi diff -x externals` empty
8. **Verify SC #3:** `chezmoi apply --dry-run --verbose 2>&1 | grep "no value"` empty

`set -euo pipefail`. On verify-gate failure, exit non-zero — manual recovery from snapshot. No auto-rollback.

### Three-Commit Breakdown

Phase 0 lands as three logical commits to keep the `chezmoi diff -x externals` merge gate readable:

1. **Structural commit** — packages.yaml restructure + role prompt + `.chezmoiignore` templating + `exact_bin` teardown + brew/03-mas consumer rewrite + 4 inline Linux-overlay bug fixes + cutover script. This is the big cut; merge gate runs against THIS.
2. **Mas guard commit** — `03-mas.sh` `/Applications/<App>.app` presence pre-check (follow-up #4). Separate so structural diff is pure.
3. **Docs commit** — `docs/conventions.md` § 10 update: AUD-02 LIGHT remainder (6 inherited inconsistencies) + follow-ups #1, #2, #3, #5, #8 as pitfall/pattern notes.

### Phase 0.5 Follow-ups Disposition

| # | Disposition |
|---|---|
| 1 | docs commit: `chezmoi state dump` as canonical clean-check utility |
| 2 | docs commit: pitfall — `chezmoi apply --dry-run --verbose` exits nonzero on interactive TTY prompts |
| 3 | docs commit: pitfall — `mas list` Apple ID visibility (mas guard from #4 is the practical fix) |
| 4 | code: separate commit, `03-mas.sh` `/Applications/` guard |
| 5 | docs commit: state-forge pattern documentation |
| 6 | absorbed: `.localrc` + Mac-work NODE_EXTRA_CA_CERTS migration in cutover script |
| 7 | code: cutover script preflight (≥2.70.4) + `--key /path` space-separated form |
| 8 | docs commit: Pitfall C re-validation note (source-delete does NOT auto-remove destination on either chezmoi version) |
| 9 | absorbed: `exact_bin` teardown → `private_dot_local/bin/` in structural commit |

### Claude's Discretion

- Plan-file split: structural + mas guard + docs as separate plan files vs. one plan with internal commit boundaries (lean: three plans, parallels the three commits)
- Exact cutover-script filename if `cutover-phase-0.sh` is awkward
- Exact format of snapshot directory layout
- Exact wording of `docs/conventions.md` § 10 additions
- Order of plan execution (lean: structural → mas guard → docs; cutover script is committed with structural but RUN after merge)
- Whether the cutover script lives only in `.planning/` or also gets a symlink/copy in `scripts/` for discoverability (lean: `.planning/` only — it's phase-scoped, not a permanent tool)

</decisions>

<specifics>
## Specific Ideas

### Out of Scope (Phase 1+ owns)

- `home/scripts/generate-gpg-key.sh` deletion + `modify_dot_gitconfig.local` rewrite → Phase 1 (atomic with VaultWarden landing)
- VaultWarden, GPG canonical key, SSH per-purpose keys, bootstrap kit → Phase 1
- Windows files, pwsh, winget, Stream Deck, `role=gaming`, `role=lite` stubs → Phase 2
- WSL-specific `.wslconfig` / `wsl.conf` work → Phase 3
- Lonestar onboarding → Phase 4

### Risk Areas to Carry into Plans

- **Merge gate fragility.** SC #4 is `chezmoi diff -x externals` empty on BOTH Macs. The mas guard commit (#4) MUST land after structural so the structural diff is pure. If mas guard surfaces unexpected drift on Mac work (apps installed under a different Apple ID), Plan must include a fix-source-vs-fix-machine decision point, not just an assertion.
- **Cutover script verify-gate failure recovery.** Snapshot is targeted (5 paths + ~/bin/), not full `~/.config/`. If chezmoi.toml lands wrong via `init --apply`, restore from snapshot; if the source tree itself is the problem, `git revert` + re-apply. Document recovery path in plan.
- **Pitfall 9 latent risk** (rename → silent `<no value>`). Loud-fail guard on `role` is the primary defense; pre-flight `chezmoi execute-template` pass on fixture data is still worth a line-item in the structural plan.
- **`chezmoi init --apply` re-prompt behavior** — confirmed via docs + reading `.chezmoi.toml.tmpl` (all `*Once`). If a future plan revision touches `.chezmoi.toml.tmpl` without preserving `*Once`, the cutover ritual silently breaks. Plan should call this out.

### Pitfall Mitigations the Roadmap Baked In (carry forward)

- Pitfall 1 (`promptStringOnce` discipline) → `role` uses `promptChoiceOnce`; existing prompts already use `*Once` (verified)
- Pitfall 2 (`chezmoi diff` blind to script side-effects) → cutover script pairs `diff` with `apply --dry-run --verbose`
- Pitfall 9 (renaming variables → silent `<no value>`) → loud-fail `hasKey` guard + dry-run grep gate
- Pitfall 11 (`run_once_` state survives refactors) → still applies generally to script renames in this phase; just doesn't apply to `generate-gpg-key.sh` (entryState, not scriptState; deferred to Phase 1)
- Pitfall C (source-delete leaves destination) → cutover script `rm -rf ~/bin/` + state-bucket cleanup is the explicit handling

</specifics>

<deferred>
## Deferred Ideas

- **Apple ID provenance audit script** (follow-up #3 strong form) — file-presence guard from #4 is the practical fix; full provenance audit is overkill for Phase 0
- **`chezmoi state dump` automated assertion** (follow-up #1 strong form) — useful pattern, documented as utility; not a load-bearing assertion in Phase 0 verify gates
- **DRY refactor of brew template's 6 copy-pasted personal/else-work branches** — YAGNI; revisit if a 7th branch surfaces
- **Pre-stubbing Windows/gaming/lite files** — Phase 2/3 own these; pre-stubs would be dead code in Phase 0
- **Lonestar-specific bootstrap path** — status unclear; defer until Lonestar work resumes

</deferred>

---

*Phase: 0-structural-refactor*
*Context gathered: 2026-05-31 / 2026-06-01 via two-session discussion (post-Phase-0.5-close)*
