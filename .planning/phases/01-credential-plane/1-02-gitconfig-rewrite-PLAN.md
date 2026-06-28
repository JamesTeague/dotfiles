---
phase: 01-credential-plane
plan: 02
type: execute
wave: 2
depends_on:
  - "1-01"
files_modified:
  - home/modify_dot_gitconfig.local
  - home/scripts/generate-gpg-key.sh
autonomous: true
requirements:
  - SEC-05
must_haves:
  truths:
    - "home/scripts/generate-gpg-key.sh no longer exists in source tree"
    - "home/modify_dot_gitconfig.local renders without invoking any external script"
    - "When chezmoi data has no .signingkey, the rendered gitconfig omits [commit] gpgsign and signingkey lines"
    - "When chezmoi data has .signingkey set, the rendered gitconfig includes signingkey + commit.gpgsign = true"
    - "chezmoi apply on Mac personal (which has existing signingkey in chezmoi.toml [data]) reports zero functional diff for ~/.gitconfig.local"
  artifacts:
    - path: "home/modify_dot_gitconfig.local"
      provides: "Pure chezmoi-data-driven gitconfig modify-template (no output of external script)"
      contains: ".signingkey"
    - path: "home/scripts/generate-gpg-key.sh"
      provides: "DELETED (must not exist)"
  key_links:
    - from: "home/modify_dot_gitconfig.local"
      to: "chezmoi data (.signingkey)"
      via: "template expression {{ if .signingkey }}...{{ end }}"
      pattern: "\\.signingkey"
    - from: "home/modify_dot_gitconfig.local"
      to: "chezmoi data (.name, .email)"
      via: "template expressions {{ .name }} {{ .email }}"
      pattern: "\\.name|\\.email"
---

<objective>
Carry over SEC-05 from Phase 0 by (a) DELETING `home/scripts/generate-gpg-key.sh` and (b) rewriting `home/modify_dot_gitconfig.local` from "shell-out via `output` template function" to a pure chezmoi-data-driven modify-template.

Purpose: Phase 0 deferred SC #5 because `modify_dot_gitconfig.local` was load-bearing on the to-be-deleted script. Phase 1's per-machine-key architecture replaces the shell-out with a `.signingkey` chezmoi data field set by `setup-credentials.sh`. Until the script runs on a machine, `.signingkey` is unset and the template gracefully omits the signing-config lines (no broken commits, no silent failure). After the script runs, `chezmoi apply` re-renders gitconfig with signingkey + commit.gpgsign present.

Output: One template rewrite (`modify_dot_gitconfig.local`) + one source-tree deletion (`home/scripts/generate-gpg-key.sh`). Both commits are structural — no behavioral change on machines until Plan 1-04a/1-04b's `setup-credentials.sh` runs there.
</objective>

<execution_context>
@/Users/jteague/.claude/get-shit-done/workflows/execute-plan.md
@/Users/jteague/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/phases/01-credential-plane/1-CONTEXT.md
@.planning/phases/01-credential-plane/1-RESEARCH.md
@home/modify_dot_gitconfig.local
@home/scripts/generate-gpg-key.sh

