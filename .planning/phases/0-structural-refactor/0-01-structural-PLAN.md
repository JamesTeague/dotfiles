---
phase: 0-structural-refactor
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/phases/0-structural-refactor/checks/lib.sh
  - .planning/phases/0-structural-refactor/checks/quick.sh
  - .planning/phases/0-structural-refactor/checks/full.sh
  - .planning/phases/0-structural-refactor/checks/fixtures/role-dev-darwin-personal.env
  - .planning/phases/0-structural-refactor/checks/fixtures/role-dev-darwin-work.env
  - .planning/phases/0-structural-refactor/checks/fixtures/role-dev-linux-personal.env
  - .planning/phases/0-structural-refactor/cutover-phase-0.sh
  - home/.chezmoi.toml.tmpl
  - home/.chezmoidata/packages.yaml
  - home/.chezmoiignore
  - home/.chezmoitemplates/brew
  - home/.chezmoiscripts/run_onchange_before_02-install-packages.sh.tmpl
  - home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl
  - home/private_dot_local/bin/executable_dot.tmpl
  - home/private_dot_local/bin/executable_git-bare-clone
  - home/private_dot_local/bin/executable_git-wtf
  - home/private_dot_local/bin/executable_tmux-cht.sh
  - home/private_dot_local/bin/executable_tmux-sessionizer
  - home/private_dot_config/flameshot/flameshot.ini
autonomous: true
requirements: [TAX-01, TAX-02, TAX-03, TAX-04, TAX-05, TAX-06, TAX-07, SEC-05, SS-03]
must_haves:
  truths:
    - "`role` is a `promptChoiceOnce` field with values dev|gaming|lite, default dev, in home/.chezmoi.toml.tmpl"
    - "All existing prompts in home/.chezmoi.toml.tmpl remain `*Once` variants (no `promptString` non-Once present)"
    - "home/.chezmoidata/packages.yaml has the new shape: packages.roles.dev.{core,darwin,linux} + packages.overlays.{personal,work}.<os>"
    - "home/.chezmoitemplates/brew consumes the new shape and the 4 Linux-overlay keyword bugs from the pre-rewrite file (audit refs: old lines ~70-78 + ~110-118) are fixed BY the rewrite emitting `brew` and `cask` correctly in the new linux loops (verified by grep of the rewritten file, not by line-range diff)"
    - "home/.chezmoiscripts/run_onchange_before_02-install-packages.sh.tmpl has a loud-fail `{{ if not (hasKey . \"role\") }}{{ fail ... }}` guard at top"
    - "home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl is rewritten to consume the new overlay shape (outer darwin/wsl gates moved to .chezmoiignore; body simplifies to `{{ if .personal }}`)"
    - "home/.chezmoiignore is templated and gates aerospace+darwin-configure+03-mas to darwin, flameshot to linux+not-wsl+role=dev, preserves `.oh-my-zsh/cache/**`"
    - "home/exact_bin/ is DELETED from source tree; the 5 utilities are at home/private_dot_local/bin/ with their `executable_` prefixes preserved"
    - "home/private_dot_config/flameshot/flameshot.ini is restored verbatim from .planning/phases/00.5-audit-documentation/00.5-04-flameshot-baseline.md (mode + SHA match)"
    - "home/scripts/generate-gpg-key.sh is UNTOUCHED (Phase 0 must not delete; goal amendment #1 defers to Phase 1)"
    - ".planning/phases/0-structural-refactor/checks/{lib.sh,quick.sh,full.sh} exist; quick.sh covers TAX-01..06, TAX-08, SS-03, loud-fail guard, and no-`<no value>` template-render assertions"
    - ".planning/phases/0-structural-refactor/cutover-phase-0.sh exists, executable, implements the locked 8-step sequence from 0-RESEARCH.md Pattern 4"
    - "`chezmoi execute-template --init --promptString name=t --promptString email=t@t --promptBool personal=true --promptChoice role=dev < home/.chezmoi.toml.tmpl` renders with `role = \"dev\"` and no `<no value>` strings"
    - "`bash .planning/phases/0-structural-refactor/checks/full.sh --no-diff-gate` returns 0"
  artifacts:
    - path: ".planning/phases/0-structural-refactor/checks/lib.sh"
      provides: "shared shell harness helpers (assert_file, assert_grep, assert_cmd_zero_output, summary)"
    - path: ".planning/phases/0-structural-refactor/checks/quick.sh"
      provides: "post-task automated gate (~5s); template-render + file-structure assertions"
    - path: ".planning/phases/0-structural-refactor/checks/full.sh"
      provides: "post-wave automated gate (~15s); adds fixture-scenario template renders; --no-diff-gate flag"
    - path: ".planning/phases/0-structural-refactor/cutover-phase-0.sh"
      provides: "operator-driven per-machine cutover script (8-step; NOT executed by executor — committed as artifact)"
    - path: "home/.chezmoi.toml.tmpl"
      provides: "+role promptChoiceOnce; existing *Once prompts preserved"
      contains: "promptChoiceOnce"
    - path: "home/.chezmoidata/packages.yaml"
      provides: "new role × overlay shape; ~131 lines; load-bearing localstack-cli warning trimmed to single line"
      contains: "roles:"
    - path: "home/.chezmoiignore"
      provides: "templated; 5 gates (aerospace, flameshot, darwin-configure, 03-mas, .oh-my-zsh cache pre-existing)"
      contains: "{{"
    - path: "home/.chezmoitemplates/brew"
      provides: "consumer rewrite against new shape; 4 Linux bug fixes inline; 6 copy-paste branches retained (DRY YAGNI)"
    - path: "home/.chezmoiscripts/run_onchange_before_02-install-packages.sh.tmpl"
      provides: "hasKey role loud-fail guard"
      contains: "hasKey"
    - path: "home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl"
      provides: "consumer rewrite against new shape (mas guard added in Plan 02)"
    - path: "home/private_dot_local/bin/"
      provides: "5 utilities moved from home/exact_bin/; non-exact directive"
    - path: "home/private_dot_config/flameshot/flameshot.ini"
      provides: "flameshot config restored from 0.5 baseline; gated by .chezmoiignore"
  key_links:
    - from: "home/.chezmoiscripts/run_onchange_before_02-install-packages.sh.tmpl"
      to: "home/.chezmoitemplates/brew"
      via: "{{ template \"brew\" . }} include"
      pattern: "template \"brew\""
    - from: "home/.chezmoitemplates/brew"
      to: "home/.chezmoidata/packages.yaml"
      via: ".packages.roles.dev.* + .packages.overlays.{personal,work}.* path traversal"
      pattern: ".packages.roles"
    - from: "home/.chezmoi.toml.tmpl"
      to: ".chezmoiignore + 02-install-packages.sh.tmpl + 03-mas.sh.tmpl"
      via: ".role data key (set by promptChoiceOnce; consumed downstream)"
      pattern: "\\.role"
    - from: "home/.chezmoiignore"
      to: "home/private_dot_config/flameshot/, home/private_dot_config/aerospace/, .chezmoiscripts/*darwin-configure*, .chezmoiscripts/*03-mas*"
      via: "templated conditional-include gates evaluated on every apply"
      pattern: "{{ if "
  out_of_scope_for_executor:
    - "Running cutover-phase-0.sh on Mac personal or Mac work (operator-driven, post-merge — per CLAUDE.md 'manual work = collaborative mode')"
    - "Verifying `chezmoi diff -x externals` empty on either Mac (manual-only per 0-VALIDATION.md; cutover script step 7 owns it on-machine)"
    - "Deleting home/scripts/generate-gpg-key.sh (deferred to Phase 1 per goal amendment #1)"
