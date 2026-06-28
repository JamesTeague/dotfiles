# Phase 1: Credential Plane — Research

**Researched:** 2026-06-04
**Domain:** Per-machine credential bootstrap (SSH + GPG) on macOS for a chezmoi dotfiles fleet; GitHub registration via `gh` CLI; structural decoupling from VaultWarden
**Confidence:** HIGH on `gh`/GPG/SSH primitives; HIGH on chezmoi data plumbing; MEDIUM on exact `bw`-vs-VaultWarden-1.36.0 pin (compat matrix is empirical, not documented)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Two-stage bootstrap.** `chezmoi apply` and credential setup are separate steps. `apply` never reads from VW; it does package install, shell/editor/tool config, and writes templates that reference credential paths without depending on those paths being populated.

```
Stage 1 (no prompts, offline-safe):
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply JamesTeague/dotfiles
Stage 2 (prompts, one-time per machine):
  setup-credentials.sh
  # gh auth login (device flow) → ssh-keygen → gh ssh-key add → gpg keygen
  # → gh gpg-key add → write signingkey → rewrite chezmoi remote
```

**Per-machine, regenerable keys.** Each machine generates its own SSH + GPG keypair locally. NOT stored centrally. Personal SSH/GPG registered via `gh`. Bluebeam GitLab work SSH is hand-generated on the work Mac (out of script scope). Multiple verified keys per GitHub account is supported and unremarkable.

**Empty passphrases** on both SSH and GPG keys. Defense rests on FileVault + macOS user login.

**VW role:** installed via `bw` Homebrew formula (pinned). Runtime password lookup only. Apply does NOT call VW. Apply works fine with VW unreachable.

**Public dotfiles repo** (reverted from "going private" — no privacy gain remains).

**`modify_dot_gitconfig.local` rewrite** (SEC-05 carryover): replace `output $generate-gpg-key.sh` mechanism with chezmoi-data-driven template. `.signingkey` becomes a chezmoi data field set by `setup-credentials.sh`. `home/scripts/generate-gpg-key.sh` DELETED.

**Idempotency model:** safe re-run. Default = no-op when already configured. Explicit `--rotate-*` flag forces regen + re-register + optional cleanup of prior GitHub-side key.

**Script not a chezmoi script.** `setup-credentials.sh` is explicitly invoked by user. NOT a `run_once_` chezmoi script. Lives in repo for distribution.

**`bw` CLI version pinned** against VaultWarden 1.36.0 (Pitfall 3 mitigation). When VW server upgrades, pin bumps in lockstep.

**SSH config:** purpose-based Host aliases (`github-personal`, `gitlab-bluebeam`). Bluebeam-internal hostname is per-machine data, not template literal. Work-key block templated on a chezmoi data field (e.g., `.employer == "bluebeam"` or `.hasWorkGit`).

**Verification target:** Parallels macOS 26.5.1 arm64 VM at `jteague@10.211.55.4`, snapshot `vanilla-fresh-boot-pre-chezmoi`. First phase to use a VM target.

### Claude's Discretion

These open questions are mine to resolve in research and recommend in plan:

1. Exact chezmoi data field name for `signingkey` (which file, which key path).
2. Script location: `home/scripts/`, `bootstrap/`, or other.
3. Rotation flag shape: `--rotate` vs `--rotate-ssh`/`--rotate-gpg`/`--rotate-all`.
4. GitHub-side stale key cleanup (manual + documented vs scripted).
5. Multi-host SSH config beyond `github-personal` + `gitlab-bluebeam`.
6. `bw` pin syntax in `packages.yaml` (formula `@version` is not directly supported — see Brew Pinning section).
7. Test plan for signed-commit verification on VM (setup steps — test repo clone, etc.).
8. `modify_dot_gitconfig.local` final shape — pure template / conditional output / removed in favor of static template.

### Deferred Ideas (OUT OF SCOPE)

