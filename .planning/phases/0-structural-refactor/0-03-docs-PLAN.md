---
phase: 0-structural-refactor
plan: 03
type: execute
wave: 3
depends_on: ["0-02"]
files_modified:
  - docs/conventions.md
autonomous: true
requirements: [TAX-08, LNX-05]
must_haves:
  truths:
    - "`docs/conventions.md` § 10 (or equivalent dedicated subsection) contains the 6 inherited Phase 0.5 AUD-02 LIGHT inconsistencies, documented as pitfall/pattern notes"
    - "Section documents the locked decision: NO Linux Homebrew — `.chezmoiscripts/linux/` skeleton uses apt + mise only (LNX-05)"
    - "Section documents `.localrc` + `~/.local/bin/` employer-local pattern (resolves 0.5 follow-ups #6 + #9 as documentation; the code-side resolution lives in Plan 01's exact_bin teardown + cutover script)"
    - "Section documents 5 follow-up notes from CONTEXT.md disposition table: #1 (chezmoi state dump as canonical clean-check utility), #2 (chezmoi apply --dry-run --verbose exits nonzero on interactive TTY prompts), #3 (mas list Apple ID invisibility — practical fix is Plan 02's /Applications/ guard), #5 (state-forge pattern), #8 (Pitfall C re-validation: source-delete does NOT auto-remove destination on either chezmoi 2.69.4 or 2.70.4)"
    - "Section explicitly notes goal amendment #1: SC #5 (`generate-gpg-key.sh` deletion) DEFERRED to Phase 1 because script is load-bearing via `home/modify_dot_gitconfig.local:6` modify-template"
    - "Section explicitly notes goal amendment #3 reframing of SC #2: `.chezmoiignore` is FILE PRESENCE only — template-internal runtime logic stays in templates"
    - "TAX-08 verification by inspection: `docs/dot_topics.md` exists and contains the `dot_topics/<tool>` convention text (inherited from Phase 0.5 Plan 02; no new work — just verify)"
  artifacts:
    - path: "docs/conventions.md"
      provides: "§ 10 expanded with 6 inherited inconsistencies + 5 follow-up pitfall/pattern notes + 2 goal amendments + .localrc/.local/bin pattern + LNX-05 decision"
      contains: ".localrc"
    - path: "docs/dot_topics.md"
      provides: "TAX-08 inherited from Phase 0.5 Plan 02 — verify-only, no new content"
      contains: "dot_topics"
  key_links:
    - from: "docs/conventions.md § 10"
      to: ".planning/phases/00.5-audit-documentation/00.5-drift-reconciliation.md 'Phase 0 follow-ups' section"
      via: "follow-up disposition table — Plan 03 closes follow-ups #1, #2, #3, #5, #8 as docs (the code-side resolutions are owned by Plan 01 + Plan 02)"
    - from: "docs/conventions.md § 10"
      to: "0-CONTEXT.md goal amendments + Phase 0.5 Plan 02 inconsistencies list"
      via: "documentation reference — captures the AUD-02 LIGHT remainder + goal amendments as living patterns"
---