---

<objective>
Land the structural cut for Phase 0: introduce the `role` axis, restructure packages.yaml around `roles × overlays`, template `.chezmoiignore`, tear down `home/exact_bin/`, fix 4 latent Linux-overlay bugs in the brew partial, install the loud-fail `hasKey` guard, re-stage the flameshot config, install the Wave 0 validation harness, and commit the operator-driven cutover script as a phase artifact.

Purpose: This is the "big cut" — the merge gate (`chezmoi diff -x externals` empty on BOTH active Macs) runs against THIS commit. Plans 02 (mas guard) and 03 (docs) sit on top so the structural diff is pure.

Output: 1 git commit titled `feat(phase-0): structural taxonomy refactor (role × personal × os × wsl)`. Wave 0 harness + cutover script + all source-tree changes ship in the same commit (they are mutually load-bearing — harness validates the change; cutover script is the operational completion mechanism).
</objective>

<execution_context>
@/Users/jteague/.claude/get-shit-done/workflows/execute-plan.md
@/Users/jteague/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/0-structural-refactor/0-CONTEXT.md
@.planning/phases/0-structural-refactor/0-RESEARCH.md
@.planning/phases/0-structural-refactor/0-VALIDATION.md
@.planning/phases/00.5-audit-documentation/00.5-exit-gate-report.md
@.planning/phases/00.5-audit-documentation/00.5-04-flameshot-baseline.md
@.planning/phases/00.5-audit-documentation/checks/lib.sh
@.planning/phases/00.5-audit-documentation/checks/quick.sh
@home/.chezmoi.toml.tmpl
@home/.chezmoiignore
@home/.chezmoidata/packages.yaml
@home/.chezmoitemplates/brew
@home/.chezmoiscripts/run_onchange_before_02-install-packages.sh.tmpl
@home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl

<interfaces>
<!-- Locked contracts from 0-RESEARCH.md + 0-CONTEXT.md. Executor uses these verbatim — no codebase exploration needed for shape. -->

New `home/.chezmoi.toml.tmpl` shape (full file, replaces current 16 lines):
```go-template
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

New `home/.chezmoidata/packages.yaml` shape (executor maps existing keys per CONTEXT.md Q1-Q5):
```yaml
packages:
  roles:
    dev:
      core:            # was: packages.core (cross-OS dev essentials) — name continuity preserved
        brews: [...]
        taps: [...]
      darwin:          # was: packages.darwin (includes current core.casks per Q2)
        brews: [...]
        casks: [...]
        taps: [...]
      linux:           # was: packages.linux (currently empty placeholders — prune; consumer uses hasKey)
        brews: [...]
        casks: [...]
        taps: [...]
  overlays:
    personal:
      darwin:          # was: packages.personal.darwin
        brews: [...]
        casks: [...]
        mas: {<id>: {name: ..., id: ...}, ...}
        taps: [...]
    work:
      darwin:          # was: packages.work.darwin
        brews: [...]
        casks: [...]
        taps: [...]
# Note: no overlays.<axis>.core layer (Q4 — asymmetric with roles, fine).
# Drop ALL move-history comments (Q3); KEEP only the trimmed localstack-cli warning.
```

New `home/.chezmoiignore` (full file, replaces 1-line stub):
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

New `home/.chezmoiscripts/run_onchange_before_02-install-packages.sh.tmpl` header (prepend ABOVE existing content):
```go-template
#!/bin/bash
{{ if not (hasKey . "role") }}{{ fail "Role not set. Run: chezmoi init --apply" }}{{ end }}
```
(Existing shebang/content below — preserve `{{ template "utils" . }}` + brew-shellenv + `{{ template "brew" . }}`.)

New `home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl` shape (Plan 01 lays the consumer; Plan 02 adds the /Applications/ guard):
```go-template
#!/bin/bash
{{ if .personal -}}
  {{ range $k, $v := .packages.overlays.personal.darwin.mas }}
/opt/homebrew/bin/mas install {{ dig "id" "" $v }}
  {{ end -}}
{{ end -}}
```
(Outer `darwin + not-wsl` gate moved to .chezmoiignore — `.personal` is sufficient here because .chezmoiignore guarantees this file only exists on darwin+not-wsl. NOTE: Plan 02 will further wrap the `mas install` line with `/Applications/` guard — leave room for that change.)

New `home/.chezmoitemplates/brew` shape: REWRITE against new packages-path traversal. Pattern (repeat 3× for taps, brews, casks; with .personal/.else-work overlay branches):

```go-template
brew bundle --file=/dev/stdin << EOF

# Role-level (cross-OS)
{{ range .packages.roles.dev.core.taps -}}
tap {{ . | quote }}
{{ end -}}
{{ range .packages.roles.dev.core.brews -}}
brew {{ . | quote }}
{{ end -}}

# Role × OS
{{ if eq .chezmoi.os "darwin" -}}
  {{ if hasKey .packages.roles.dev "darwin" -}}
    {{ range .packages.roles.dev.darwin.taps -}}
tap {{ . | quote }}
    {{ end -}}
    {{ range .packages.roles.dev.darwin.brews -}}
brew {{ . | quote }}
    {{ end -}}
    {{ range .packages.roles.dev.darwin.casks -}}