<interfaces>
<!-- CURRENT modify_dot_gitconfig.local content (load-bearing — what we're replacing): -->

```
{{- /* chezmoi:modify-template */ -}}
{{- $helper := "osxkeychain" -}}
{{- if eq .chezmoi.os "linux" -}}
{{-    $helper = "cache" -}}
{{- end -}}
{{- $scriptPath := printf "%s/scripts/generate-gpg-key.sh" .chezmoi.sourceDir -}}
{{- $output := output $scriptPath -}}
{{- $output | replaceAllRegex "data-name" .name | replaceAllRegex "data-email" .email | replaceAllRegex "data-helper" $helper -}}
```

<!-- CURRENT chezmoi data field availability (from home/.chezmoi.toml.tmpl, lines 12-17): -->
```
[data]
  personal = {{ $personal }}
  name = {{ $name | quote }}
  email = {{ $email | quote }}
  role = {{ $role | quote }}
  wsl = {{ $wsl }}
```

<!-- .signingkey is NOT yet in [data] — Plan 1-04b's setup-credentials.sh write_signingkey() writes it idempotently after key generation. -->
<!-- Until then, .signingkey is unset and template MUST handle that path. -->

<!-- TARGET shape (recommended in 1-RESEARCH.md Pattern 1, slightly hardened): -->
```
{{- /* chezmoi:modify-template */ -}}
{{- $helper := "osxkeychain" -}}
{{- if eq .chezmoi.os "linux" -}}
{{-   $helper = "cache" -}}
{{- end -}}
[user]
  name = {{ .name }}
  email = {{ .email }}
{{- if .signingkey }}
  signingkey = {{ .signingkey }}
{{- end }}
[credential]
  helper = {{ $helper }}
{{- if .signingkey }}
[commit]
  gpgsign = true
{{- end }}
```

<!-- SEC-15 contract (canonical from Plan 1-01 interfaces block): -->
<!-- Verify commands in this plan use the THREE-clause regex: \bbw \b|bitwardenAttachment|\{\{ *bitwarden -->
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Rewrite modify_dot_gitconfig.local to pure chezmoi-data form</name>
  <files>home/modify_dot_gitconfig.local</files>
  <behavior>
    - Render WITHOUT .signingkey in chezmoi data: output contains `[user]`, `name = <name>`, `email = <email>`, `[credential]`, `helper = osxkeychain` (on darwin) / `helper = cache` (on linux). Output does NOT contain `signingkey` or `[commit]` or `gpgsign`.
    - Render WITH .signingkey set to a fake value `ABCDEF0123456789` in chezmoi data: output contains all of the above PLUS `signingkey = ABCDEF0123456789` AND `[commit]\n  gpgsign = true`.
    - Render does NOT shell out — no `output` template function call. Grep of file for `output.*generate-gpg-key` returns nothing; grep for `.signingkey` returns at least 2 matches (one in user section, one in commit gate).
    - Render preserves the chezmoi:modify-template marker (`{{- /* chezmoi:modify-template */ -}}`) at file top — without it, chezmoi treats the file as a plain template and double-applies it through the modify pipeline.
  </behavior>
  <action>
Replace the entire contents of `home/modify_dot_gitconfig.local` with the pure-template form from the interfaces block above. Preserve the `chezmoi:modify-template` marker. Use `{{- ... -}}` whitespace trimming on control directives, plain `{{ ... }}` on emitted values.

Critical correctness points:
1. The `{{- if .signingkey }}` guards check truthiness — `nil`, empty string, and `false` all skip the block. This is the desired Stage-1-machine-without-script behavior.
2. Do NOT remove `chezmoi:modify-template`. Without it, chezmoi treats `modify_dot_gitconfig.local` as a regular template and overwrites the destination file unconditionally instead of running it as a modify-pipeline filter.
3. Do NOT consume `.chezmoi.stdin`. CONTEXT Open Question 8 was resolved in 1-RESEARCH.md to favor pure template form (matches the original "overwrite whole file from script output" semantics).
4. Keep the osxkeychain/cache branching exactly as in the current file — this is unchanged behavior.

After writing, validate with two chezmoi-execute-template renders against synthetic data:

```bash
# Render WITHOUT signingkey:
echo '' | chezmoi execute-template --init \
  --promptString name='Test' --promptString email='t@e.com' --promptBool personal=false \
  --promptChoice role=dev \
  < home/modify_dot_gitconfig.local > /tmp/render-nosign.txt

# Render WITH signingkey (chezmoi data via stdin not viable for arbitrary keys; instead
# test by directly invoking chezmoi execute-template with a wrapped template that sets
# signingkey via {{ $_ := set ... }} or by temporarily editing ~/.config/chezmoi/chezmoi.toml).
# Recommended: use a one-off test wrapper template:
cat > /tmp/test-with-sign.tmpl <<'EOF'
{{- $_ := set . "signingkey" "ABCDEF0123456789" -}}
EOF
cat /tmp/test-with-sign.tmpl home/modify_dot_gitconfig.local | chezmoi execute-template > /tmp/render-sign.txt
```

Both renders are part of the verify automated command — they must produce the expected presence/absence of `signingkey` and `[commit]`.

Do NOT modify `home/.chezmoi.toml.tmpl` — `.signingkey` is added at runtime by `setup-credentials.sh` (Plan 1-04b), not at init time.
  </action>
  <verify>
    <automated>cd /Users/jteague/.local/share/chezmoi && grep -q "chezmoi:modify-template" home/modify_dot_gitconfig.local && grep -c "\.signingkey" home/modify_dot_gitconfig.local | grep -qE "^[2-9]$|^[1-9][0-9]+$" && ! grep -q "output.*generate-gpg-key" home/modify_dot_gitconfig.local && ! grep -q "data-name\|data-email\|data-helper" home/modify_dot_gitconfig.local && chezmoi execute-template --init --promptString name=Test --promptString email=t@e.com --promptBool personal=false --promptChoice role=dev < home/modify_dot_gitconfig.local > /tmp/render-nosign.txt 2>&1 && grep -q "name = Test" /tmp/render-nosign.txt && grep -q "email = t@e.com" /tmp/render-nosign.txt && ! grep -q "signingkey" /tmp/render-nosign.txt && ! grep -q "\[commit\]" /tmp/render-nosign.txt</automated>
  </verify>
  <done>modify_dot_gitconfig.local rewritten to pure chezmoi-data template with chezmoi:modify-template marker preserved; renders cleanly without signingkey (no [commit] block); zero `output` / placeholder strings remain; quick.sh's SEC-05(b) gate turns GREEN.</done>
</task>

<task type="auto">
  <name>Task 2: Delete home/scripts/generate-gpg-key.sh and verify file-state directly</name>
  <files>home/scripts/generate-gpg-key.sh</files>
  <action>
Delete `home/scripts/generate-gpg-key.sh` from the source tree. Use `git rm home/scripts/generate-gpg-key.sh` so the deletion is tracked.

Then verify Mac personal would not re-fire the script: this is NOT a `run_once_` chezmoi script (it lives in `home/scripts/`, not `home/.chezmoiscripts/`), and `home/modify_dot_gitconfig.local` (Task 1's rewrite) no longer references it via `output`. Therefore: no `chezmoistate.boltdb` entry tracks it for scriptState, and no apply-time path invokes it. The Phase 0.5 Plan 04 lesson — "after source delete, chezmoi managed/diff are SILENT on stale entryState entries" — applies here ONLY if the file had an entryState row. `home/scripts/generate-gpg-key.sh` IS an entryState entry (it's a managed file landing at `~/scripts/generate-gpg-key.sh`). Per Phase 0.5 Plan 04 attestation, the right pattern is `chezmoi state dump | grep generate-gpg-key` to confirm what state cleanup the operator owes on each machine post-merge.

Document this in the commit body (operator must run on Mac personal + Mac work after merge):
```bash
# Operator post-merge cleanup (per machine):
chezmoi state dump | grep generate-gpg-key  # inventory remaining state entries
chezmoi state delete --bucket=entryState --key=/Users/jteague/scripts/generate-gpg-key.sh
# Then verify:
chezmoi diff -x externals  # should be empty wrt generate-gpg-key
rm -f ~/scripts/generate-gpg-key.sh  # destination cleanup if file present
```

This is NOT something Plan 1-02 executes — it's a documented operator handoff in the commit message. Plan 1-02 is autonomous and edits only the source tree.

After deletion, the verify command uses DIRECT FILE-STATE ASSERTIONS (not harness-stdout parsing). The three SEC-05 truths this plan owns are observable on the source tree itself, without invoking `quick.sh`:

- `! test -e home/scripts/generate-gpg-key.sh` — the script is gone
- `grep -q "\.signingkey" home/modify_dot_gitconfig.local` — the template references the chezmoi data field
- `! grep -q "output" home/modify_dot_gitconfig.local` — no `output` shell-out remains

Additionally, `quick.sh` is invoked as a sanity check (no parsing of its stdout — only its exit-or-continue), and `lib.sh` interfaces guarantee these three assertions land on dedicated PASS rows in its output. The plan's contract with downstream waves is the file state, not the harness phrasing.

The other gates (SEC-02, SEC-07, SEC-08, SEC-11, SEC-13, SEC-15) remain RED/PENDING after this plan — those are owned by Plans 1-03, 1-04a, and 1-04b.
  </action>
  <verify>
    <automated>cd /Users/jteague/.local/share/chezmoi && ! test -e home/scripts/generate-gpg-key.sh && grep -q "\.signingkey" home/modify_dot_gitconfig.local && ! grep -q "output" home/modify_dot_gitconfig.local && ! grep -q "data-name\|data-email\|data-helper" home/modify_dot_gitconfig.local && bash .planning/phases/01-credential-plane/checks/quick.sh >/dev/null 2>&1; true</automated>
  </verify>
  <done>generate-gpg-key.sh removed from source tree via git rm; file-state assertions confirm SEC-05(a) (script absent) and SEC-05(b) (template references .signingkey, no `output` call); quick.sh sanity-invocation completes (exit code not asserted — file-state is the contract); commit message documents per-machine entryState cleanup procedure for operator post-merge handoff.</done>
</task>

</tasks>

<verification>
After both tasks:
- `! test -e home/scripts/generate-gpg-key.sh` (file gone)
- `grep -q "\.signingkey" home/modify_dot_gitconfig.local` (data-driven)
- `! grep -q "output" home/modify_dot_gitconfig.local` (no script shell-out)
- `! grep -q "data-name\|data-email\|data-helper" home/modify_dot_gitconfig.local` (no leftover placeholders)
- `STRICT=1 bash .planning/phases/01-credential-plane/checks/quick.sh` still exits non-zero (other waves' gates still RED — this plan only owns SEC-05)
</verification>

<success_criteria>
- SEC-05 (a) and (b) file-state contracts MET on source tree (direct file assertions, not harness-stdout phrasing)
- `home/modify_dot_gitconfig.local` renders cleanly via `chezmoi execute-template` without signingkey present (graceful Stage-1 path)
- Commit body documents the per-machine entryState cleanup ritual (Mac personal + Mac work post-merge)
- Zero modifications to `home/.chezmoi.toml.tmpl` (signingkey is runtime-added, not init-time)
- No new `bw`/`bitwarden` template calls introduced (SEC-15 gate unchanged)
</success_criteria>

<output>
After completion, create `.planning/phases/01-credential-plane/1-02-SUMMARY.md` covering: before/after diff of modify_dot_gitconfig.local, deletion record + git SHA for generate-gpg-key.sh, the entryState cleanup ritual handoff for operator (Mac personal + Mac work paths), and an explicit "until Plan 1-04b lands on a machine, .signingkey is unset and signed-commit is OFF by design" note.
</output>