- Canonical GPG migration (no use case yet).
- Encrypted bootstrap kit (regenerable credentials don't need DR encryption).
- Vault-offline runtime drill (replaced by structural VW-independence grep).
- PAT-rotation automation.
- Bluebeam GitLab key automation.
- Lonestar onboarding specifics.
- Migrating to SSH-based commit signing (gpg.format=ssh) — flagged but not adopted; see "Alternatives Considered."
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SEC-02 | `bw` CLI version pinned in `packages.yaml` against VaultWarden 1.36.0 | See "Bitwarden CLI / VaultWarden Compatibility" — empirical version-bracketing pattern + brew-extract/local-tap pin technique. |
| SEC-05 | `home/scripts/generate-gpg-key.sh` DELETED + `modify_dot_gitconfig.local` rewritten (Phase 0 carryover) | See "chezmoi `modify_` Pattern" — `.chezmoi.stdin` stays in scope; rewrite reads `.signingkey` from chezmoi data. |
| SEC-07 | `~/.ssh/config` uses purpose-based Host aliases | See "SSH Config Template" — `Host github-personal` + machine-gated `Host gitlab-bluebeam`; chezmoi naming `private_dot_ssh/config.tmpl`. |
| SEC-08 | chezmoi repo remote rewritten to `git@github-personal:JamesTeague/dotfiles.git` | See "Rewriting chezmoi's Own Remote" — `chezmoi git -- remote set-url origin <url>` is canonical. |
| SEC-09 | `git commit -S` works on first machine setup (per-machine GPG identity) | See "GitHub Multi-Key Verification" — multiple verified GPG keys per account fully supported; per-machine identity does not break verification. |
| SEC-10 | `ssh -T git@github-personal` authenticates as personal identity on first setup | See "gh ssh-key add" + "SSH Config Template" — purpose alias resolves to per-machine private key path. |

**New per-machine-keygen requirements introduced by 2026-06-04 pivot** (planner SHOULD enumerate as explicit IDs or fold into the above):

| Proposed ID | Description |
|-------------|-------------|
| SEC-11 (proposed) | `setup-credentials.sh` exists, is idempotent, and lives in the repo for distribution (not a `run_once_` chezmoi script). |
| SEC-12 (proposed) | `setup-credentials.sh` exposes `--rotate-*` flag (shape TBD) that regenerates + re-registers + optionally deregisters prior GitHub-side key. |
| SEC-13 (proposed) | Per-machine SSH key generated with `ssh-keygen -t ed25519 -N "" -C "<hostname>-personal-<date>"` and registered via `gh ssh-key add`. |
| SEC-14 (proposed) | Per-machine GPG key generated with `gpg --batch --gen-key` (parameter file w/ `%no-protection`) and registered via `gh gpg-key add` (armored pubkey). |
| SEC-15 (proposed) | Structural VW-independence verified: grep of `home/**` + `home/.chezmoiscripts/` for `bitwarden*`/`bw `/`{{ bitwarden` returns zero matches in apply-time code paths (the `bitwarden` line in `packages.yaml` is the GUI cask name and OK). |
| SEC-16 (proposed) | End-to-end verification on Parallels VM (snapshot `vanilla-fresh-boot-pre-chezmoi`): Stage 1 + Stage 2 produces a signed verified commit and successful `ssh -T git@github-personal`. |

The carryover SEC-05 supersedes its original framing; per-machine keys eliminate the canonical-GPG-via-VW mechanism, so the rewrite is to chezmoi-data-driven, not VW-driven.
</phase_requirements>

## Summary

The pivot turns Phase 1 from a multi-pillar VW + secret-plane + DR-kit build-out into a focused per-machine credential bootstrap script + template glue. The script generates SSH + GPG keypairs locally, registers them with GitHub via `gh ssh-key add` / `gh gpg-key add`, rewrites chezmoi's git remote, and writes `signingkey` to a chezmoi data file so `modify_dot_gitconfig.local` can read it as static template data instead of via `output` against the deleted `generate-gpg-key.sh`.

Two non-obvious findings drive the plan:

1. **`gh` ssh-key/gpg-key add are NOT idempotent** — they return HTTP 422 and exit 1 when a key is already registered (open feature request: cli/cli #5085). Idempotency must be implemented client-side via `gh ssh-key list --json key,title` + match-before-add. Same pattern for GPG.
2. **`modify_` script templates already give us the right primitive** — `chezmoi:modify-template` marker + `.chezmoi.stdin` lets the rewrite preserve any non-templated lines in the user's local gitconfig. We can drop the `output` call cleanly without losing the modify-behavior the original script had.

**Primary recommendation:** Use ed25519 for SSH (one key, comment = `<hostname>-personal-<YYYYMMDD>`); use `gpg --batch --gen-key` with a parameter file using `%no-protection` and `Key-Type: EDDSA` / `Key-Curve: Ed25519` for GPG (matches `gh`'s armor expectations and produces small modern keys). Implement idempotency with `gh ssh-key list --json` + fingerprint comparison. Write `signingkey` to `~/.config/chezmoi/chezmoi.yaml`'s `data:` section so chezmoi templates pick it up on next `apply` without re-running `init`.

## Standard Stack

### Core

| Library / Tool | Version (target) | Purpose | Why Standard |
|---|---|---|---|
| `gh` (GitHub CLI) | ≥ 2.40 (current Homebrew formula) | Device-flow auth + SSH/GPG key registration | The canonical first-party CLI; provides `auth login` device flow, `ssh-key add`, `gpg-key add`. No reasonable alternative. |
| `gnupg` (GPG) | 2.4.x via `gnupg` Homebrew formula (already present in `packages.yaml` post Phase 0.5 rename from `gpg`) | Per-machine GPG keypair generation + signing | Industry-standard for git commit signing. macOS has no built-in alternative for OpenPGP. |
| `ssh-keygen` | macOS-bundled OpenSSH (no install) | Per-machine SSH keypair generation | macOS-native; nothing else needed. |
| `bitwarden-cli` (`bw`) | Pinned — see "Bitwarden CLI / VaultWarden Compatibility" below | Runtime password vault access (NOT in apply path) | Already in fleet's password-manager ecosystem. Pin is a Pitfall-3 mitigation, not a credential-plane dependency. |
| `chezmoi` | ≥ 2.70.4 (already standardized post-Phase-0) | Dotfiles management | Project's primary tool. |
| `pinentry-mac` | latest (Homebrew formula) | GPG pinentry for macOS | Not strictly needed when `%no-protection` is set, but installed by default with `gnupg` and present on dev Macs. Empty-passphrase path bypasses pinentry entirely (see Pitfall 1). |

### Supporting

| Tool | Version | Purpose | When to Use |
|---|---|---|---|
| `jq` | latest (already in `packages.yaml`) | Parse `gh ssh-key list --json` output for idempotency check | In `setup-credentials.sh` when matching local pubkey against registered keys. |
| `shellcheck` | optional dev | Static-check `setup-credentials.sh` | Before commit — script is user-facing and re-run by the user repeatedly. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| GPG-based commit signing | SSH-based signing (`git config gpg.format ssh`) | Strictly simpler; one keypair instead of two. But: SSH-signed commits become "unverified" when the signing SSH key is removed from GitHub, whereas removed GPG keys retain verification of historical commits. **Rejected for Phase 1** — CONTEXT locked GPG signing and the rewrite of `modify_dot_gitconfig.local` assumes a `.signingkey` (GPG key ID, not SSH file). Revisit only as a future Deferred item. |
| `gpg --quick-gen-key "<uid>" ed25519` | One-shot quick form | Cleaner one-liner, but no `%no-protection` equivalent in the CLI flag set; loopback-pinentry + `--passphrase ''` still required. Parameter file form is more reproducible and self-documenting (the param file becomes a checked-in artifact you can audit). **Recommended: parameter file form.** |
| RSA 4096 GPG | Ed25519 (EDDSA) GPG | RSA: larger keys, slower sign, ubiquitous tooling. Ed25519: small, fast, modern, fully supported by GitHub since 2017. **Recommended: Ed25519** — matches our SSH choice and is current best practice. |
| `setup-credentials.sh` as a `run_once_` chezmoi script | Standalone user-invoked script | `run_once_` would re-fire under taxonomy-axis changes (Pitfall 11) and runs during `apply`, defeating the offline-Stage-1 property. **CONTEXT locked: standalone, not chezmoi script.** |
| `bw` formula version pinning via `@version` syntax | `brew extract` to a local tap, then install pinned formula | Homebrew has no `bitwarden-cli@<ver>` upstream formula. `brew extract` is the canonical way to pin a non-versioned formula. See "Bitwarden CLI / VaultWarden Compatibility." |

**Installation (already in `packages.yaml` post Phase 0.5):**

```
gh, gnupg, jq, chezmoi  → roles.dev.core.brews
bitwarden               → roles.dev.darwin.casks (line 71, GUI app — keep)
```

**To add for Phase 1:**

```
bitwarden-cli (pinned)  → roles.dev.core.brews (with pin mechanism — see SEC-02 section)
```

## Architecture Patterns

### Recommended Project Structure

```
home/
├── .chezmoidata/
│   └── packages.yaml             # SEC-02: bw pin (with version-pair comment)
├── .chezmoiscripts/
│   └── (unchanged — NO new run_once_ scripts; credential setup is explicitly NOT a chezmoi script)
├── modify_dot_gitconfig.local    # SEC-05: rewritten to use chezmoi data (.signingkey)
├── private_dot_ssh/
│   └── config.tmpl               # SEC-07: purpose-based Host aliases
├── scripts/
│   ├── setup-credentials.sh      # NEW: the Stage-2 bootstrap script
│   └── (generate-gpg-key.sh DELETED — SEC-05)
└── ...

docs/
└── credential-plane.md           # NEW (recommended): documents the two-stage flow
                                   #  + bw/VW version pair + rotation playbook
                                   #  + stale-GitHub-key cleanup procedure

bootstrap/                         # OPTIONAL — keep empty/absent; setup-credentials.sh
                                   #  lives in home/scripts/ to ship via chezmoi-managed tree.
                                   #  CONTEXT marks bootstrap-kit as out of scope.
```

**On script location:** `home/scripts/setup-credentials.sh` is the recommended path. Lives in the source tree so it lands at `~/scripts/setup-credentials.sh` on apply (or wherever the `scripts` directive maps). Alternative `bootstrap/` at repo root is more discoverable in a fresh clone but doesn't get distributed by `chezmoi apply` — the user would have to know to navigate the source tree. Since CONTEXT says the user explicitly invokes it post-apply, distribution via apply is preferable.

### Pattern 1: chezmoi `modify_` Template with `.chezmoi.stdin`

**What:** A `modify_dot_gitconfig.local` file with the marker `chezmoi:modify-template` is treated as a template, executed with the current target-file contents available as `.chezmoi.stdin`, and its stdout becomes the new file contents. This is the same primitive the current (deleted-in-Phase-1) `generate-gpg-key.sh` indirectly leveraged via `output`.

**When to use:** When you need to merge chezmoi-managed config with user-local edits the user makes outside chezmoi. For `.gitconfig.local`, this lets the user have local-only includes (work-only proxy settings, machine-specific aliases) that chezmoi preserves through apply.

**Example (recommended Phase 1 shape):**

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

When `.signingkey` is unset (machine where `setup-credentials.sh` hasn't run), the `signingkey` line and `[commit] gpgsign = true` block are simply omitted, leaving git in its default unsigned-commit mode. No silent failure, no broken commit.

If we want to preserve user-local edits beyond what the template produces, the modify-template form can additionally consume `.chezmoi.stdin`. CONTEXT Open Question 8 leaves the exact shape open — recommended is **pure template, not stdin-consuming** for Phase 1 (simplest, matches the original script's "overwrite whole file" semantics). Source: [chezmoi modify_ docs discussion](https://github.com/twpayne/chezmoi/discussions/3996).

### Pattern 2: Idempotency via `gh ssh-key list --json` + fingerprint compare

**What:** `gh ssh-key add` is NOT idempotent (returns 422 on duplicate, exit code 1 — see cli/cli #5085). Workaround: enumerate registered keys first, compare fingerprints, skip if present.

**When to use:** Any time `setup-credentials.sh` runs (every invocation is potentially a re-run).

**Example:**

```bash
# After local keygen at ~/.ssh/personal_ed25519
local_fp=$(ssh-keygen -lf ~/.ssh/personal_ed25519.pub | awk '{print $2}')
registered_fps=$(gh ssh-key list --json key | jq -r '.[].key' | while read pk; do
  echo "$pk" | ssh-keygen -lf - 2>/dev/null | awk '{print $2}'
done)
if echo "$registered_fps" | grep -qFx "$local_fp"; then
  echo "SSH key already registered with GitHub — skipping add"
else
  gh ssh-key add ~/.ssh/personal_ed25519.pub --title "$(hostname)-personal-$(date +%Y%m%d)"
fi
```

For GPG, `gh gpg-key list --json keyId,publicKey` exposes the registered key IDs; compare against the long key ID from `gpg --list-secret-keys --keyid-format LONG`.

### Pattern 3: Per-machine GPG keygen via parameter file

**What:** Unattended GPG generation with no passphrase, using a parameter file. Reproducible, auditable, and the parameter file can be templated by `setup-credentials.sh` with hostname/email/date.

**Example parameter file (heredoc'd by the script, fed to `gpg --batch --gen-key`):**

```
%echo Generating per-machine GPG key (ed25519)
Key-Type: EDDSA
Key-Curve: Ed25519
Key-Usage: sign
Subkey-Type: ECDH
Subkey-Curve: Cv25519
Subkey-Usage: encrypt
Name-Real: James Teague
Name-Email: <email-from-chezmoi-data>
Expire-Date: 0
%no-protection
%commit
%echo Done
```

`%no-protection` skips the pinentry prompt entirely (Pitfall 1 — pinentry-mac in interactive terminal sessions is a common stall point).

After generation, extract the long key ID for the `signingkey` field:

```bash
key_id=$(gpg --list-secret-keys --keyid-format LONG --with-colons "$EMAIL" \
  | awk -F: '/^sec:/ {print $5; exit}')
```

### Pattern 4: Writing `signingkey` to chezmoi data

**What:** `setup-credentials.sh` writes `signingkey: <key_id>` to `~/.config/chezmoi/chezmoi.yaml` under the `data:` section. On next `chezmoi apply`, `modify_dot_gitconfig.local` reads `.signingkey` and renders the signing config.

**Why this file:** It's the user-level chezmoi config, machine-local, not in the source tree, layered on top of `.chezmoidata/*.yaml`. Source: [chezmoi templating docs](https://www.chezmoi.io/user-guide/templating/) — later data overrides earlier, and the user config is the latest layer.

**Caveats:**
- The existing `.chezmoi.toml.tmpl` writes `.toml`, not `.yaml`. If we write `signingkey` to a `.yaml`, chezmoi will read BOTH (config-format is detected by extension). Recommended: write to the same `.toml` the existing init produces, OR write to a separate `~/.config/chezmoi/chezmoi-data.yaml` as a deliberate "set by script" file. **Planner discretion** — I lean toward modifying the existing `.toml` via a small idempotent shell function that detects `[data]` section and sets/replaces `signingkey = "..."`. Avoids a second file the user has to know about.
- After writing, the script SHOULD trigger `chezmoi apply -- modify_dot_gitconfig.local` (or just `chezmoi apply`) so the gitconfig is regenerated immediately, not on next apply.

### Pattern 5: SSH Config Template

```
{{- /* templated host aliases for purpose-based SSH */ -}}
Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/personal_ed25519
  IdentitiesOnly yes

{{- if and (eq .employer "bluebeam") (eq .chezmoi.os "darwin") }}
Host gitlab-bluebeam
  HostName {{ .bluebeamGitlabHost }}
  User git
  IdentityFile ~/.ssh/work_ed25519
  IdentitiesOnly yes
{{- end }}
```

`IdentitiesOnly yes` is important — without it, ssh-agent offers ALL loaded keys to the server, which can trigger MaxAuthTries failures on hosts where multiple keys are registered to different accounts (real failure mode for `github-personal` vs other GitHub accounts).

The `bluebeamGitlabHost` chezmoi data field and `employer` field are out of script scope per CONTEXT — they're set by the user during `chezmoi init` prompts (Phase 0 added employer-axis follow-up #6). The Phase 1 SSH config template reads them but Phase 1 does not own creating the prompts.

### Anti-Patterns to Avoid

- **Templating `bw` calls into chezmoi apply-time files.** Defeats the whole pivot. Grep gate (SEC-15 proposed) enforces this.
- **Generating GPG keys interactively (`gpg --full-gen-key`).** Stalls on tty + pinentry. Parameter file + `%no-protection` is the path.
- **Setting `signingkey` via `git config --global`.** Bypasses chezmoi; next apply overwrites it. The chezmoi-data path is the right primitive.
- **Re-running `gh auth login` if already authed.** It clobbers existing tokens. Detect with `gh auth status`; only run if not authed or scopes insufficient (`admin:public_key`, `admin:gpg_key`, `repo`).
- **Generating fresh SSH/GPG without checking GitHub registration first.** Without an idempotency gate, every re-run produces a new local keypair that fails registration (already in use), and you end up with stale local key files. Check-before-generate is the right ordering: (1) does local file exist? (2) is the corresponding pubkey already in GitHub? (3) generate iff both no.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| GitHub device-flow auth | Custom OAuth dance, PAT prompts | `gh auth login --hostname github.com --git-protocol ssh --web` | Device flow is a security primitive; rolling your own is a vulnerability surface. `gh` handles refresh, scope upgrades, and credential helper integration. |
| SSH pubkey upload to GitHub | `curl` + GitHub API + token mgmt | `gh ssh-key add ~/.ssh/personal_ed25519.pub --title <hostname>-personal-<date>` | `gh` handles auth context, API endpoint changes, error reporting. |
| GPG pubkey upload to GitHub | `curl` + API + armor mgmt | `gh gpg-key add` (from stdin via `gpg --armor --export | gh gpg-key add -` per cli/cli #6528 pattern) | Same — first-party CLI is the right primitive. |
| Idempotent pubkey check | Local cache of "did I register this?" | Live `gh ssh-key list --json` + fingerprint compare against local | GitHub is the source of truth. A local cache can lie if the user removes a key via the web UI. |
| GPG ID extraction from `--list-secret-keys` | Regex of human-readable output | `--with-colons` parseable output + awk on the `sec:` row, field 5 | Colon output is documented as the machine-readable form; human format changes between gpg minor versions. |
| `.gitconfig.local` content merge | sed/awk against current file contents | chezmoi `modify_` template + (optionally) `.chezmoi.stdin` | First-party primitive; respects chezmoi's idempotency model. |
| Rewriting chezmoi git remote | `cd $(chezmoi source-path) && git remote set-url ...` | `chezmoi git -- remote set-url origin git@github-personal:JamesTeague/dotfiles.git` | `chezmoi git --` is the documented canonical wrapper; works regardless of source-dir layout changes. |
| Brew formula version pin | Editing `Cellar` paths, copying old `.rb` files | `brew extract bitwarden-cli <user>/local --version <ver>` then install from local tap | `brew extract` is the documented pinning mechanism; reversible. See "Bitwarden CLI / VaultWarden Compatibility." |

**Key insight:** Every credential-plane primitive in this phase has a first-party tool. The script's job is glue — gating, idempotency, user feedback — not custom protocol implementation.

## Common Pitfalls

### Pitfall 1: pinentry-mac stalls unattended GPG keygen

**What goes wrong:** `gpg --batch --gen-key` without `%no-protection` triggers pinentry-mac to prompt for a passphrase. In a script context (even an interactive terminal session), pinentry can hang on the agent socket if gpg-agent state is inconsistent.

**Why it happens:** gpg-agent is shared across terminal sessions; pinentry-mac is GUI-backed on macOS. The agent may try to display a dialog while the script's controlling terminal can't surface it.

**How to avoid:** Always include `%no-protection` in the parameter file. Empty passphrase via CLI flag (`--passphrase ''`) requires `--pinentry-mode loopback` to take effect (gpg ≥ 2.1). Parameter-file form is cleaner.

**Warning signs:** Script hangs at "Generating per-machine GPG key" with no progress for > 30s. `ps aux | grep pinentry` shows a hung pinentry-mac process.

### Pitfall 2: `gh ssh-key add` / `gh gpg-key add` 422-exit-1 on duplicate

**What goes wrong:** Re-running `setup-credentials.sh` after a successful first run causes 422 errors and non-zero exits, breaking the idempotency contract.

**Why it happens:** Open feature request cli/cli #5085 — no `--ignore-existing` flag exists. Both commands return exit 1 on duplicate.

**How to avoid:** Implement client-side idempotency (Pattern 2 above). Check registration before add. If add fails with stderr matching "key is already in use", treat as success (defense-in-depth). The cli/cli #6271 discussion confirms the operation often actually succeeds despite the error — but treat success only when the fingerprint check confirms it.

**Warning signs:** Second-run output shows "HTTP 422" or "key already in use." Exit code 1 from a re-run that should be a no-op.

### Pitfall 3: Bitwarden CLI / VaultWarden version drift

**What goes wrong:** Newer `bw` CLI versions (≥ 2025.12.0 confirmed) call API endpoints / expect response fields that older VaultWarden servers don't return. Authentication or unlock fails with cryptic errors like "User Decryption Options are required."

**Why it happens:** `bw` is built against upstream Bitwarden server. VaultWarden re-implements the API and lags adoption of new endpoints by weeks-to-months.

**How to avoid:** Pin `bw` to a known-good version paired with the live VaultWarden server. For VW 1.36.0, `bw` 2025.11.0 is the most recent known-good ceiling per vaultwarden#6729 (the breakage report was against 2025.12.0). Document the pair in `packages.yaml` comment + `docs/credential-plane.md`. When VW server is upgraded, bump the pin in lockstep.

**Warning signs:** `bw login` succeeds but `bw unlock` fails. `bw list items` returns "Vault is locked" repeatedly. Error messages mentioning "Decryption Options" or KDF fields.

### Pitfall 4: `chezmoi apply` reads a `bw` shell-out via template

**What goes wrong:** Someone adds a template that calls `bw` via `output` or `bitwardenAttachment` for "just one thing." Apply now depends on VW reachability.

**Why it happens:** Convenience. A tiny secret retrieval feels harmless.

**How to avoid:** Structural grep gate (SEC-15 proposed). Run on every Phase 1 verification pass. Fail loud if any apply-time path references `bitwarden`, `bw `, `{{ bitwarden`, or `bitwardenAttachment`.

**Warning signs:** New template using `bitwarden*` template functions. PR/commit adding `bw ` invocations to `.chezmoiscripts/`.

### Pitfall 5: `signingkey` written to file chezmoi doesn't read

**What goes wrong:** Script writes `signingkey` to `~/.config/chezmoi/chezmoi.yaml`, but the existing `init` produced `chezmoi.toml`. chezmoi might read only one of them depending on `--config-format` and discovery order.

**Why it happens:** chezmoi auto-detects config format by extension; if both `chezmoi.toml` and `chezmoi.yaml` exist, behavior is non-obvious.

**How to avoid:** Write to the same file the existing init produced (`.toml`). Use a small shell function that idempotently sets `signingkey = "..."` under `[data]`. Alternative: `chezmoi state set --bucket=... ` but that's overcomplicated for this case.

**Warning signs:** `chezmoi data | grep signingkey` returns empty after script runs. `chezmoi apply -v modify_dot_gitconfig.local` shows the template missing `.signingkey`.

### Pitfall 6: SSH config with multiple agent keys + IdentitiesOnly missing

**What goes wrong:** `ssh -T git@github-personal` fails with "Too many authentication failures" because ssh-agent offers every loaded key to GitHub, exhausting MaxAuthTries before the right one.

**Why it happens:** Default ssh behavior is to try every agent-loaded identity. With multiple GitHub-registered keys across machines and other services, the work Mac can easily hit this.

**How to avoid:** `IdentitiesOnly yes` in every Host block. Explicit `IdentityFile` per alias.

**Warning signs:** `ssh -vT git@github-personal` shows multiple "Offering public key" lines before failure. Authentication eventually succeeds on hosts with `MaxAuthTries 10` but fails on stricter ones.

### Pitfall 7: Remote rewrite happens before key is registered

**What goes wrong:** `setup-credentials.sh` rewrites chezmoi's remote to `git@github-personal:...` before the SSH key is actually registered and `ssh-agent` knows about it. Subsequent `chezmoi git pull` fails.

**Why it happens:** Step ordering in the script.

**How to avoid:** Remote rewrite is the LAST step in `setup-credentials.sh`, after both SSH and GPG paths have completed successfully. Before rewriting, do a smoke test: `ssh -T git@github-personal 2>&1 | grep -q "successfully authenticated"`.

**Warning signs:** First `chezmoi update` or `chezmoi git pull` after Stage 2 fails with `Permission denied (publickey)`.

### Pitfall 8: GPG signing fails because gpg-agent doesn't know the new key

**What goes wrong:** Key is generated, GitHub registration succeeds, `signingkey` is in chezmoi data, but `git commit -S` still fails because gpg-agent in the current shell doesn't see the new secret key.

**Why it happens:** gpg-agent caches its keyring state per-session. New keys created via `--batch --gen-key` are added immediately, but a `gpg-connect-agent reloadagent /bye` is sometimes needed if you were using GPG in the same session pre-script.

**How to avoid:** `gpg-connect-agent reloadagent /bye` after keygen. Smoke-test signing inside the script with a throwaway test commit before declaring success.

**Warning signs:** `git commit -S` says "gpg: signing failed: No secret key" despite `gpg --list-secret-keys` showing the key.

### Pitfall 9: VM verification target is stateful between runs

**What goes wrong:** First-run verification leaves credentials, gpg state, chezmoi state on the VM. Second run isn't a true "fresh boot" test.

**Why it happens:** Verifying idempotency / rotation flags requires the dirty state, but verifying first-run requires clean state. Conflating them produces false confidence.

**How to avoid:** Restore `vanilla-fresh-boot-pre-chezmoi` snapshot between distinct verification scenarios. Document which scenarios require fresh state vs which test rerun behavior. Recommended: verify (a) fresh Stage 1 + Stage 2, (b) re-run no-op idempotency, (c) `--rotate-*` flag, (d) structural grep gate. Snapshot restore between (a) and (b)? No — that's the point of idempotency. Restore between (a) and (c)? Yes — rotation should also work on a fresh-then-rotated machine.

**Warning signs:** "It worked on the second run but failed on the third" type symptoms. Drift between local and CI verification.

### Pitfall 10: Stale GitHub-side keys accumulate

**What goes wrong:** Over time, decommissioned machines leave their keys on GitHub. If one of those machines is compromised, the attacker has a valid SSH key for the personal account.

**Why it happens:** Manual cleanup is easy to defer. `setup-credentials.sh` doesn't know which machines are alive.

**How to avoid:** Document a quarterly cleanup procedure in `docs/credential-plane.md`. `gh ssh-key list --json id,title,createdAt` + `gh gpg-key list` produces an audit-friendly inventory. Title convention `<hostname>-personal-<YYYYMMDD>` makes stale entries identifiable by hostname.

**Warning signs:** `gh ssh-key list` count growing without bound. Old hostnames you don't recognize.

## Code Examples

Verified patterns from official sources.

### Example 1: Unattended GPG keygen with Ed25519, empty passphrase

```bash
# Source: https://www.gnupg.org/documentation/manuals/gnupg/Unattended-GPG-key-generation.html
gpg --batch --gen-key <<EOF
%echo Generating per-machine GPG key
Key-Type: EDDSA
Key-Curve: Ed25519
Key-Usage: sign
Subkey-Type: ECDH
Subkey-Curve: Cv25519
Subkey-Usage: encrypt
Name-Real: ${GIT_NAME}
Name-Email: ${GIT_EMAIL}
Expire-Date: 0
%no-protection
%commit
%echo Done
EOF

# Extract long key ID (machine-parseable colon output)
KEY_ID=$(gpg --list-secret-keys --keyid-format LONG --with-colons "${GIT_EMAIL}" \
  | awk -F: '/^sec:/ {print $5; exit}')
```

### Example 2: SSH ed25519 keygen + register with idempotency

```bash
# Source: https://man7.org/linux/man-pages/man1/ssh-keygen.1.html
#         https://cli.github.com/manual/gh_ssh-key_add
KEY_FILE="${HOME}/.ssh/personal_ed25519"
KEY_TITLE="$(hostname -s)-personal-$(date +%Y%m%d)"

if [[ ! -f "${KEY_FILE}" ]]; then
  ssh-keygen -t ed25519 -N "" -C "${KEY_TITLE}" -f "${KEY_FILE}"
fi

LOCAL_FP=$(ssh-keygen -lf "${KEY_FILE}.pub" | awk '{print $2}')

# Idempotency: fingerprint-compare against registered set
REGISTERED=$(gh ssh-key list --json key --jq '.[].key' 2>/dev/null \
  | while read -r pk; do echo "$pk" | ssh-keygen -lf - 2>/dev/null | awk '{print $2}'; done)

if echo "${REGISTERED}" | grep -qFx "${LOCAL_FP}"; then
  echo "[skip] SSH key already registered: ${LOCAL_FP}"
else
  gh ssh-key add "${KEY_FILE}.pub" --title "${KEY_TITLE}" --type authentication
fi
```

### Example 3: GPG pubkey export + register with idempotency

```bash
# Source: https://cli.github.com/manual/gh_gpg-key_add  (armor required per cli/cli #6528)
REGISTERED_IDS=$(gh gpg-key list --json keyId --jq '.[].keyId' 2>/dev/null)

if echo "${REGISTERED_IDS}" | grep -qFx "${KEY_ID}"; then
  echo "[skip] GPG key already registered: ${KEY_ID}"
else
  gpg --armor --export "${KEY_ID}" | gh gpg-key add - --title "${KEY_TITLE}"
fi
```

### Example 4: Rewrite chezmoi's git remote (canonical form)

```bash
# Source: https://www.chezmoi.io/user-guide/command-overview/
chezmoi git -- remote set-url origin git@github-personal:JamesTeague/dotfiles.git

# Verify
chezmoi git -- remote -v
```

### Example 5: Brew formula version pin via local tap (for `bw` SEC-02)

```bash
# Source: https://nelson.cloud/how-to-install-a-specific-version-of-a-homebrew-package-with-brew-extract/
# One-time setup (per machine):
brew tap-new "${USER}/local"
brew extract --version=2025.11.0 bitwarden-cli "${USER}/local"
brew install "${USER}/local/bitwarden-cli@2025.11.0"
brew pin bitwarden-cli@2025.11.0

# In packages.yaml — RECOMMENDED: don't put the brew-extract in packages.yaml directly
# (it's a one-time-per-machine setup). Document the procedure in docs/credential-plane.md
# and leave packages.yaml referencing `bitwarden-cli` formula with a comment:
#
#   - 'bitwarden-cli' # PIN: 2025.11.0 against VaultWarden 1.36.0 — see docs/credential-plane.md
#
# A run_once_ script could automate the extract+install if we want it idempotent on fresh
# machines; planner discretion. But: a run_once_ for bw pin re-introduces an apply-time
# dependency on the local-tap state, which is more surface than the simple manual
# procedure documented for the few machines in the fleet.
```

### Example 6: Idempotent `signingkey` write to chezmoi config

```bash
# Source: https://www.chezmoi.io/reference/configuration-file/
# Idempotently set [data].signingkey in ~/.config/chezmoi/chezmoi.toml
CHEZMOI_CFG="${HOME}/.config/chezmoi/chezmoi.toml"

if grep -q '^\s*signingkey\s*=' "${CHEZMOI_CFG}"; then
  # Replace existing value
  sed -i.bak "s|^\s*signingkey\s*=.*|  signingkey = \"${KEY_ID}\"|" "${CHEZMOI_CFG}"
else
  # Append under [data] (insert after [data] line)
  awk -v kid="${KEY_ID}" '
    /^\[data\]/ { print; print "  signingkey = \"" kid "\""; next }
    { print }
  ' "${CHEZMOI_CFG}" > "${CHEZMOI_CFG}.new" && mv "${CHEZMOI_CFG}.new" "${CHEZMOI_CFG}"
fi

# Trigger re-render of gitconfig immediately
chezmoi apply ~/.gitconfig.local
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Canonical GPG identity in centralized vault (VW) | Per-machine GPG identities registered to one GitHub account | 2026-06-04 (this project's pivot) | Eliminates rotation fanout; multiple verified keys per account is GitHub-supported and unremarkable. |
| `output` template function calling shell script for runtime data | chezmoi data file populated by post-apply script | 2026-06-04 (SEC-05 carryover) | Decouples apply-time templates from runtime side effects; restores `chezmoi apply` to a pure idempotent operation. |
| RSA 4096 for GPG | Ed25519 (EDDSA) for GPG | ~2018 (GitHub support) | Smaller keys, faster signing, modern crypto. Matches our SSH choice. |
| `gpg --full-gen-key` (interactive) | `gpg --batch --gen-key` with parameter file + `%no-protection` | gpg 2.1+ (loopback pinentry) | Unattended, scriptable, reproducible. |
| HTTPS clone with PAT in git credential helper | SSH clone with per-purpose Host alias | 2022 (GitHub SSH commit signing GA, but applies to clone too) | No long-lived PATs in credential helpers; clone auth is SSH key. |
| `git config --global user.signingkey` set manually | chezmoi-data-driven signingkey rendered into `.gitconfig.local` | This phase | Survives machine rebuild; no out-of-band manual config drift. |

**Deprecated / outdated:**
- `gpg --gen-key` (non-`--full`, non-`--quick`) — soft-deprecated in favor of `--quick-gen-key` or `--batch --gen-key`.
- `mas-cli` for App Store apps via `mas install` without Apple-ID prompt — already mitigated in Phase 0 with `/Applications/<App>.app` pre-check (not Phase 1's problem but related to "fresh VM" verification).

## Open Questions

1. **`signingkey` chezmoi-data target file: `chezmoi.toml` vs separate `chezmoi-data.yaml`.**
   - What we know: chezmoi reads both, later overrides earlier; format detected by extension.
   - What's unclear: whether modifying the existing `chezmoi.toml` interacts cleanly with `promptStringOnce`-tracked fields.
   - Recommendation: write to existing `chezmoi.toml`'s `[data]` section. Verify in Plan 1 by inspecting current `~/.config/chezmoi/chezmoi.toml` on Mac personal post-init and confirming `[data]` is mutable without re-prompt.

2. **`bw` pin enforcement: `run_once_` script vs documented manual procedure.**
   - What we know: `brew extract` works; `bitwarden-cli@<ver>` formulas don't exist upstream.
   - What's unclear: whether the fleet's 3-4 dev machines warrant automation here, or whether doc + manual is cleaner.
   - Recommendation: doc + manual for Phase 1. Revisit if Lonestar / future machines make manual painful.

3. **VaultWarden 1.36.0 ↔ `bw` known-good pin: 2025.11.0 confirmed?**
   - What we know: 2025.12.0 broken against VW 1.35.2 per vaultwarden#6729. 2025.11.0 is the suggested downgrade target.
   - What's unclear: whether 1.36.0 (the live server in this fleet) fixed the API surface to accept 2025.12.0. The vaultwarden#6729 issue is against 1.35.2.
   - Recommendation: planner verifies empirically — run `bw login` + `bw unlock` against the live VW 1.36.0 with both 2025.11.0 and 2025.12.0; pin to whichever works. Document the test in the verification artifact.

4. **Rotation flag shape.**
   - What we know: CONTEXT leaves this open; options include `--rotate`, `--rotate-ssh` / `--rotate-gpg` / `--rotate-all`.
   - Recommendation: `--rotate-ssh`, `--rotate-gpg`, `--rotate-all` for clarity. `--rotate-all` is a convenience for both. Default invocation does not rotate.

5. **GitHub-side stale key cleanup: manual or scripted?**
   - What we know: `gh ssh-key delete <id>` + `gh gpg-key delete <id>` exist. Listing by title prefix is straightforward.
   - Recommendation: manual + documented playbook. The script's role is per-machine; fleet-wide cleanup is a fleet operation that doesn't belong in `setup-credentials.sh`.

6. **`modify_dot_gitconfig.local` shape: pure template (no `output`) vs stdin-consuming modify-template.**
   - What we know: both work. Original used `output`. New rewrite needs to drop `output`.
   - Recommendation: pure template form (no `.chezmoi.stdin` consumption). The original semantics were "overwrite the whole file from script output" — pure template matches that. If user-local `.gitconfig.local` edits ever become a use case, switch to stdin form then.

7. **Where script should be located: `home/scripts/` vs `bootstrap/` vs other.**
   - Recommendation: `home/scripts/setup-credentials.sh`. Distributes via chezmoi apply. User runs `~/scripts/setup-credentials.sh` (or equivalent target path under chezmoi's mapping).

8. **`employer` data field for SSH config gating: introduced in Phase 0 follow-ups or Phase 1?**
   - What we know: STATE.md Phase 0 follow-up #6 mentions employer-axis design as Phase 0 escalation.
   - What's unclear: whether Phase 0 actually lands the `employer` prompt before Phase 1 needs it.
   - Recommendation: planner checks the Phase 0 final state of `.chezmoi.toml.tmpl`. If `employer` is not yet a prompt, Phase 1 SSH config template uses a different gating mechanism (e.g., presence of `~/.ssh/work_ed25519` file via `lookPath`-style check, OR the work Mac sets a `hasWorkGit: true` data flag manually post-init) and notes the cleanup-after-Phase-0-lands handoff. Document explicitly.

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | Bash + chezmoi-internal templating; structural greps; live SSH/git smoke tests on VM |
| Config file | none — Wave 0 of Phase 1 establishes test scripts under `.planning/phases/01-credential-plane/checks/` (pattern established by Phase 0.5 Plan 01) |
| Quick run command | `bash .planning/phases/01-credential-plane/checks/quick.sh` (structural greps + template-render-only checks; no network) |
| Full suite command | `bash .planning/phases/01-credential-plane/checks/full.sh` (quick + VM-driven Stage 1+2 + idempotency + rotation) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| SEC-02 | `bw` formula pinned; pin documented | structural | `grep -E "bitwarden-cli.*PIN" home/.chezmoidata/packages.yaml && test -f docs/credential-plane.md` | ❌ Wave 0 |
| SEC-05 (part 1) | `home/scripts/generate-gpg-key.sh` is absent | structural | `! test -e home/scripts/generate-gpg-key.sh` | ❌ Wave 0 |
| SEC-05 (part 2) | `modify_dot_gitconfig.local` uses chezmoi data not `output` | structural | `! grep -q "output.*generate-gpg-key" home/modify_dot_gitconfig.local && grep -q "\.signingkey" home/modify_dot_gitconfig.local` | ❌ Wave 0 |
| SEC-07 | `private_dot_ssh/config.tmpl` exists with purpose-based aliases | structural | `grep -q "Host github-personal" home/private_dot_ssh/config.tmpl` | ❌ Wave 0 |
| SEC-08 | After Stage 2, `chezmoi git -- remote -v` reports `git@github-personal:...` | smoke (VM) | `ssh jteague@10.211.55.4 'chezmoi git -- remote get-url origin | grep -q "^git@github-personal:"'` | ❌ Wave 0 |
| SEC-09 | `git commit -S --allow-empty` produces a verified signature | smoke (VM) | `ssh jteague@10.211.55.4 'cd /tmp/verify-repo && git commit -S --allow-empty -m phase1 && git log --show-signature -1 | grep -E "Good signature|gpg: Signature made"'` | ❌ Wave 0 |
| SEC-10 | `ssh -T git@github-personal` returns GitHub welcome | smoke (VM) | `ssh jteague@10.211.55.4 'ssh -T git@github-personal 2>&1 | grep -q "successfully authenticated"'` (exit 1 is expected from `ssh -T`; grep result is the assertion) | ❌ Wave 0 |
| SEC-11 (proposed) | `setup-credentials.sh` exists, executable, NOT a chezmoi `run_once_` | structural | `test -x home/scripts/setup-credentials.sh && ! ls home/.chezmoiscripts/*setup-credentials* 2>/dev/null` | ❌ Wave 0 |
| SEC-12 (proposed) | `--rotate-*` flags documented + functional | smoke (VM) | `ssh jteague@10.211.55.4 'bash ~/scripts/setup-credentials.sh --help \| grep -E "(rotate-ssh\|rotate-gpg\|rotate-all)"'` | ❌ Wave 0 |
| SEC-13 (proposed) | After Stage 2, `~/.ssh/personal_ed25519` exists and is ed25519 | smoke (VM) | `ssh jteague@10.211.55.4 'test -f ~/.ssh/personal_ed25519 && ssh-keygen -lf ~/.ssh/personal_ed25519.pub \| grep -q "ED25519"'` | ❌ Wave 0 |
| SEC-14 (proposed) | After Stage 2, GPG secret key present and matches `signingkey` in chezmoi data | smoke (VM) | `ssh jteague@10.211.55.4 'KID=$(chezmoi data \| jq -r .signingkey); gpg --list-secret-keys --keyid-format LONG \| grep -q "$KID"'` | ❌ Wave 0 |
| SEC-15 (proposed) | Structural VW-independence: zero `bw `/`bitwarden`/`{{ bitwarden` in apply-time paths | structural | `! grep -rEn "(\\\\bbw \\b\|bitwardenAttachment\|\\\\{\\\\{ *bitwarden)" home/ --include="*.tmpl" && ! grep -rEn "(\\\\bbw \\b\|bitwarden)" home/.chezmoiscripts/` (with permitted exception: `packages.yaml` line referencing `bitwarden` cask + `bitwarden-cli` formula are OK because they are package install names, not template calls; comment lines in `setup-credentials.sh` referencing the design also OK) | ❌ Wave 0 |
| SEC-16 (proposed) | End-to-end VM verification produces all of: signed commit, SSH auth, remote-rewrite, idempotent re-run | smoke (VM) | composite script `checks/vm-e2e.sh` orchestrating snapshot restore + Stage 1 + Stage 2 + verifications + re-run + assert no-op | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `bash .planning/phases/01-credential-plane/checks/quick.sh` — structural-only, fast (< 5s), runs on every commit in Phase 1.
- **Per wave merge:** `bash .planning/phases/01-credential-plane/checks/full.sh` — adds VM-driven smoke (Stage 1, Stage 2, verifications). Runs at wave merge points and before `/gsd:verify-work`.
- **Phase gate:** Full suite green on the VM (snapshot restored first) AND structural greps green on the local source tree. Then `/gsd:verify-work` runs.

**Note on VM verification cadence:** VM full-suite runs take 5-15 min (snapshot restore + brew install during Stage 1). NOT a per-commit check. Plans should batch their VM verifications at wave merge.

### Wave 0 Gaps

- [ ] `.planning/phases/01-credential-plane/checks/lib.sh` — shared helpers (color output, assertion macros) — adapt from `.planning/phases/00.5-audit-documentation/checks/lib.sh`.
- [ ] `.planning/phases/01-credential-plane/checks/quick.sh` — structural greps for SEC-02, SEC-05, SEC-07, SEC-11, SEC-13 (file existence), SEC-15.
- [ ] `.planning/phases/01-credential-plane/checks/full.sh` — quick + VM smokes (SEC-08, SEC-09, SEC-10, SEC-12, SEC-13 keypair check, SEC-14, SEC-16).
- [ ] `.planning/phases/01-credential-plane/checks/vm-e2e.sh` — composite VM orchestration script (snapshot restore via Parallels CLI `prlctl snapshot-switch`, Stage 1 invocation, Stage 2 invocation, verifications, idempotency re-run).
- [ ] `.planning/phases/01-credential-plane/checks/parallels-helpers.sh` — `prlctl`-based snapshot management (verify `prlctl` available, snapshot UUID resolution, restore + wait-for-boot).

*Framework install commands: none — bash + ssh + (host-side) `prlctl` are all macOS-available primitives. VM uses standard tooling that Stage 1 itself installs.*

## Sources

### Primary (HIGH confidence)

- [chezmoi command overview](https://www.chezmoi.io/user-guide/command-overview/) — `chezmoi git --` canonical wrapper.
- [chezmoi configuration file](https://www.chezmoi.io/reference/configuration-file/) — config format detection, data layering.
- [chezmoi templating](https://www.chezmoi.io/user-guide/templating/) — `.chezmoidata` precedence rules.
- [chezmoi manage different files](https://www.chezmoi.io/user-guide/manage-different-types-of-file/) — `modify_` prefix semantics.
- [chezmoi discussion #3996](https://github.com/twpayne/chezmoi/discussions/3996) — full examples of modifying part of a file with `modify_`.
- [GnuPG: Unattended GPG key generation](https://www.gnupg.org/documentation/manuals/gnupg/Unattended-GPG-key-generation.html) — parameter file format, `%no-protection`.
- [GnuPG: OpenPGP Key Management](https://gnupg.org/documentation/manuals/gnupg/OpenPGP-Key-Management.html) — supported algorithms including ed25519, future-default semantics.
- [GitHub CLI: gh ssh-key add](https://cli.github.com/manual/gh_ssh-key_add) — flags, `--title`, `--type`.
- [GitHub CLI: gh gpg-key add](https://cli.github.com/manual/gh_gpg-key_add) — flags, key file arg.
- [GitHub CLI #6528](https://github.com/cli/cli/pull/6528) — `gh gpg-key add` requires armored format starting with `-----BEGIN PGP PUBLIC KEY BLOCK-----`.
- [GitHub Docs: About commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification) — multiple verified keys per account explicitly supported; no limit.
- [ssh-keygen(1) man page](https://man7.org/linux/man-pages/man1/ssh-keygen.1.html) — `-t ed25519`, `-N ""`, `-C`, `-f`.

### Secondary (MEDIUM confidence — verified with official sources)

- [GitHub CLI #5085](https://github.com/cli/cli/issues/5085) — confirmed open: `gh ssh-key add` and `gh gpg-key add` are NOT idempotent; no `--ignore-existing` flag.
- [GitHub CLI #5299](https://github.com/cli/cli/issues/5299) — spurious auth error when SSH key already registered (confirms 422 behavior).
- [GitHub CLI discussion #6271](https://github.com/cli/cli/discussions/6271) — HTTP 422 + login-succeeded confusion pattern.
- [vaultwarden #6729](https://github.com/dani-garcia/vaultwarden/issues/6729) — Bitwarden CLI 2025.12.0 vs VW 1.35.2 incompat; 2025.11.0 known-good downgrade. Pair with VW 1.36.0 needs empirical re-verification.
- [Nelson Figueroa: brew extract for version pinning](https://nelson.cloud/how-to-install-a-specific-version-of-a-homebrew-package-with-brew-extract/) — canonical Homebrew formula pinning pattern.
- [Toby WF: Signing commits with SSH instead of GPG](https://tobywf.com/2026/01/ditch-gnupg-signing-commits-with-ssh/) — context for the GPG-vs-SSH-signing tradeoff (alternative considered but rejected per CONTEXT).
- [Ken Muse: Comparing GitHub Commit Signing Options](https://www.kenmuse.com/blog/comparing-github-commit-signing-options/) — corroborates verification persistence differences.

### Tertiary (LOW confidence — flagged for empirical validation in Plan)

- VaultWarden 1.36.0 ↔ `bw` exact pin: 2025.11.0 is the only confirmed-good ceiling, but against a different (1.35.2) VW server. Plan-time empirical check required (Open Question 3).
- Exact behavior of writing to `[data]` in `chezmoi.toml` already populated by `promptStringOnce` keys — verify by inspection of live config on Mac personal during planning (Open Question 1).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — `gh`, `gnupg`, `ssh-keygen` are well-documented; algorithm choices (ed25519 both sides) are current best practice per multiple 2026 sources.
- Architecture: HIGH — chezmoi `modify_` + `.chezmoidata` layering is documented; pure-template form for rewrite is straightforward; the script-as-glue pattern is conventional.
- Pitfalls: HIGH on `gh` idempotency (cli/cli #5085 confirmed), HIGH on `pinentry-mac` stall (well-known), MEDIUM on `bw`/VW exact pin (compat matrix is empirical-by-fleet).
- Idempotency design: HIGH — fingerprint-compare is the documented workaround for the missing `--ignore-existing` flag.
- VM verification orchestration: MEDIUM — host-side `prlctl` is well-documented but exact snapshot UUID resolution may differ across Parallels versions; planner verifies in Plan 0/Wave 0.

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (30 days; `gh` CLI and `gpg` move slowly, but `bw`/VW compat is a moving target — re-verify the pin before any production work after VW server upgrade).
