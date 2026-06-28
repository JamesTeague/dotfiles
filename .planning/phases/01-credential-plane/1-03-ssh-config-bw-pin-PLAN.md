---
phase: 01-credential-plane
plan: 03
type: execute
wave: 2
depends_on:
  - "1-01"
files_modified:
  - home/private_dot_ssh/config.tmpl
  - home/.chezmoidata/packages.yaml
  - docs/credential-plane.md
autonomous: true
requirements:
  - SEC-02
  - SEC-07
must_haves:
  truths:
    - "Rendered ~/.ssh/config defines Host github-personal with IdentityFile ~/.ssh/personal_ed25519 and IdentitiesOnly yes"
    - "When a machine has ~/.ssh/work_ed25519 present, rendered ~/.ssh/config also defines Host gitlab-bluebeam (file-presence-based gating since employer data field doesn't exist post-Phase-0)"
    - "packages.yaml includes bitwarden-cli formula in roles.dev.core.brews with a PIN comment referencing VaultWarden 1.36.0 and docs/credential-plane.md"
    - "docs/credential-plane.md exists and documents the bw/VW compat pair, the brew-extract pin procedure, the rotation playbook, and the stale-key cleanup procedure"
    - "Structural VW-independence (SEC-15) gate remains GREEN: packages.yaml install names are permitted; no template calls introduced"
  artifacts:
    - path: "home/private_dot_ssh/config.tmpl"
      provides: "Purpose-based SSH Host aliases (github-personal always; gitlab-bluebeam file-presence-gated)"
      contains: "Host github-personal"
      min_lines: 12
    - path: "home/.chezmoidata/packages.yaml"
      provides: "bitwarden-cli formula entry with version-pin comment"
      contains: "bitwarden-cli"
    - path: "docs/credential-plane.md"
      provides: "Operator-facing doc for two-stage bootstrap + bw pin + rotation + stale cleanup"
      min_lines: 80
  key_links:
    - from: "home/private_dot_ssh/config.tmpl"
      to: "~/.ssh/personal_ed25519"
      via: "IdentityFile directive"
      pattern: "IdentityFile.*personal_ed25519"
    - from: "home/private_dot_ssh/config.tmpl"
      to: "~/.ssh/work_ed25519 file-presence"
      via: "stat template gate"
      pattern: "work_ed25519"
    - from: "home/.chezmoidata/packages.yaml"
      to: "docs/credential-plane.md"
      via: "comment reference in the bitwarden-cli line"
      pattern: "credential-plane"
---

<objective>
Land two structural artifacts:

1. `home/private_dot_ssh/config.tmpl` — chezmoi template for the SSH config with purpose-based Host aliases (`github-personal` always present; `gitlab-bluebeam` gated on file-presence of `~/.ssh/work_ed25519`).
2. `home/.chezmoidata/packages.yaml` amendment + new `docs/credential-plane.md` — adds the `bitwarden-cli` brew formula with a version-pin comment referencing VaultWarden 1.36.0 + Pitfall 3 mitigation, and creates the operator-facing doc that explains the two-stage bootstrap, the brew-extract pin procedure, the rotation playbook, and the stale-key cleanup procedure.

**Divergence flag (operator-review during execution):** CONTEXT.md's SSH-config example sketched `gitlab-bluebeam` gated on `.employer == "bluebeam"` chezmoi data. Phase 0 did NOT introduce an `employer` data field (verified by reading `home/.chezmoi.toml.tmpl` during planning — the `[data]` section contains `personal`, `name`, `email`, `role`, `wsl` only). Per 1-RESEARCH Open Question 8 resolution, this plan uses **file-presence gating on `~/.ssh/work_ed25519`** as the fallback mechanism. Operator confirms this divergence during execution checkpoint or escalates back to discussion if an `employer` data field is preferred (in which case Phase 0 would need amendment first).

Purpose: Plan 1-04b's setup-credentials.sh writes keys to `~/.ssh/personal_ed25519` and writes `signingkey` to chezmoi data — the SSH config template makes those keys USABLE for git ops (SEC-07). Plan 1-04b also runs `bw` at runtime for password lookups (NOT in apply path) — the formula pin (SEC-02) prevents drift from breaking Teague's password workflow. The two artifacts are independent of each other; both depend only on Plan 1-01's harness.

Output: One new template, one packages.yaml edit (one line added + one comment), one new documentation file. SEC-02 and SEC-07 gates in checks/quick.sh turn GREEN.
</objective>

