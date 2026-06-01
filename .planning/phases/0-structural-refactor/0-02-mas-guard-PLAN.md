---
phase: 0-structural-refactor
plan: 02
type: execute
wave: 2
depends_on: ["0-01"]
files_modified:
  - home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl
autonomous: true
requirements: [TAX-05]
must_haves:
  truths:
    - "`03-mas.sh.tmpl` wraps every `mas install <id>` call with a `[[ ! -d \"/Applications/${app_name}.app\" ]]` pre-check"
    - "App name resolution uses `dig \"name\" \"\" $v` from the packages.yaml mas dict (each entry is `{name: ..., id: ...}`)"
    - "When the app IS already present at /Applications/<App>.app, the script echoes a skip message instead of invoking `mas install`"
    - "The script body is still wrapped by `{{ if .personal }}` (file-presence darwin+not-wsl gate stays in .chezmoiignore from Plan 01)"
    - "Rendered output on Mac personal: every mas-managed app (e.g., Brother iPrint id 1193539993) renders a guard-then-install pair; no bare `mas install` lines"
  artifacts:
    - path: "home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl"
      provides: "mas install guarded by /Applications/<App>.app presence check (resolves 0.5 follow-up #4 + Pitfall mas-list-Apple-ID-invisibility)"
      contains: "/Applications/"
  key_links:
    - from: "home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl"
      to: "home/.chezmoidata/packages.yaml (.packages.overlays.personal.darwin.mas)"
      via: "{{ range $k, $v := .packages.overlays.personal.darwin.mas }} iteration over {name,id} dicts"
      pattern: ".packages.overlays.personal.darwin.mas"
    - from: "home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl"
      to: "/Applications/${app_name}.app filesystem check"
      via: "[[ ! -d ... ]] bash test as `mas install` precondition"
      pattern: "/Applications/"
---

<objective>
Add a `/Applications/<App>.app` presence pre-check around each `mas install` invocation in `03-mas.sh.tmpl`. Resolves Phase 0.5 follow-up #4 + Pitfall mas-list-Apple-ID-invisibility (Brother iPrint case from Plan 06 Task 1: app installed under a different Apple ID is invisible to `mas list` but visible to `/Applications/`; `mas install` against it triggers Spotlight re-index + sudo prompt + non-TTY failure).

Purpose: Separate commit from structural so the merge-gate `chezmoi diff -x externals` reads against a pure structural diff. The guard introduces user-facing behavior change (skip messages instead of failed installs) and warrants its own audit line.