<objective>
Land the docs commit: expand `docs/conventions.md` with the AUD-02 LIGHT remainder (6 inherited inconsistencies from Phase 0.5 Plan 02), Phase 0 goal amendments (generate-gpg-key.sh deferred; .chezmoiignore reframed to file-presence-only), 5 follow-up pitfall/pattern notes from the Phase 0.5 disposition table (#1, #2, #3, #5, #8), the `.localrc` + `~/.local/bin/` employer-local pattern, and the LNX-05 locked decision (NO Linux Homebrew).

Purpose: Docs is the third and final commit of the Phase 0 three-commit breakdown. Lands after structural (Plan 01) and mas guard (Plan 02) so the merge-gate `chezmoi diff -x externals` reads against pure code commits. Closes the documentation half of 0.5's 9 follow-ups; the code half is closed by Plans 01 + 02.

Output: 1 git commit titled `docs(phase-0): conventions § 10 — AUD-02 remainder + Phase 0 patterns + follow-up pitfalls`. Touches a single file (docs/conventions.md). Wave 3 (depends on Plans 01 + 02 — content references their implementations as the canonical examples).
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
@.planning/phases/0-structural-refactor/0-02-SUMMARY.md
@.planning/phases/00.5-audit-documentation/00.5-drift-reconciliation.md
@.planning/phases/00.5-audit-documentation/00.5-exit-gate-report.md
@docs/conventions.md
@docs/dot_topics.md

<interfaces>
<!-- The Phase 0.5 disposition table (from 0-CONTEXT.md + 0-RESEARCH.md) is the load-bearing input here. -->

**Docs-owned follow-up dispositions (this plan):**

| # | Follow-up | This plan does |
|---|-----------|----------------|
| 1 | `chezmoi state dump` as canonical clean-check utility | Documents as utility pattern (NOT a load-bearing assertion in verify gates — see CONTEXT.md "Deferred Ideas") |
| 2 | `chezmoi apply --dry-run --verbose` exits nonzero on interactive TTY prompts | Documents as pitfall — pair `diff -x externals` with `--dry-run --verbose` but be aware the latter can false-fail on interactive source |
| 3 | `mas list` Apple ID invisibility | Documents pitfall + cross-reference to Plan 02 as the practical fix |
| 5 | state-forge pattern (symmetric inverse of state-delete) | Documents pattern: legitimate when underlying reality has been verified; cite Phase 0.5 Plan 06 Task 1 Brother iPrint as example |
| 8 | Pitfall C re-validation (source-delete leaves destination on BOTH 2.69.4 and 2.70.4) | Documents pitfall with the empirical update from Phase 0.5 |

**Code-owned follow-up dispositions (NOT this plan — already done in 01/02):**

| # | Follow-up | Owner |
|---|-----------|-------|
| 4 | mas /Applications/ guard | Plan 02 |
| 6 | `.localrc` + Mac-work NODE_EXTRA_CA_CERTS migration | Plan 01 cutover script |
| 7 | chezmoi version floor + `--key /path` space-separated form | Plan 01 cutover script |
| 9 | `exact_bin` teardown → `private_dot_local/bin/` | Plan 01 |

**AUD-02 LIGHT remainder (6 inherited inconsistencies, from Phase 0.5 Plan 02 conventions.md § 10 baseline):**

Read the EXISTING § 10 in `docs/conventions.md` first — Phase 0.5 Plan 02 left 6 inconsistencies flagged but NOT normalized (deferred to Phase 0 for renaming decisions because rename changes destination file mode — break zero-functional-diff exit-gate). Examples likely include:

- `rust/path.zsh` (no executable_ prefix where peers have it)
- `system/path.zsh.tmpl` (no executable_ prefix where peers have it)
- OS-routing asymmetries (some files use `.tmpl` runtime gate; some use directory placement)
- `packages.yaml` cross-cutting structure smells (resolved by Plan 01 restructure — note as RESOLVED)
- `.DS_Store` at root
- (6th inconsistency — read source to confirm)

For each: document the inconsistency, document whether Phase 0 resolved it (Plan 01's packages restructure RESOLVED the packages-shape one; the others remain DEFERRED — flag as Phase 1+ work).

**Goal amendments (must be documented):**

- **Amendment #1:** SC #5 (`generate-gpg-key.sh` deletion) deferred to Phase 1. Rationale: script is load-bearing via `home/modify_dot_gitconfig.local:6` (chezmoi modify-template runs script on every apply; stdout becomes `~/.gitconfig.local` content). Deleting in Phase 0 would break `git commit -S` on next apply. Phase 1 owns the atomic VaultWarden landing — delete + rewrite happen together.
- **Amendment #2 (was #3 in CONTEXT.md numbering):** SC #2 (`.chezmoiignore` single gating decision point) reframed to FILE PRESENCE ONLY. Template-internal runtime logic (e.g., `{{ if eq .chezmoi.os "darwin" }}` blocks inside scripts) stays in templates; `.chezmoiignore` can only gate whether a file exists at the destination at all.

**`.localrc` + `~/.local/bin/` pattern (must be documented):**

The employer-local axis. NOT a 5th templated axis. Pattern: personal-identity content stays chezmoi-managed; employer/site-local content stays per-machine in:
- `~/.localrc` — sourced by `dot_zshrc.tmpl:4-7` (already in source)
- `~/.local/bin/` — first on PATH via mise (Phase 0.5 Plan 06 finding: `start-aws-mcp.sh` was moved here for Bluebeam tooling)

Why this beats a 5th templated axis (per CONTEXT.md Employer Axis decision rationale, reproduce briefly):
1. Content (e.g., `NODE_EXTRA_CA_CERTS=...`) references employer-IT-provisioned files; templating one line of indirection isn't substance
2. Dotfiles are personal-identity; employer config leaks + contaminates over time
3. Pattern is already half-adopted

**LNX-05 (must be documented):**

NO Linux Homebrew anywhere. `.chezmoiscripts/linux/` (when Phase 3 lands it) uses apt + mise only. Cite Phase 3 as the future implementation phase.
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Expand docs/conventions.md § 10 with AUD-02 remainder + goal amendments + 5 follow-up notes + .localrc pattern + LNX-05 decision</name>
  <files>
    docs/conventions.md
  </files>
  <action>
**Sub-task 1A — Read existing structure:**

Read `docs/conventions.md` end-to-end. Identify § 10 (or whatever the AUD-02 LIGHT section is currently labeled — Phase 0.5 Plan 02 created it). Inventory what's already there: the 6 inherited inconsistencies, their current framing.

**Sub-task 1B — Plan the additions:**

Decide the section structure. Recommended layout:

```markdown
## 10. Phase 0 Patterns & Follow-up Pitfalls

### 10.1 Phase 0 Goal Amendments (from Phase 0 CONTEXT.md)

#### 10.1.1 generate-gpg-key.sh: deferred to Phase 1 (NOT Phase 0)
[explanation per <interfaces> Amendment #1]

#### 10.1.2 .chezmoiignore: FILE PRESENCE only (not template-internal logic)
[explanation per <interfaces> Amendment #2]

### 10.2 Employer-Local Pattern: .localrc + ~/.local/bin/
[explanation per <interfaces> .localrc section]

### 10.3 LNX-05 Locked Decision: NO Linux Homebrew
[explanation per <interfaces> LNX-05 section; cite Phase 3 as the implementation phase]

### 10.4 Phase 0.5 Follow-up Pitfalls (docs-owned: #1, #2, #3, #5, #8)

#### 10.4.1 chezmoi state dump as canonical clean-check utility (follow-up #1)
#### 10.4.2 chezmoi apply --dry-run --verbose exits nonzero on interactive TTY prompts (follow-up #2)
#### 10.4.3 mas list Apple ID invisibility (follow-up #3 — practical fix is the /Applications/ guard, see home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl)
#### 10.4.4 state-forge pattern (follow-up #5)
#### 10.4.5 Pitfall C re-validation: source-delete leaves destination on BOTH chezmoi 2.69.4 AND 2.70.4 (follow-up #8)

### 10.5 AUD-02 LIGHT Remainder (6 inherited Phase 0.5 inconsistencies)

#### 10.5.1 [first inconsistency from existing § 10] — Phase 0 disposition: RESOLVED/DEFERRED
#### 10.5.2 ...etc through 6
```

(The "10" prefix assumes the doc currently goes to § 9 or § 10; adjust to match the actual existing numbering. If § 10 already exists from Phase 0.5 Plan 02, treat this work as renaming + expanding the existing § 10 — preserve existing content where it documents the inherited inconsistencies, add new subsections for everything else.)

**Sub-task 1C — Write the content:**

For each new subsection, write 2-5 sentences. Cite the source artifact (e.g., "Per Phase 0.5 Plan 06 Task 1 finding"). Cross-reference Plan 01 + Plan 02 by file path (`home/.chezmoiignore`, `home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl`) NOT by plan number — the file is the load-bearing reference.

For the 5 follow-up subsections:
- **#1 (state dump):** Use as a utility for ad-hoc "is my state bucket clean?" inspection. NOT a load-bearing assertion in Phase 0 verify gates (deferred per CONTEXT.md "Deferred Ideas"). Example command: `chezmoi state dump | grep -i flameshot` (Plan 04 of 0.5 found this is the only discovery surface for stale entryState entries — `chezmoi managed` and `diff` were both silent for orphaned-state-only entries).
- **#2 (dry-run nonzero):** When `home/dot_zshrc.tmpl:80` contains an interactive prompt (DEBUG=1 question), `chezmoi apply --dry-run --verbose` exits nonzero even though the source is otherwise valid. Mitigation: filter dry-run output by pattern (`grep "no value"`) or reconcile pre-existing drift first — don't gate on exit code alone.
- **#3 (mas list invisibility):** `mas list` only sees apps under the currently-signed-in Apple ID. Sideloaded or different-Apple-ID apps (e.g., Brother iPrint on Mac personal) are visible to `/Applications/` but invisible to mas. PRACTICAL FIX: file-presence guard around `mas install` (see `home/.chezmoiscripts/run_onchange_before_03-mas.sh.tmpl`).
- **#5 (state-forge):** Inverse of `chezmoi state delete`. When underlying reality has been verified manually (e.g., "the file IS installed but mas can't see it"), forge the entryState SHA to mark chezmoi-aware of the destination state. Cite Phase 0.5 Plan 06 Task 1 Brother iPrint as the example. Caveat: legitimate only when reality is verified by another mechanism — never blind-forge.
- **#8 (Pitfall C re-validation):** Source-delete does NOT auto-remove destination. Confirmed empirically on BOTH chezmoi 2.69.4 AND 2.70.4 (Phase 0.5 Plan 06 captured both versions). The only mechanism that removes the destination is operator-driven `rm` (plus optional `chezmoi state delete --bucket=entryState --key /path` for state hygiene; the destination delete is the load-bearing part).

For the AUD-02 LIGHT remainder (6 inconsistencies), preserve the existing list and ADD a "Phase 0 disposition" line to each:
- `packages.yaml` shape smells → RESOLVED in Plan 01 (restructure to `roles × overlays`)
- The rest → DEFERRED (likely Phase 1+ when other refactors warrant changing destination file modes)

**Sub-task 1D — TAX-08 verify-by-inspection:**

`docs/dot_topics.md` was created by Phase 0.5 Plan 02 (TAX-08 inherited). Verify it still exists and contains the canonical `dot_topics/<tool>` convention text:

```
test -f docs/dot_topics.md && grep -q "dot_topics" docs/dot_topics.md
```

If verification fails, halt and surface — TAX-08 was supposed to be inherited; missing file means 0.5 regression and needs investigation BEFORE Phase 0 closes. Do NOT recreate the file here (that's out of scope; this plan's job is to verify, not regenerate Phase 0.5 outputs).

**Sub-task 1E — TAX-05 docs sanity-add (LNX-05 cross-reference):**

In § 10.3, add a one-line cross-reference to the actual packages.yaml shape that Plan 01 lands: `Linux dev essentials live at packages.roles.dev.linux.{brews,casks,taps} but use apt+mise consumers (NOT brew bundle on Linux). See home/.chezmoidata/packages.yaml for current shape; Phase 3 lands the apt+mise consumer.`

This isn't a NEW requirement — it's a documentation cross-link to make the LNX-05 decision discoverable from the YAML shape's existence.

**Sub-task 1F — Run Wave 0 harness to confirm no regression:**

```
bash .planning/phases/0-structural-refactor/checks/full.sh --no-diff-gate
```

Must exit 0. (The docs change is content-only; no template state changes. Harness should be stable from Plan 02 baseline.)
  </action>
  <verify>
    <automated>test -f docs/conventions.md && grep -qE '(\.localrc|~/.local/bin)' docs/conventions.md && grep -qE '(NO Linux Homebrew|apt \+ mise|apt and mise)' docs/conventions.md && grep -qE 'generate-gpg-key' docs/conventions.md && grep -qE '(file.presence|FILE PRESENCE)' docs/conventions.md && grep -qiE '(state dump|state-forge|mas list|dry-run.*nonzero|Pitfall C)' docs/conventions.md && test -f docs/dot_topics.md && grep -q 'dot_topics' docs/dot_topics.md && bash .planning/phases/0-structural-refactor/checks/full.sh --no-diff-gate</automated>
  </verify>
  <done>
    docs/conventions.md § 10 expanded with goal amendments + .localrc/.local/bin pattern + LNX-05 decision + 5 follow-up pitfall notes + 6 AUD-02 LIGHT inconsistencies with Phase 0 dispositions. docs/dot_topics.md verified present (TAX-08 inheritance confirmed). Wave 0 full.sh --no-diff-gate stays green.
  </done>
</task>

</tasks>

<verification>
**TAX-08 verification by inspection:** `test -f docs/dot_topics.md && grep -q dot_topics docs/dot_topics.md` — inherited from Phase 0.5 Plan 02; this plan only confirms presence.

**LNX-05 verification:** `grep -q "NO Linux Homebrew\|apt + mise\|apt and mise" docs/conventions.md` — documented decision is the requirement; no code change.

**Sampling rate per 0-VALIDATION.md:** `bash .planning/phases/0-structural-refactor/checks/quick.sh` after commit (must stay green — docs commit doesn't touch source tree, so harness should be stable).

**No manual-only verifications for this plan** — docs are content; the prose is verified by `grep`-able patterns above. Operator-driven cutover (Plans 01-02 territory) is unaffected.
</verification>

<success_criteria>
1. `docs/conventions.md` contains all the additions listed in must_haves.truths.
2. `docs/dot_topics.md` verified present (TAX-08 inheritance from Phase 0.5).
3. Wave 0 full.sh --no-diff-gate stays green (no regression from docs-only changes).
4. Single git commit titled `docs(phase-0): conventions § 10 — AUD-02 remainder + Phase 0 patterns + follow-up pitfalls`.
5. Plan SUMMARY written: `.planning/phases/0-structural-refactor/0-03-SUMMARY.md`.
6. Plans 01 + 02 + 03 form three sequential commits visible in `git log --oneline -3` since branch creation; in that order; mas-guard AFTER structural; docs LAST.
</success_criteria>

<output>
After completion, create `.planning/phases/0-structural-refactor/0-03-SUMMARY.md` documenting:
- Section structure of the expanded § 10 (subsection headers)
- Which AUD-02 LIGHT inconsistencies were marked RESOLVED vs DEFERRED
- Line count delta of docs/conventions.md (before vs after)
- Cross-references made to Plans 01 + 02 files
- Hand-off to phase close: Phase 0 source-tree work is DONE; operator-driven cutover ritual is next (Mac personal first, then Mac work). Cutover scripts live at `.planning/phases/0-structural-refactor/cutover-phase-0.sh`.

Git commit message:
```
docs(phase-0): conventions § 10 — AUD-02 remainder + Phase 0 patterns + follow-up pitfalls

Expands docs/conventions.md § 10 with:
- Phase 0 goal amendments (generate-gpg-key.sh deferred to Phase 1;
  .chezmoiignore reframed to FILE PRESENCE only)
- Employer-local pattern: .localrc + ~/.local/bin/ (resolves 0.5
  follow-ups #6 + #9 documentation half; code half in Plan 01)
- LNX-05 locked decision: NO Linux Homebrew — apt + mise only
- 5 follow-up pitfall notes: #1 chezmoi state dump, #2 dry-run nonzero
  on TTY prompts, #3 mas list Apple ID invisibility, #5 state-forge
  pattern, #8 Pitfall C re-validation on both chezmoi versions
- AUD-02 LIGHT remainder (6 inherited inconsistencies) with Phase 0
  dispositions: packages.yaml shape RESOLVED via Plan 01; others
  DEFERRED to Phase 1+

TAX-08 inherited from Phase 0.5 Plan 02 (docs/dot_topics.md — verified
present, no new content).

Requirements: TAX-08 (verify-by-inspection), LNX-05 (documented decision)
```
</output>