<execution_context>
@/Users/jteague/.claude/get-shit-done/workflows/execute-plan.md
@/Users/jteague/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/phases/01-credential-plane/1-CONTEXT.md
@.planning/phases/01-credential-plane/1-RESEARCH.md
@home/.chezmoi.toml.tmpl
@home/.chezmoidata/packages.yaml

<interfaces>
chezmoi template naming convention: `private_dot_ssh/config.tmpl` renders to `~/.ssh/config` with 0700 directory mode (from `private_` prefix) and template-rendered file content.

Phase 0 final state of `home/.chezmoi.toml.tmpl` `[data]` section (confirmed during planning):
- personal (bool)
- name (string)
- email (string)
- role (one of dev/gaming/lite)
- wsl (bool)

There is NO `employer` data field. Resolution per planning-context open question: use file-presence gating for the work-only block via the chezmoi template helper `stat` (returns map when file exists, nil otherwise) on `~/.ssh/work_ed25519`.

Available chezmoi template helpers used here:
- `stat <path>` returns a map if file exists, nil otherwise
- `joinPath` portable path build
- `default <fallback> <val>` returns val if non-empty else fallback

Recommended SSH config template body (adapted from 1-RESEARCH.md Pattern 5 with file-presence gating):

The template emits an always-on `Host github-personal` block and a file-presence-gated `Host gitlab-bluebeam` block. Identity file paths are literal in the rendered output. `IdentitiesOnly yes` is set on both blocks (Pitfall 6 mitigation).

packages.yaml current relevant section (excerpt for placement reference) — `roles.dev.core.brews` contains an alphabetized list including `gh`, `gnupg`, `jq`. The new `bitwarden-cli` entry goes into the same list with an inline PIN comment.