Output: 1 git commit titled `fix(phase-0): mas install /Applications/<App>.app guard`. Touches a single file. Wave 2 (depends on Plan 01's structural cut — needs the new `packages.overlays.personal.darwin.mas` path shape).
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
@.planning/phases/0-structural-refactor/0-01-SUMMARY.md
@home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl
@home/.chezmoidata/packages.yaml

<interfaces>
<!-- Locked target shape from 0-RESEARCH.md Code Examples § "Mas guard (plan 02 commit)". -->

After this plan, `home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl` reads:

```go-template
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

Notes:
- Outer `darwin + not-wsl` is enforced by `.chezmoiignore` from Plan 01 (file-presence gate); body only needs `{{ if .personal }}`.
- `dig "name" "" $v` returns the `name` key from each mas-dict entry, empty string if missing (defensive). Same for `id`.
- `app_name` is double-quoted in the bash test to handle apps with spaces (e.g., "Brother iPrint" — though /Applications uses the .app bundle name, which for Brother iPrint is `Brother iPrint&Scan.app` — depends on what the YAML records).
- The expanded form changes from 1 line per mas entry to ~5 lines per mas entry; the script grows from ~12 to ~25 lines.

Packages.yaml mas dict shape (locked from current packages.yaml structure post-Plan-01 restructure):
```yaml
packages:
  overlays:
    personal:
      darwin:
        mas:
          "1193539993":
            name: "Brother iPrint&Scan"     # OR whatever name is in source today; copy verbatim
            id: 1193539993
          # ... other mas entries
```
Verify the actual keys in `packages.yaml` after Plan 01 — `name` key MUST exist for each mas entry, else the `dig` falls back to "" and the bash test becomes `[ ! -d "/Applications/.app" ]` (always true → no skip → silent regression). Plan 01 Task 1 (Sub-task 1B) owns the validation/addition of missing `name:` keys. Plan 02 only ASSERTS this invariant as a read-only precondition (see Sub-task 1A) — if the assertion fails, Plan 02 HALTS and surfaces the gap. Plan 02 must not mutate `packages.yaml`.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add /Applications/<App>.app guard around mas install</name>
  <files>
    home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl
  </files>
  <behavior>
    - Rendered output on a darwin+personal machine: for EACH entry under `packages.overlays.personal.darwin.mas`, the script renders an `if [ ! -d "/Applications/${app_name}.app" ]; then mas install <id>; else echo "Skipping ..."; fi` block. No bare `mas install` lines remain.
    - `chezmoi execute-template --init --promptString name=t --promptString email=t@t --promptBool personal=true --promptChoice role=dev < home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl 2>/dev/null` (on a darwin machine) emits at least one `/Applications/` substring AND at least one `mas install` invocation AND zero `<no value>` strings.
    - `grep -c '/Applications/' home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl` returns at least 1.
    - `grep -c 'mas install' home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl` returns 1 (a single literal `mas install` call, parameterized).
    - The file body remains wrapped by `{{ if .personal }}` (outer darwin+not-wsl gating is in .chezmoiignore from Plan 01 — do not re-add).
  </behavior>
  <action>
**Sub-task 1A — Pre-flight: ASSERT packages.yaml mas entries have `name:` and `id:` keys (read-only precondition).**

Plan 01 Task 1 (Sub-task 1B) is responsible for ensuring every entry under `packages.overlays.personal.darwin.mas` has both `name:` and `id:` keys. Plan 02 only ASSERTS this precondition — it does NOT mutate `packages.yaml`.

Run the precondition check:
```bash
ruby -r yaml -e '
  h = YAML.load_file("home/.chezmoidata/packages.yaml")
  mas = h.dig("packages","overlays","personal","darwin","mas") || {}
  mas.each do |k,v|
    raise "mas entry #{k} missing name (Plan 01 Task 1 invariant violated)" unless v.is_a?(Hash) && v["name"] && !v["name"].to_s.empty?
    raise "mas entry #{k} missing id (Plan 01 Task 1 invariant violated)"   unless v["id"]
  end
  puts "mas name/id precondition OK"
'
```

If this assertion FAILS, HALT immediately. The failure means Plan 01 Task 1's mas name-key validation step did not run or did not address all entries. Do NOT patch packages.yaml from inside Plan 02 — Plan 02 is locked to a single file (`home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl`) per the merge-gate-purity constraint (CONTEXT.md three-commit lock). The executor must surface the gap and route it back to Plan 01.

This is a behavior-revision per checker warning #2: contingent `packages.yaml` mutation has been hoisted to Plan 01 Task 1. Plan 02 stays truly single-file.

**Sub-task 1B — Rewrite `03-mas.sh.tmpl`:**

Read current `home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl` (which Plan 01 already rewrote against the new shape but WITHOUT the guard). Replace the body with the locked shape from `<interfaces>` above:

```go-template
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

**Quoting note:** `{{ dig "name" "" $v | quote }}` produces a Go-template-quoted string — e.g., `app_name="Brother iPrint&Scan"`. The double-quote in the bash test (`"/Applications/${app_name}.app"`) handles spaces/ampersands. Test by rendering the script and inspecting one entry's output manually.

**Sub-task 1C — Render + smoke test:**

```bash
chezmoi execute-template --init \
  --promptString name=t \
  --promptString email=t@t \
  --promptBool personal=true \
  --promptChoice role=dev \
  < home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl > /tmp/mas-render-$$
cat /tmp/mas-render-$$
grep -c '<no value>' /tmp/mas-render-$$ | grep -q '^0$'
grep -c '/Applications/' /tmp/mas-render-$$ | grep -qvE '^0$'
grep -c 'mas install' /tmp/mas-render-$$ | grep -qvE '^0$'
rm /tmp/mas-render-$$
```

Manually inspect one rendered entry — bash syntax must be valid (no unmatched quotes; `${app_name}` expansion correct).

**Wave 0 harness extension (optional but recommended):** add an assertion to `quick.sh` (Plan 01's harness file):
```
assert_grep '/Applications/' home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl
```
This isn't strictly required (the verify command below covers it) but keeps the harness comprehensive for any future Phase 0 follow-on work. If adding, do it as a small Edit to the existing checks/quick.sh — do not rewrite the harness.

**Pitfall 2 awareness:** This task changes `03-mas.sh.tmpl` content SHA → cutover script step 5 (`chezmoi init --apply`) WILL re-fire `run_onchange_before_03-mas` on next apply. On Mac personal/work this is the expected behavior — the mas install loop runs once and skips every entry (Brother iPrint et al. already present at `/Applications/`). Document this expected re-fire in the plan SUMMARY.
  </action>
  <verify>
    <automated>grep -qE '/Applications/' home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl && grep -qE 'mas install' home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl && grep -qE 'Skipping mas install' home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl && grep -qE 'dig "name"' home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl && grep -qE 'dig "id"' home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl && grep -qE '{{ if \.personal' home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl && ! grep -qE '\.chezmoi\.os.*darwin' home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl && chezmoi execute-template --init --promptString name=t --promptString email=t@t --promptBool personal=true --promptChoice role=dev < home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl 2>/dev/null | grep -c '<no value>' | grep -q '^0$' && bash .planning/phases/0-structural-refactor/checks/full.sh --no-diff-gate</automated>
  </verify>
  <done>
    `03-mas.sh.tmpl` contains the /Applications/<App>.app pre-check around mas install; renders with zero `<no value>` on darwin+personal=true; outer darwin/wsl gates absent (in .chezmoiignore from Plan 01); Wave 0 full.sh --no-diff-gate still green. Maps to 0.5 follow-up #4 + #3 (practical fix).
  </done>
</task>

</tasks>

<verification>
**Sampling rate per 0-VALIDATION.md:** After Task 1 commit, run `bash .planning/phases/0-structural-refactor/checks/quick.sh` (must stay green from Plan 01 baseline) AND the per-task verify command above.

**Manual-only verifications deferred to operator-driven cutover:**
- Mac personal: After cutover, expect `03-mas.sh` re-fires once due to content SHA change; every mas entry should `echo "Skipping mas install: <App>.app already present"` (no actual `mas install` invocations, no sudo prompt, no Spotlight re-index). Capture in cutover log.
- Mac work: same. Note that Mac work is not `personal=true`, so the `{{ if .personal }}` block evaluates to nothing — the rendered script body is effectively empty (no mas calls regardless of /Applications/ state). This is correct: work machines don't have an `overlays.work.darwin.mas` block (per CONTEXT.md packages-restructure — work overlay has no mas key).
- Brother iPrint specifically (Pitfall mas-list-Apple-ID-invisibility origin case from Plan 06 Task 1): rendered script must show `Brother iPrint&Scan.app` (or whatever the source name resolves to) — verify on Mac personal at cutover time.
</verification>

<success_criteria>
1. `03-mas.sh.tmpl` contains `/Applications/` pre-check around `mas install` for every mas entry.
2. `chezmoi execute-template ... < 03-mas.sh.tmpl` renders zero `<no value>` strings.
3. Wave 0 `bash full.sh --no-diff-gate` stays green.
4. Plan 01's structural diff remains pure (this commit is separate — `git log --oneline` shows two distinct commits: structural then mas-guard).
5. Plan SUMMARY written: `.planning/phases/0-structural-refactor/0-02-SUMMARY.md`.
</success_criteria>

<output>
After completion, create `.planning/phases/0-structural-refactor/0-02-SUMMARY.md` documenting:
- The before/after diff of `03-mas.sh.tmpl` (line counts: ~12 → ~25)
- Confirmation that Sub-task 1A's precondition assertion passed on the first run (i.e., Plan 01 Task 1 Sub-task 1B correctly populated all `name:` keys). If the assertion required a re-route to Plan 01, document that here.
- One rendered example block (e.g., Brother iPrint) showing the expected runtime behavior
- Note about expected re-fire on cutover (Pitfall 2 — content SHA change triggers run_onchange re-fire; intentional)
- Hand-off pointer to Plan 03 (docs)

Git commit message:
```
fix(phase-0): mas install /Applications/<App>.app guard

Wraps every `mas install <id>` in 03-mas.sh.tmpl with a [[ ! -d
/Applications/<App>.app ]] pre-check. Skip-with-echo when present;
mas install only when absent.

Resolves Phase 0.5 follow-up #4 + Pitfall mas-list-Apple-ID-invisibility
(Brother iPrint case Plan 06 Task 1: app installed under a different Apple
ID is invisible to `mas list` but visible to /Applications/; bare `mas
install` triggered Spotlight re-index + sudo prompt + non-TTY failure).

Outer darwin+not-wsl gate stays in .chezmoiignore (Plan 01). Body
guarded only by `{{ if .personal }}`.

Requirements: TAX-05 (consumer)
```
</output>