cask {{ . | quote }}
    {{ end -}}
  {{ end -}}
{{ else if eq .chezmoi.os "linux" -}}
  {{ if hasKey .packages.roles.dev "linux" -}}
    {{ range .packages.roles.dev.linux.taps -}}
tap {{ . | quote }}
    {{ end -}}
    {{ range .packages.roles.dev.linux.brews -}}
brew {{ . | quote }}                          {# <-- BUG FIX: was `tap` at old lines 70-78 #}
    {{ end -}}
    {{ range .packages.roles.dev.linux.casks -}}
cask {{ . | quote }}                          {# <-- BUG FIX: was `tap` at old lines 110-118 #}
    {{ end -}}
  {{ end -}}
{{ end -}}

# Overlay × OS (personal else work — 6 copy-paste branches; DRY refactor YAGNI per Q5)
{{ if eq .chezmoi.os "darwin" -}}
  {{ if .personal -}}
    {{ if hasKey .packages.overlays "personal" -}}
      {{ range .packages.overlays.personal.darwin.taps -}}
tap {{ . | quote }}
      {{ end -}}
      {{ range .packages.overlays.personal.darwin.brews -}}
brew {{ . | quote }}
      {{ end -}}
      {{ range .packages.overlays.personal.darwin.casks -}}
cask {{ . | quote }}
      {{ end -}}
    {{ end -}}
  {{ else -}}
    {{ if hasKey .packages.overlays "work" -}}
      {{ range .packages.overlays.work.darwin.taps -}}
tap {{ . | quote }}
      {{ end -}}
      {{ range .packages.overlays.work.darwin.brews -}}
brew {{ . | quote }}
      {{ end -}}
      {{ range .packages.overlays.work.darwin.casks -}}
cask {{ . | quote }}
      {{ end -}}
    {{ end -}}
  {{ end -}}
{{ end -}}
EOF
```

Cutover script (`.planning/phases/0-structural-refactor/cutover-phase-0.sh`) — 8-step locked design verbatim from 0-RESEARCH.md Pattern 4 § "Example structure". `set -euo pipefail`. Operator-driven post-merge per CLAUDE.md.

Wave 0 harness mirrors `00.5-audit-documentation/checks/` pattern: copy lib.sh helper set; quick.sh runs file-existence + grep + `chezmoi execute-template` fixture renders; full.sh adds fixture-scenario expansion + `--no-diff-gate` flag.
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 0: Install Wave 0 validation harness</name>
  <files>
    .planning/phases/0-structural-refactor/checks/lib.sh,
    .planning/phases/0-structural-refactor/checks/quick.sh,
    .planning/phases/0-structural-refactor/checks/full.sh,
    .planning/phases/0-structural-refactor/checks/fixtures/role-dev-darwin-personal.env,
    .planning/phases/0-structural-refactor/checks/fixtures/role-dev-darwin-work.env,
    .planning/phases/0-structural-refactor/checks/fixtures/role-dev-linux-personal.env
  </files>
  <action>
Copy `.planning/phases/00.5-audit-documentation/checks/lib.sh` verbatim to `.planning/phases/0-structural-refactor/checks/lib.sh` (helpers, sentinel guard, STRICT_MODE handling — Phase 0.5 Plan 01 design proved it out; no need to redesign).

Write `quick.sh` to run these assertions (each emits PASS/FAIL via lib.sh helpers; suite returns nonzero on FAIL):

1. `assert_file home/.chezmoi.toml.tmpl`
2. `assert_grep 'promptChoiceOnce .* "role"' home/.chezmoi.toml.tmpl` — TAX-01
3. Negative: `grep promptString home/.chezmoi.toml.tmpl | grep -v Once` must be empty (Pitfall 1 defense)
4. `assert_file home/.chezmoidata/packages.yaml`
5. YAML structure check via `ruby -r yaml -e 'h = YAML.load_file("home/.chezmoidata/packages.yaml"); raise unless h.dig("packages","roles","dev","core") && h.dig("packages","overlays","personal","darwin") && h.dig("packages","overlays","work","darwin")'` — TAX-05 (fallback to `python3 -c "import yaml; ..."` if ruby missing — match Phase 0.5 Plan 01 detection order: ruby first, python3 fallback, pending if neither)
6. `assert_file home/.chezmoiignore`
7. `assert_grep '{{' home/.chezmoiignore` — TAX-06 (templated)
8. `assert_grep '\.role' home/.chezmoiignore` — TAX-06 (gates on role)
9. `assert_grep 'hasKey .*"role".*fail' home/.chezmoiscripts/run_onchange_before_02-install-packages.sh.tmpl` — loud-fail guard
10. `assert_dir_missing_strict home/exact_bin` — strict because Phase 0 invariant after this plan
11. `assert_file home/private_dot_local/bin/executable_dot.tmpl` (+ assert_file for the other 4)
12. `assert_file home/private_dot_config/flameshot/flameshot.ini` — SS-03 (re-staged from 0.5 baseline)
13. `assert_file home/scripts/generate-gpg-key.sh` — SEC-05 (MUST STILL EXIST in Phase 0; deferred to Phase 1)
14. `assert_file docs/dot_topics.md` — TAX-08 (inherited from 0.5)
15. Template render TAX-01: `chezmoi execute-template --init --promptString name=t --promptString email=t@t --promptBool personal=true --promptChoice role=dev < home/.chezmoi.toml.tmpl | grep -q '^  role = "dev"$'`
16. No-`<no value>` smoke: `chezmoi execute-template --init --promptString name=t --promptString email=t@t --promptBool personal=true --promptChoice role=dev < home/.chezmoi.toml.tmpl | grep -c '<no value>'` returns 0
17. Cutover script exists + is executable: `assert_file .planning/phases/0-structural-refactor/cutover-phase-0.sh && test -x .planning/phases/0-structural-refactor/cutover-phase-0.sh`
18. Call `summary` and exit with its return code.

Write `full.sh` to: (a) source lib.sh; (b) parse `--no-diff-gate` and `--no-quick` flags (same flag semantics as Phase 0.5 Plan 01 — `--no-diff-gate` skips `chezmoi diff -x externals` which is operator-driven; `--no-quick` runs full-only assertions); (c) `bash quick.sh` first (unless --no-quick); (d) run the fixture-scenario block: for each `fixtures/role-dev-*.env` file, source the fixture's `PROMPT_*` env vars, run `chezmoi execute-template --init ... < home/.chezmoi.toml.tmpl > /tmp/cm-toml-render-$$` and `chezmoi execute-template < home/.chezmoitemplates/brew > /tmp/cm-brew-render-$$`, grep both outputs for `<no value>` (must be empty), assert brew render has at least one `tap`/`brew`/`cask` line; (e) summary.

Fixture files: write three shell-sourceable `.env` files with `PROMPT_NAME=test PROMPT_EMAIL=t@t PROMPT_PERSONAL=true PROMPT_ROLE=dev` and OS-specific notes (the OS axis is controlled by the machine running the check — fixtures cover prompt axis only; OS-axis variance is exercised by running full.sh on both Macs at cutover time). Add a 2-line header comment in each fixture explaining its scenario.

After writing all files: `chmod +x .planning/phases/0-structural-refactor/checks/{quick,full}.sh`.

NOTE: This task creates the harness BEFORE source-tree changes, so the harness will FAIL on the first run — that's intentional. Subsequent tasks (1-5) bring the source tree into compliance; running quick.sh after Task 5 should be GREEN.
  </action>
  <verify>
    <automated>bash -n .planning/phases/0-structural-refactor/checks/lib.sh && bash -n .planning/phases/0-structural-refactor/checks/quick.sh && bash -n .planning/phases/0-structural-refactor/checks/full.sh && test -x .planning/phases/0-structural-refactor/checks/quick.sh && test -x .planning/phases/0-structural-refactor/checks/full.sh</automated>
  </verify>
  <done>
    Harness files exist, are syntactically valid bash, and are executable. Maps to 0-VALIDATION.md "Wave 0 Requirements" first 3 bullets. (Fixtures are content-only — bash -n covers the scripts; fixtures are checked by full.sh consumption.)
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 1: Restructure packages.yaml (TAX-05) + add role to chezmoi.toml.tmpl (TAX-01/02)</name>
  <files>
    home/.chezmoidata/packages.yaml,
    home/.chezmoi.toml.tmpl
  </files>
  <behavior>
    - `chezmoi execute-template --init --promptString name=t --promptString email=t@t --promptBool personal=true --promptChoice role=dev < home/.chezmoi.toml.tmpl` includes `role = "dev"` line in `[data]` and includes `personal = true` and `wsl = false` (or `true` on WSL). No `<no value>` in output.
    - `ruby -r yaml -e 'h = YAML.load_file("home/.chezmoidata/packages.yaml"); raise unless h.dig("packages","roles","dev","core") && h.dig("packages","roles","dev","darwin") && h.dig("packages","overlays","personal","darwin","mas") && h.dig("packages","overlays","work","darwin")'` exits 0.
    - The 4 empty Linux placeholders (linux.*, work.darwin.* keys with empty list values that are not load-bearing) are pruned per CONTEXT.md Q4. Consumer template (brew) will use `hasKey` — keys with non-empty lists stay; truly-empty placeholders are removed.
    - `grep -c "^#" home/.chezmoidata/packages.yaml` shows the move-history comments removed (Q3). The trimmed `localstack-cli` warning remains as a single comment line.
    - `grep promptString home/.chezmoi.toml.tmpl | grep -v Once` returns empty (Pitfall 1 — all prompts are *Once variants).
    - Every entry under `packages.overlays.personal.darwin.mas` is a YAML dict with both `name:` and `id:` keys (precondition for Plan 02's /Applications/ guard). `ruby -r yaml -e 'h = YAML.load_file("home/.chezmoidata/packages.yaml"); mas = h.dig("packages","overlays","personal","darwin","mas") || {}; mas.each { |k,v| raise "mas entry #{k} missing name" unless v.is_a?(Hash) && v["name"] && !v["name"].to_s.empty?; raise "mas entry #{k} missing id" unless v["id"] }'` exits 0.
  </behavior>
  <action>
**Sub-task 1A — `home/.chezmoi.toml.tmpl`:**

Replace the existing 16 lines with the locked shape in `<interfaces>` above. Add `$role := promptChoiceOnce . "role" "Machine role" (list "dev" "gaming" "lite") "dev"` and `role = {{ $role | quote }}` to the `[data]` block. All other prompts (`personal`, `name`, `email`) remain `*Once` variants. `$wsl` computation unchanged.

**Sub-task 1B — `home/.chezmoidata/packages.yaml` restructure:**

Read current `home/.chezmoidata/packages.yaml`. Mechanically map the existing keys to the new shape per CONTEXT.md Q1-Q5 + 0-RESEARCH.md "packages.yaml Restructure":

- `packages.core` → `packages.roles.dev.core` (Q1: cross-OS dev essentials; name continuity preserved)
- `packages.darwin.brews` → `packages.roles.dev.darwin.brews`
- `packages.darwin.taps` → `packages.roles.dev.darwin.taps`
- `packages.core.casks` (the current Mac-cask misfile — fonts, bitwarden, docker-desktop) → `packages.roles.dev.darwin.casks` (Q2 resolved as Q1 side-effect)
- `packages.linux.*` (currently empty placeholders) → drop (Q4); brew consumer uses `hasKey` defense
- `packages.personal.core` → `packages.roles.dev.core` if cross-OS personal; OR drop if it's Mac-only personal (see actual file for shape — Phase 0.5 Plan 05 left this structure intact; if `personal.core` is empty post-Plan-05, drop it)
- `packages.personal.darwin.{brews,casks,mas,taps}` → `packages.overlays.personal.darwin.{brews,casks,mas,taps}`
- `packages.personal.linux.*` → drop if empty (Q4); otherwise → `packages.overlays.personal.linux.*` (but only if non-empty; do NOT create empty overlay nodes)
- `packages.work.darwin.{brews,casks,taps}` → `packages.overlays.work.darwin.{brews,casks,taps}`
- `packages.work.linux.*` → drop if empty; otherwise → `packages.overlays.work.linux.*`

**Mas `name:` key validation/addition (hoisted from Plan 02 per checker warning #2):**

During the `packages.personal.darwin.mas` → `packages.overlays.personal.darwin.mas` restructure, iterate every mas entry and verify each is a dict with both `name:` (human-readable App Store/.app bundle name) and `id:` keys. If any entry is missing `name:`, do ONE of the following (in this order of preference):

1. **If running on Mac personal at edit time:** read `/Applications/` for the canonical `.app` bundle name and add `name: "Bundle Name"` to that entry verbatim. Use double-quoted YAML scalar to handle ampersands/spaces (e.g., `name: "Brother iPrint&Scan"`).
2. **Otherwise (off-machine or app missing):** HALT this sub-task with a clear error listing every mas `id:` that lacks a `name:` key, and require Teague to fill in the canonical names before continuing. Do not invent names — wrong names propagate into Plan 02's `[ ! -d "/Applications/${app_name}.app" ]` guard and silently disable the skip path.

Rationale: Plan 02 Task 1's guard depends on `dig "name" "" $v` resolving to the real `.app` bundle name. Missing-name entries would render `[ ! -d "/Applications/.app" ]` (always true → mas install fires → Spotlight re-index + sudo prompt on Brother iPrint et al.). Plan 01 Task 1 already owns `packages.yaml`, so the validation/addition fits cleanly here; Plan 02 becomes truly single-file.

Drop ALL move-history comments (Q3). KEEP the single load-bearing `localstack-cli` warning trimmed to one line above the localstack-cli formula entry (per CONTEXT.md Q3 + Phase 0.5 Plan 05 + Plan 06 reality correction in commit `3725e90`: `localstack-cli` is the maintained formula; `localstack` is upstream-deprecated).

**Style preservation:** This is a 131-line file. Use Phase 0.5 Plan 05 "hand-edit-over-yaml-roundtrip pattern" — targeted Edit tool calls preserve single-quote/inline-comment style. Do NOT round-trip through PyYAML/ruamel — that'll churn quoting and key order.

**Validate after edit:**
- `ruby -r yaml -e 'YAML.load_file("home/.chezmoidata/packages.yaml")'` exits 0 (valid YAML)
- The new top-level shape passes the structural check listed in <behavior>
- Diff the rendered brew output (after Task 2's brew template rewrite) against a known-good snapshot — defer this to Task 2's verify since the brew rewrite is what consumes the new shape.
  </action>
  <verify>
    <automated>bash .planning/phases/0-structural-refactor/checks/lib.sh 2>/dev/null; ruby -r yaml -e 'h = YAML.load_file("home/.chezmoidata/packages.yaml"); raise "missing roles.dev.core" unless h.dig("packages","roles","dev","core"); raise "missing overlays.personal.darwin" unless h.dig("packages","overlays","personal","darwin"); raise "missing overlays.work.darwin" unless h.dig("packages","overlays","work","darwin"); mas = h.dig("packages","overlays","personal","darwin","mas") || {}; mas.each { |k,v| raise "mas entry #{k} missing name" unless v.is_a?(Hash) && v["name"] && !v["name"].to_s.empty?; raise "mas entry #{k} missing id" unless v["id"] }; puts "ok"' && chezmoi execute-template --init --promptString name=t --promptString email=t@t --promptBool personal=true --promptChoice role=dev < home/.chezmoi.toml.tmpl | grep -E '^  role = "dev"$' && chezmoi execute-template --init --promptString name=t --promptString email=t@t --promptBool personal=true --promptChoice role=dev < home/.chezmoi.toml.tmpl | grep -c '<no value>' | grep -q '^0$'</automated>
  </verify>
  <done>
    packages.yaml structurally valid with new shape; chezmoi.toml.tmpl renders `role = "dev"` and zero `<no value>` strings. Maps to TAX-01, TAX-02, TAX-05. (TAX-03 + TAX-04 are inherited — `.chezmoi.os` and `.wsl` already work; no new code needed.)
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Rewrite brew template (TAX-05 consumer) + fix 4 Linux-overlay bugs + add hasKey guard (Pitfall 9)</name>
  <files>
    home/.chezmoitemplates/brew,
    home/.chezmoiscripts/run_onchange_before_02-install-packages.sh.tmpl,
    home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl
  </files>
  <behavior>
    - On Mac personal (darwin + personal=true): `chezmoi execute-template < home/.chezmoitemplates/brew` produces non-empty output with at least one `tap`, `brew`, AND `cask` line; rendered output contains zero `<no value>` strings.
    - On Mac work (darwin + personal=false): same shape, but the personal-overlay block expands to the work-overlay (else branch); zero `<no value>` strings.
    - Linux bug fix verified by inspection: the two former `tap "..."` mis-keyword sites at brew template lines ~70-78 (linux brews) and ~110-118 (linux casks) now emit `brew "..."` and `cask "..."` respectively. (Source-only fix; runtime verification waits for an actual Linux machine.)
    - `02-install-packages.sh.tmpl` first non-shebang line is the loud-fail guard `{{ if not (hasKey . "role") }}{{ fail "Role not set. Run: chezmoi init --apply" }}{{ end }}`.
    - `03-mas.sh.tmpl` body uses `.packages.overlays.personal.darwin.mas` (new shape); outer darwin/wsl gates removed (those go in .chezmoiignore in Task 3); `{{ if .personal }}` wraps the `range`.
  </behavior>
  <action>
**Sub-task 2A — `home/.chezmoitemplates/brew` rewrite:**

Read current `home/.chezmoitemplates/brew` (~123 lines). Rewrite consumer against new path structure per `<interfaces>` above. Preserve the existing 6-branch copy-paste structure for the overlay × OS section (DRY refactor is YAGNI per Q5).

**4 Linux-overlay bug fixes — fixed BY WRITING THE NEW TEMPLATE CORRECTLY:**

The 4 bugs are NOT separate edit operations against the old file. Since Task 2 rewrites the brew template wholesale (against the new `packages.roles.dev.*` + `packages.overlays.*` traversal), the fixes are simply: the new Linux-overlay loops emit the correct keywords (`brew {{ . | quote }}` for brews loops, `cask {{ . | quote }}` for casks loops). If the rewrite is correct, the bugs cannot survive.

Old-file audit-trail reference (NOT edit targets — line numbers are against the PRE-rewrite file): lines ~70-78 were inside a `{{ if eq .chezmoi.os "linux" }}` branch iterating over linux brews but emitted `tap {{ . | quote }}` (wrong keyword); lines ~110-118 were in the linux casks branch but emitted `tap` instead of `cask`. After the rewrite the new file's line numbers are unrelated — those locations no longer exist. Verification is by grepping the REWRITTEN file for correct keyword emission (see <verify> below), not by checking specific line ranges in either the old or new file.

Add `hasKey` defense at every overlay-path traversal: `{{ if hasKey .packages.overlays "personal" -}}` etc. — protects against runtime errors when an overlay is absent. (Q4 says we PRUNE empty placeholders; hasKey is the consumer-side defense.)

After rewrite, render and snapshot:
```
chezmoi execute-template < home/.chezmoitemplates/brew > /tmp/brew-render-darwin-personal.txt
```
Inspect manually — should look semantically equivalent to current brew output for the machine running the check. (Byte-equivalent snapshot is NOT a goal — the new shape changes some whitespace; semantic equivalence at the `tap NAME`/`brew NAME`/`cask NAME` line level is the goal.)

**Sub-task 2B — `02-install-packages.sh.tmpl` loud-fail guard:**

Read current `home/.chezmoiscripts/run_onchange_before_02-install-packages.sh.tmpl`. Insert these two lines IMMEDIATELY after the `#!/bin/bash` shebang and before the existing `{{ template "utils" . }}`:

```
{{ if not (hasKey . "role") }}{{ fail "Role not set. Run: chezmoi init --apply" }}{{ end }}
```

Rationale (Pitfall 9): if a pre-cutover machine somehow apply-runs this script without a `role` key in `.chezmoi.toml`, the template engine would otherwise silently produce `<no value>` in brew bundle output. The guard fails LOUD at template render time. Plan 03 documents the rationale in conventions.md.

**Sub-task 2C — `03-mas.sh.tmpl` consumer rewrite (NOT the /Applications/ guard — that's Plan 02):**

Read current `home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl`. Rewrite to:

```go-template
#!/bin/bash
{{ if .personal -}}
  {{ range $k, $v := .packages.overlays.personal.darwin.mas }}
/opt/homebrew/bin/mas install {{ dig "id" "" $v }}
  {{ end -}}
{{ end -}}
```

Remove the outer `darwin + not-wsl` gate from this file's body (those move to .chezmoiignore in Task 3 — file-presence gate guarantees darwin + not-wsl context when this script renders). KEEP the file shape minimal — Plan 02 will add `[[ ! -d "/Applications/${app_name}.app" ]]` around the install line.

**Pitfall 2 + Pitfall D awareness:** This rewrite changes the rendered content of `02-install-packages.sh.tmpl` and `03-mas.sh.tmpl`. Cutover script step 5 (`chezmoi init --apply`) WILL re-fire both `run_onchange_*` scripts because the content SHA changes — that's by design (CONTEXT.md + RESEARCH Pitfall 2 mitigation). On Mac personal/work this means `brew bundle` runs once during cutover and is a no-op (all packages already installed).

  </action>
  <verify>
    <automated>chezmoi execute-template --init --promptString name=t --promptString email=t@t --promptBool personal=true --promptChoice role=dev < home/.chezmoi.toml.tmpl > /tmp/cm-toml-render-$$ && chezmoi execute-template < home/.chezmoitemplates/brew > /tmp/brew-render-$$ && grep -c '<no value>' /tmp/brew-render-$$ | grep -q '^0$' && grep -qE '^(tap|brew|cask) ' /tmp/brew-render-$$ && grep -qE 'hasKey .*"role".*fail.*Role not set' home/.chezmoiscripts/run_onchange_before_02-install-packages.sh.tmpl && grep -q 'packages.overlays.personal.darwin.mas' home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl && ! grep -qE '\.chezmoi\.os.*darwin' home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl ; rm -f /tmp/cm-toml-render-$$ /tmp/brew-render-$$</automated>
  </verify>
  <done>
    Brew template renders against new packages.yaml shape with zero `<no value>`, emits valid `tap/brew/cask` lines. Loud-fail guard present in 02-install-packages. 03-mas consumer rewritten to new shape with outer OS gate removed (moved to .chezmoiignore in Task 3). Maps to TAX-05 consumer + Pitfall 9 defense + 4 inline Linux bug fixes.
  </done>
</task>

<task type="auto">
  <name>Task 3: Template .chezmoiignore (TAX-06) + re-stage flameshot config (SS-03)</name>
  <files>
    home/.chezmoiignore,
    home/private_dot_config/flameshot/flameshot.ini
  </files>
  <action>
**Sub-task 3A — `.chezmoiignore` templating (TAX-06):**

Replace the current 1-line `home/.chezmoiignore` (just `.oh-my-zsh/cache/**`) with the locked shape from `<interfaces>` above (4 gates + the pre-existing oh-my-zsh cache line):

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

Style: conditional-include grouped by gate (per CONTEXT.md). File-presence only (per goal amendment #3) — template-internal runtime logic stays in templates.

Verify file is templated (contains `{{`) and references `.chezmoi.os`, `.role`, `.personal` (actually only `.role`, `.wsl`, `.chezmoi.os` in this version — `.personal` not gated at file level in Phase 0; that's the brew template's runtime concern).

**Sub-task 3B — Re-stage flameshot config (SS-03):**

Read `.planning/phases/00.5-audit-documentation/00.5-04-flameshot-baseline.md`. It contains the verbatim flameshot.ini content + SHA + mode captured before Phase 0.5 Plan 04 deletion (Plan 04 deleted from Mac destinations + entryState; SS-03 says preserve in source for future Linux laptop).

Recreate `home/private_dot_config/flameshot/flameshot.ini` from the baseline content verbatim. Match mode (likely 0644) and content SHA exactly. Verify SHA: `shasum -a 256 home/private_dot_config/flameshot/flameshot.ini` matches the baseline's recorded SHA.

This file is gated by .chezmoiignore (Sub-task 3A) to `os=linux AND not wsl AND role=dev`. On both active Macs (darwin), this file is in source but ignored at destination — dormant until a real Linux laptop materializes (Phase 3 territory).

**Verification:** On darwin (i.e., Mac personal / Mac work), after applying this .chezmoiignore + adding the source flameshot file: `chezmoi managed | grep flameshot` returns empty (file is in source but .chezmoiignore-gated out). On a hypothetical linux+role=dev+not-wsl machine, the file would be managed.
  </action>
  <verify>
    <automated>grep -q '{{' home/.chezmoiignore && grep -qE '\.chezmoi\.os' home/.chezmoiignore && grep -qE '\.role' home/.chezmoiignore && grep -qE 'aerospace' home/.chezmoiignore && grep -qE 'flameshot' home/.chezmoiignore && grep -q '.oh-my-zsh/cache/' home/.chezmoiignore && test -f home/private_dot_config/flameshot/flameshot.ini && test "$(chezmoi managed 2>/dev/null | grep -c flameshot)" = "0"</automated>
  </verify>
  <done>
    .chezmoiignore is templated, contains 5 gates (oh-my-zsh cache, 3 darwin-only entries, 1 flameshot entry); flameshot.ini restored verbatim from 0.5 baseline; chezmoi managed shows flameshot gated out on darwin. Maps to TAX-06 + SS-03.
  </done>
</task>

<task type="auto">
  <name>Task 4: Tear down home/exact_bin/ → home/private_dot_local/bin/ (resolves 0.5 follow-up #9)</name>
  <files>
    home/private_dot_local/bin/executable_dot.tmpl,
    home/private_dot_local/bin/executable_git-bare-clone,
    home/private_dot_local/bin/executable_git-wtf,
    home/private_dot_local/bin/executable_tmux-cht.sh,
    home/private_dot_local/bin/executable_tmux-sessionizer
  </files>
  <action>
**Move (git mv where possible to preserve history):** the 5 files in `home/exact_bin/` to `home/private_dot_local/bin/`. Filenames keep their `executable_` prefix so chezmoi preserves the +x mode.

```
git mv home/exact_bin/executable_dot.tmpl          home/private_dot_local/bin/executable_dot.tmpl
git mv home/exact_bin/executable_git-bare-clone    home/private_dot_local/bin/executable_git-bare-clone
git mv home/exact_bin/executable_git-wtf           home/private_dot_local/bin/executable_git-wtf
git mv home/exact_bin/executable_tmux-cht.sh       home/private_dot_local/bin/executable_tmux-cht.sh
git mv home/exact_bin/executable_tmux-sessionizer  home/private_dot_local/bin/executable_tmux-sessionizer
```

After the moves, `home/exact_bin/` directory is empty — `git mv` will leave it as an untracked empty dir (or git removes it automatically). Verify it's gone: `test ! -d home/exact_bin`. If the directory remains (untracked empty dir), `rmdir home/exact_bin`.

**Why `private_dot_local/bin/`:** Per 0-RESEARCH.md State of the Art row 2 + CONTEXT.md exact_bin Teardown decision — decouples personal-utility tooling from the strict `exact_` chezmoi directive (which was forcing `~/bin/` to ONLY contain chezmoi-source-managed files, breaking Mac work's `start-aws-mcp.sh` Bluebeam tooling — Phase 0.5 Plan 06 finding). The 5 utilities are personal-identity (keep chezmoi-managed); `~/.local/bin/` is already first on PATH via mise, so both tmux scripts continue resolving by bare command name (`tmux-sessionizer`, `tmux-cht.sh`).

**Pitfall 11 awareness:** None of these 5 files are `run_once_` scripts (per Phase 0.5 state-preview captures — they're entryState files, no scriptState entries). Moving them changes their entryState keys from `/Users/jteague/bin/<entry>` to `/Users/jteague/.local/bin/<entry>` — cutover script step 6 handles the entryState cleanup (`rm -rf ~/bin/` + 5× `chezmoi state delete --bucket=entryState --key /Users/jteague/bin/<entry>`).

**Side effect at runtime (NOT executor's job):** On per-machine cutover, after `chezmoi apply`, ~/.local/bin/ gets the 5 utilities (chezmoi creates the directory because of `private_dot_local/`). `~/bin/` files persist (chezmoi source-delete doesn't auto-remove destinations — Pitfall C). Cutover script step 6 explicitly `rm -rf ~/bin/`.
  </action>
  <verify>
    <automated>test ! -d home/exact_bin && test -f home/private_dot_local/bin/executable_dot.tmpl && test -f home/private_dot_local/bin/executable_git-bare-clone && test -f home/private_dot_local/bin/executable_git-wtf && test -f home/private_dot_local/bin/executable_tmux-cht.sh && test -f home/private_dot_local/bin/executable_tmux-sessionizer</automated>
  </verify>
  <done>
    home/exact_bin/ deleted; 5 utilities live at home/private_dot_local/bin/ with executable_ prefixes preserved; chezmoi recognizes them as +x via the prefix convention. Maps to 0.5 follow-up #9 absorption per disposition table.
  </done>
</task>

<task type="auto">
  <name>Task 5: Commit cutover-phase-0.sh artifact + run Wave 0 harness as gate</name>
  <files>
    .planning/phases/0-structural-refactor/cutover-phase-0.sh
  </files>
  <action>
**Sub-task 5A — Write cutover-phase-0.sh:**

Write `.planning/phases/0-structural-refactor/cutover-phase-0.sh` using the verbatim 8-step design from `0-RESEARCH.md` Pattern 4 § "Example structure" (lines ~308-363). Use `#!/usr/bin/env bash`; `set -euo pipefail`; print snapshot path FIRST before any mutation; preflight `chezmoi --version` ≥ 2.70.4 (die loud if not); targeted snapshot of 5 paths + `~/bin/`; Mac-work autodetect via `grep -q NODE_EXTRA_CA_CERTS ~/.zshrc` (append-to-localrc + sed-delete); `chezmoi init --apply` (interactive role prompt); exact_bin teardown (`rm -rf ~/bin/` + 5× `chezmoi state delete --bucket=entryState --key /Users/jteague/bin/<entry> || true` — SPACE-SEPARATED `--key /path` form per follow-up #7); verify SC #4 via `chezmoi diff -x externals` non-empty → fail; verify SC #3 via `chezmoi apply --dry-run --verbose 2>&1 | grep "no value"` non-empty → fail; print success + snapshot retain message.

**No auto-rollback** per CLAUDE.md "manual work = collaborative mode" + RESEARCH alternatives-considered row 3.

**Make executable:** `chmod +x .planning/phases/0-structural-refactor/cutover-phase-0.sh`.

**This script is an ARTIFACT — executor does NOT run it.** Running it is operator-driven, per-machine, post-merge, in collaborative mode (CLAUDE.md). The script is what the human invokes on Mac personal then Mac work after the phase-0 branch is merged.

**Sub-task 5B — Wave 0 gate run:**

Now that all source-tree changes from Tasks 1-4 are in place, the Wave 0 harness should pass. Run:
```
bash .planning/phases/0-structural-refactor/checks/quick.sh
```
Must exit 0 with all PASS assertions. If any FAIL, fix the underlying source issue and re-run — do NOT mutate the harness to pass (Pitfall: verify-by-loosening defeats the purpose).

Then run the full suite without the operator-driven diff gate:
```
bash .planning/phases/0-structural-refactor/checks/full.sh --no-diff-gate
```
Must exit 0.

**Why this is the last in-tree task:** The harness is the Phase 0 acceptance gate for the structural commit. Plans 02 and 03 layer on top of a passing harness state.

**Sub-task 5C — Pre-merge template-render fixture pass (Pitfall 9 belt-and-suspenders):**

Run the three fixture scenarios manually to confirm zero `<no value>` in any rendered output:
```
for f in .planning/phases/0-structural-refactor/checks/fixtures/role-dev-*.env; do
  echo "=== $f ==="
  set -a; source "$f"; set +a
  chezmoi execute-template --init \
    --promptString name="${PROMPT_NAME}" \
    --promptString email="${PROMPT_EMAIL}" \
    --promptBool personal="${PROMPT_PERSONAL}" \
    --promptChoice role="${PROMPT_ROLE}" \
    < home/.chezmoi.toml.tmpl | grep -c '<no value>'   # must be 0
done
```

All three must report `0`. (Note: OS-axis variance — the actual `.chezmoi.os` value depends on the machine running the check. Cross-OS fixture rendering is operator-driven at cutover time, NOT in-plan.)
  </action>
  <verify>
    <automated>test -x .planning/phases/0-structural-refactor/cutover-phase-0.sh && bash -n .planning/phases/0-structural-refactor/cutover-phase-0.sh && grep -q "set -euo pipefail" .planning/phases/0-structural-refactor/cutover-phase-0.sh && grep -q "chezmoi state delete --bucket=entryState --key /Users/jteague/bin" .planning/phases/0-structural-refactor/cutover-phase-0.sh && ! grep -q "key=/Users" .planning/phases/0-structural-refactor/cutover-phase-0.sh && bash .planning/phases/0-structural-refactor/checks/quick.sh && bash .planning/phases/0-structural-refactor/checks/full.sh --no-diff-gate</automated>
  </verify>
  <done>
    cutover-phase-0.sh exists, is executable, contains all 8 locked steps, uses space-separated `--key /path` form (NOT `--key=/path` — follow-up #7), has set -euo pipefail. Wave 0 quick.sh and full.sh --no-diff-gate both exit 0 on the source tree as left by Tasks 1-4. Maps to TAX-07 (merge-gate enablement; actual gate run is operator-driven per machine).
  </done>
</task>

</tasks>

<verification>
**Per-task automated verify commands above map to the 0-VALIDATION.md "Per-Task Verification Map" — sampling rate is "after every task commit" per the validation contract. After Task 5 commit, the full suite (`bash .planning/phases/0-structural-refactor/checks/full.sh --no-diff-gate`) should be GREEN.**

**Manual-only verifications deferred to operator-driven cutover** (per 0-VALIDATION.md "Manual-Only Verifications" + CLAUDE.md):
- Mac personal: `bash .planning/phases/0-structural-refactor/cutover-phase-0.sh`, answer `dev` to role prompt, verify `chezmoi diff -x externals` empty + `chezmoi apply --dry-run --verbose | grep "no value"` empty
- Mac work: same, plus verify NODE_EXTRA_CA_CERTS migrated from `~/.zshrc` to `~/.localrc` (step 4 autodetect)
- chezmoi version on Mac work must be ≥ 2.70.4 BEFORE cutover (cutover step 2 preflight refuses to run otherwise; operator handles `brew upgrade chezmoi` separately)

**Goal-amendment compliance checks:**
- [ ] `home/scripts/generate-gpg-key.sh` still exists (Phase 0 must not delete; defer to Phase 1) — `test -f home/scripts/generate-gpg-key.sh` returns 0
- [ ] `home/modify_dot_gitconfig.local` still references `home/scripts/generate-gpg-key.sh` (load-bearing) — `grep -q generate-gpg-key.sh home/modify_dot_gitconfig.local` returns 0
- [ ] `.chezmoiignore` is FILE PRESENCE only (no template-internal runtime logic) — manual review of the 5 gates
</verification>

<success_criteria>
1. All 6 tasks complete (Task 0 harness + Tasks 1-5 source-tree changes + cutover artifact).
2. `bash .planning/phases/0-structural-refactor/checks/full.sh --no-diff-gate` exits 0.
3. `chezmoi execute-template --init --promptString name=t --promptString email=t@t --promptBool personal=true --promptChoice role=dev < home/.chezmoi.toml.tmpl` includes `role = "dev"` and zero `<no value>`.
4. `home/exact_bin/` deleted; 5 utilities at `home/private_dot_local/bin/` with `executable_` prefixes preserved.
5. `home/private_dot_config/flameshot/flameshot.ini` restored verbatim from 0.5 baseline.
6. `home/scripts/generate-gpg-key.sh` UNTOUCHED (goal amendment #1).
7. `home/.chezmoiignore` is templated and references `.chezmoi.os`, `.role`, `.wsl` for file-presence gating.
8. Single git commit titled `feat(phase-0): structural taxonomy refactor (role × personal × os × wsl)` containing all of the above changes plus the cutover-phase-0.sh artifact.
9. Plan SUMMARY written: `.planning/phases/0-structural-refactor/0-01-SUMMARY.md`.
</success_criteria>

<output>
After completion, create `.planning/phases/0-structural-refactor/0-01-SUMMARY.md` documenting:
- Tasks completed (with file counts, lines changed)
- Wave 0 harness final pass count
- Brew template render delta (semantic diff vs prior version on this machine)
- Any decisions made during execution (e.g., how empty placeholder pruning was handled if the source file had ambiguous shape)
- Hand-off pointer to Plan 02 (mas guard) and operator-driven cutover ritual

Git commit message:
```
feat(phase-0): structural taxonomy refactor (role × personal × os × wsl)

- Add role promptChoiceOnce (dev|gaming|lite, default dev) to .chezmoi.toml.tmpl
- Restructure packages.yaml: packages.roles.<role>.<os> + packages.overlays.{personal,work}.<os>
- Template .chezmoiignore: 4 gates (aerospace, flameshot, darwin-configure, 03-mas) + preserved oh-my-zsh cache
- Rewrite brew partial against new shape; fix 4 latent Linux-overlay keyword bugs (lines 70-78, 110-118)
- Add hasKey "role" loud-fail guard to 02-install-packages (Pitfall 9 defense)
- Rewrite 03-mas consumer against new shape (mas /Applications/ guard lands in Plan 02)
- Move home/exact_bin/ → home/private_dot_local/bin/ (5 utilities; resolves 0.5 follow-up #9)
- Restore home/private_dot_config/flameshot/flameshot.ini from 0.5 baseline (SS-03)
- Install Wave 0 harness: checks/{lib,quick,full}.sh + 3 fixtures
- Commit cutover-phase-0.sh operational artifact (operator-driven, not executor-run)

generate-gpg-key.sh UNTOUCHED — goal amendment #1 defers deletion to Phase 1.

Requirements: TAX-01, TAX-02, TAX-03, TAX-04, TAX-05, TAX-06, TAX-07, SS-03
```
</output>