<!-- SEC-15 contract (canonical from Plan 1-01 interfaces block): -->
<!-- All SEC-15 verify commands use the THREE-clause regex: -->
<!--   \bbw \b|bitwardenAttachment|\{\{ *bitwarden  -->
<!-- Dropping any clause violates the SEC-15 contract. -->
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create home/private_dot_ssh/config.tmpl with purpose-based aliases</name>
  <files>home/private_dot_ssh/config.tmpl</files>
  <action>
Create directory `home/private_dot_ssh/` (chezmoi naming: `private_` prefix sets 0700 dir mode, `dot_ssh` maps to `.ssh`).

Write `home/private_dot_ssh/config.tmpl` with this exact structure:

- Top of file: a whitespace-trimmed chezmoi template comment pointing at `docs/credential-plane.md`. Whitespace trimming is REQUIRED — without it the comment leaves a blank line at the top of the rendered config, which is harmless but ugly.
- Always-present `Host github-personal` block with directives: `HostName github.com`, `User git`, `IdentityFile ~/.ssh/personal_ed25519`, `IdentitiesOnly yes`.
- A blank line, then a `{{- if stat (joinPath .chezmoi.homeDir ".ssh" "work_ed25519") }}` gate that conditionally emits a `Host gitlab-bluebeam` block with `HostName {{ default "gitlab.bluebeam.com" .bluebeamGitlabHost }}` (defers exact hostname to a chezmoi data field if the user adds one; sensible placeholder otherwise), `User git`, `IdentityFile ~/.ssh/work_ed25519`, `IdentitiesOnly yes`. Closed with `{{- end }}`.

Specific requirements:
1. The `Host github-personal` block is ALWAYS rendered (every dev-role machine — see SEC-07 spec).
2. The `Host gitlab-bluebeam` block is gated on file-presence of `~/.ssh/work_ed25519`. **Divergence note (carry into commit body):** CONTEXT.md sketched `.employer == "bluebeam"` data-field gating. Phase 0 did not introduce that field, so file-presence is the fallback per 1-RESEARCH Open Question 8. If the operator prefers a data-field gate, escalate before merging — Phase 0 amendment is required first.
3. `IdentitiesOnly yes` MUST appear in both blocks (Pitfall 6 mitigation per 1-RESEARCH.md — prevents ssh-agent from offering every loaded key and hitting MaxAuthTries).
4. NO `bw` / `bitwarden` references anywhere in this template (SEC-15 gate).
5. NO interactive prompts or `output` shell-outs (this is a pure data-driven template).

Confirm the template renders cleanly via `chezmoi execute-template --init` against synthetic prompt data. Expected output: a config containing the `Host github-personal` block. Whether `gitlab-bluebeam` appears depends on whether `~/.ssh/work_ed25519` exists on the planner machine (Mac personal: no; Mac work: yes). The verify command below tests only the always-present block.
  </action>
  <verify>
    <automated>cd /Users/jteague/.local/share/chezmoi && test -f home/private_dot_ssh/config.tmpl && chezmoi execute-template --init --promptString name=Test --promptString email=t@e.com --promptBool personal=true --promptChoice role=dev < home/private_dot_ssh/config.tmpl > /tmp/ssh-render.txt 2>&1 && grep -q "Host github-personal" /tmp/ssh-render.txt && grep -q "IdentityFile ~/.ssh/personal_ed25519" /tmp/ssh-render.txt && grep -q "IdentitiesOnly yes" /tmp/ssh-render.txt && ! grep -E "\\bbw \\b|bitwardenAttachment|\\{\\{ *bitwarden" home/private_dot_ssh/config.tmpl</automated>
  </verify>
  <done>Template renders cleanly with github-personal block always present; gitlab-bluebeam block conditionally emitted based on `~/.ssh/work_ed25519` presence; IdentitiesOnly yes set on both blocks; SEC-15 three-clause regex returns zero matches on the template; SEC-07 gate in quick.sh turns GREEN; divergence note (CONTEXT employer-data-field vs file-presence) carried into commit body for operator review.</done>
</task>

<task type="auto">
  <name>Task 2: Amend packages.yaml with bitwarden-cli pin entry and write docs/credential-plane.md</name>
  <files>home/.chezmoidata/packages.yaml, docs/credential-plane.md</files>
  <action>
**Part A — packages.yaml**: Add the line `        - 'bitwarden-cli' # PIN: pair with VaultWarden 1.36.0 — see docs/credential-plane.md (SEC-02 / Pitfall 3)` to the `roles.dev.core.brews` list. Place it in alphabetical position (after `awscli`, before `chezmoi`, or wherever the alphabetical slot falls — match the existing single-quoted-string style of the list verbatim). Do NOT modify any other section.

Do NOT change the Homebrew formula to a versioned form (`bitwarden-cli@2025.11.0` does not exist upstream — see 1-RESEARCH.md Brew Pinning section). The PIN comment is the authoritative pin marker; the actual pinning ritual (`brew extract` to local tap) is documented in `docs/credential-plane.md` and executed manually per machine. Hand-edit style — NOT a YAML round-trip — to preserve quote style and inline comment placement (Plan 00.5-05 lesson).

**Part B — docs/credential-plane.md**: Create the operator-facing documentation file. Mirror the existing `docs/conventions.md` style (heading conventions, code-block fencing, section numbering if used). Sections required:

1. **Two-stage bootstrap overview** — Stage 1 (`chezmoi init --apply` — public repo, offline-safe, no VW calls) vs Stage 2 (`setup-credentials.sh` — interactive, one-time per machine). Reference 1-CONTEXT.md decision summary.

2. **Per-machine key model** — what gets generated per machine (personal SSH + personal GPG), what is NOT generated (Bluebeam GitLab work SSH — hand-generated on work Mac, out of script scope), why per-machine (no rotation fanout; lost-machine blast radius bounded to one machine; multiple verified keys per GitHub account is supported).

3. **bw / VaultWarden compat pair** — the live VW server is 1.36.0; the recommended bw pin ceiling is 2025.11.0 per vaultwarden#6729 (vs VW 1.35.2 baseline; 1.36.0 needs empirical re-verification — see 1-RESEARCH.md Open Question 3). Brew-extract procedure verbatim:

```
brew tap-new "${USER}/local"
brew extract --version=2025.11.0 bitwarden-cli "${USER}/local"
brew install "${USER}/local/bitwarden-cli@2025.11.0"
brew pin bitwarden-cli@2025.11.0
```

Document that this is one-time-per-machine setup; pin bumps in lockstep with VW server upgrades.

4. **Rotation playbook** — `setup-credentials.sh --rotate-ssh`, `--rotate-gpg`, `--rotate-all`. What each does (regenerate local keypair, re-register with GitHub via gh CLI, LOG the prior fingerprint/key-ID to stdout). What rotation does NOT do (delete the prior GitHub-side key — operator decides via manual cleanup; see next section).

5. **Stale GitHub-side key cleanup** — quarterly cleanup procedure. `gh ssh-key list --json id,title,createdAt` + `gh gpg-key list` produces an audit-friendly inventory. Title convention `<hostname>-personal-<YYYYMMDD>` makes stale entries identifiable. Manual deletion via `gh ssh-key delete <id>` / `gh gpg-key delete <id>`. This is explicitly MANUAL — out of script scope per CONTEXT.

6. **VM verification target** — Parallels macOS 26.5.1 arm64 VM at jteague@10.211.55.4, snapshot `vanilla-fresh-boot-pre-chezmoi`. First phase to use VM verification. `checks/vm-e2e.sh` is the composite orchestrator. Restore snapshot between distinct test scenarios (fresh-install vs rotation); do NOT restore between fresh-install and idempotency re-run (that's the point of idempotency).

7. **Pitfall mitigations carried over** — Pitfall 3 (bw/VW drift) addressed by formula pin + this doc. Pitfall 10 (VW unreachable bricks apply) structurally eliminated by removing VW from apply path. Reference 1-RESEARCH.md sections by name.

Length target: 80-150 lines. Operator-facing tone (procedures + commands first; rationale second). The file is the single authoritative reference for credential plane operations; commits to bw pin / rotation flag behavior MUST be reflected here in the same change.

Confirm the SEC-15 three-clause regex still passes — neither file change introduces any apply-time `bw` template call.
  </action>
  <verify>
    <automated>cd /Users/jteague/.local/share/chezmoi && grep -q "bitwarden-cli" home/.chezmoidata/packages.yaml && grep -q "PIN" home/.chezmoidata/packages.yaml && grep -q "credential-plane.md" home/.chezmoidata/packages.yaml && test -f docs/credential-plane.md && wc -l docs/credential-plane.md | awk '{exit ($1 >= 80) ? 0 : 1}' && grep -q "VaultWarden 1.36.0" docs/credential-plane.md && grep -q "brew extract" docs/credential-plane.md && grep -q "rotate-ssh\|rotate-gpg\|rotate-all" docs/credential-plane.md && grep -q "gh ssh-key list" docs/credential-plane.md && grep -q "vanilla-fresh-boot-pre-chezmoi" docs/credential-plane.md && ! grep -rEn "\\bbw \\b|bitwardenAttachment|\\{\\{ *bitwarden" home/ --include='*.tmpl'</automated>
  </verify>
  <done>packages.yaml has bitwarden-cli formula with PIN comment referencing VaultWarden 1.36.0 and docs/credential-plane.md; docs/credential-plane.md exists with all seven required sections and at least 80 lines; SEC-02 gate in quick.sh turns GREEN; SEC-15 three-clause structural grep returns zero matches in `*.tmpl` files (no new apply-time VW calls introduced).</done>
</task>

</tasks>

<verification>
After both tasks:
- `test -f home/private_dot_ssh/config.tmpl` and `chezmoi execute-template < home/private_dot_ssh/config.tmpl` renders Host github-personal block
- `grep -q "bitwarden-cli" home/.chezmoidata/packages.yaml` and the line includes the PIN comment with VW 1.36.0 reference
- `test -f docs/credential-plane.md` with 80+ lines and all seven sections
- `bash .planning/phases/01-credential-plane/checks/quick.sh` shows SEC-02 and SEC-07 gates as PASS
- SEC-15 three-clause structural grep (`\bbw \b|bitwardenAttachment|\{\{ *bitwarden`) returns zero matches in `*.tmpl` files
</verification>

<success_criteria>
- SEC-02 and SEC-07 gates in checks/quick.sh turn GREEN
- SSH config template renders Host github-personal unconditionally with IdentitiesOnly yes
- SSH config template renders Host gitlab-bluebeam ONLY when ~/.ssh/work_ed25519 exists on the target machine
- Divergence from CONTEXT example (file-presence vs `.employer` field) explicitly flagged for operator review in objective + commit body
- docs/credential-plane.md is the single authoritative ops reference for the credential plane
- bitwarden-cli entry in packages.yaml carries the PIN comment but uses the unversioned formula name (brew-extract ritual is documented, not scripted)
- No new bw/bitwardenAttachment template calls introduced (canonical three-clause regex green)
</success_criteria>

<output>
After completion, create `.planning/phases/01-credential-plane/1-03-SUMMARY.md` covering: the rendered SSH config shape (both blocks shown), the chosen file-presence gating mechanism + why (Phase 0 lacks employer field) + the divergence-flag operator-review outcome, the bitwarden-cli PIN comment as committed, the seven docs/credential-plane.md sections with line counts, and a confirmation that the SEC-15 three-clause structural grep gate remains GREEN.
</output>
