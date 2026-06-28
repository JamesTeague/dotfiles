# Phase 1: Credential Plane — Context

**Gathered:** 2026-06-04
**Status:** Ready for planning
**Source:** Discussion-first session 2026-06-04 (continuation of Phase 0 close 2026-06-03)
**Supersedes:** ROADMAP.md Phase 1 framing ("VaultWarden + Secret Plane + Bootstrap Kit"). Architecture pivoted during this session — VW comes off the credential-plane critical path; bootstrap kit deleted from scope.

<domain>
## Phase Boundary

Deliver a per-machine credential bootstrap flow such that a fresh Mac, after running the chezmoi one-liner and an explicit post-apply script, ends up with working `git commit -S` and `ssh -T git@github-personal` — without any credential synced from a central store, and without VaultWarden being on the apply-time critical path.

In scope:
- Public dotfiles repo (revert from Phase 0's "going private" pending-state)
- `setup-credentials.sh` (idempotent post-apply script — generates and registers per-machine keys)
- `~/.ssh/config` chezmoi template (purpose-based host aliases)
- `modify_dot_gitconfig.local` rewrite (replaces `generate-gpg-key.sh` dependency — SC #5 carryover from Phase 0)
- Delete `home/scripts/generate-gpg-key.sh`
- Verification: signed-commit test, structural VW-independence check, VM-based fresh-install drill

Out of scope:
- VaultWarden auto-unlock as part of `chezmoi apply` (no inline VW template calls — VW gets installed via packages, used at runtime for passwords, but not on the credential-plane bootstrap path)
- Age-encrypted bootstrap kit (deleted from Phase 1 — credential plane uses no centrally-stored regenerable material)
- Age identity backup ceremony (no kit means no age identity to back up)
- Vault-offline drill as originally framed (collapses to structural check: prove apply does not call VW)
- Bluebeam GitLab work key generation / registration (manual, hand-generated on work Mac, not in script scope)
- Canonical GPG migration path (deferred; not needed unless a real use case emerges — see "Deferred / Future" below)
</domain>

<decisions>
## Architecture (Locked)

### Two-stage bootstrap

`chezmoi apply` and credential setup are separate steps. `apply` never reads from VW; it does package install, shell/editor/tool config, and writes templates that *reference* credential paths without depending on those paths being populated.

```
Stage 1 (no prompts, offline-safe):
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply JamesTeague/dotfiles
  # — installs chezmoi, clones public repo, runs apply, installs packages
  #   (including bw, gh, gpg via Homebrew), writes shell+editor+tool config

Stage 2 (prompts, one-time per machine):
  setup-credentials.sh
  # — gh auth login (device flow)
  # — ssh-keygen for personal key
  # — gh ssh-key add <pubkey>
  # — gpg --batch --gen-key for personal GPG key
  # — gh gpg-key add <pubkey>
  # — write git signingkey (or trigger re-apply of modify_dot_gitconfig.local)
  # — rewrite chezmoi remote: git@github-personal:JamesTeague/dotfiles.git
```

Rotation = re-run `setup-credentials.sh` on each machine independently. No central rotation event fanout.

### Per-machine, regenerable keys

| Credential | Stored centrally? | Generation | Registration |
|---|---|---|---|
| Personal SSH key | NO | `ssh-keygen` on each machine | `gh ssh-key add` |
| Personal GPG key | NO | `gpg --batch --gen-key` on each machine | `gh gpg-key add` |
| Bluebeam GitLab work SSH key | NO | Hand-generated on work Mac (out of script scope) | Manual via GitLab UI / Bluebeam-internal flow |
| Application passwords | YES (VaultWarden) | N/A | N/A |
| Non-regenerable API tokens | YES (VaultWarden) | N/A | N/A |

Each machine ends up with its own SSH + GPG keypair. Commit signing identity is per-machine (multiple verified keys per GitHub account). Lost / compromised machine → revoke that one machine's keys via GitHub UI; other machines unaffected. No "rotate everywhere" pain.

### Passphrases

Empty passphrases on both SSH and GPG keys. Defense rests on FileVault + macOS user login. Matches Teague's existing practice.

### VaultWarden's role in Phase 1

VW gets installed (`bw` Homebrew formula, pinned to a version compatible with the live VaultWarden 1.36.0 server — Pitfall 3 mitigation). VW is used at runtime for password lookups / API token retrieval *outside* the chezmoi apply path. Apply itself does not call VW. VW going down does not break `chezmoi apply`, `git commit -S`, or `ssh -T`.

### Public dotfiles repo

Reverted to public. The 2026-05-27 design decision "going private" was made before this session's pivot. With no VW URL, employer name, machine taxonomy, or encrypted bootstrap kit in templates that *require* privacy, the public repo enables a true `curl ... | sh` Stage 1 with no auth prompts. (Repo IS already public — no GitHub-side change needed.)

### `modify_dot_gitconfig.local` rewrite (SC #5 carryover from Phase 0)

Current template (`home/modify_dot_gitconfig.local`) sources `home/scripts/generate-gpg-key.sh` via `output` template function and rewrites placeholders. This phase replaces that mechanism. New approach (planner discretion on exact shape):

- Static gitconfig template content using chezmoi data (`.name`, `.email`, `.signingkey` if set)
- `.signingkey` becomes a chezmoi data field, set by `setup-credentials.sh` after key generation (e.g., write to `~/.config/chezmoi/chezmoi.yaml` or a sourced data file)
- Until `setup-credentials.sh` has run on a machine, signingkey is unset and `commit.gpgsign` is either false or relies on git falling back to unsigned commits with a clear error
- `home/scripts/generate-gpg-key.sh` deleted

## Script Design

### Idempotency model

`setup-credentials.sh` must be safely re-runnable. Default behavior:
- Existing local key + registered with GitHub → skip generation, no-op
- Existing local key + NOT registered with GitHub → register existing pubkey
- No local key → generate + register
- Local key file missing but GitHub has a key recorded for the hostname → planner-discretion (likely: regenerate + register new, leave stale GitHub-side key for user to clean up manually OR detect-and-prompt)

Rotation flag (e.g., `--rotate-ssh`, `--rotate-gpg`, `--rotate-all`): force regeneration, register new pubkey, optionally call `gh ssh-key delete` / `gh gpg-key delete` on the prior one. Default invocation does NOT rotate.

### Machine-awareness

Script runs on every dev-role machine (Mac personal, Mac work, Lonestar when it lands). The work Mac gets a `personal` SSH/GPG key generated (so Teague can access personal repos from work Mac). It does NOT generate or manage the Bluebeam GitLab work key — that's hand-generated separately and chezmoi's `~/.ssh/config` template just references the expected file path.

### Failure modes

- `gh auth login` interrupted / fails → script exits non-zero with clear "re-run when ready" message
- Key generation fails (disk space, gpg-agent issues) → exit, clear message
- `gh ssh-key add` fails (network, scope mismatch) → exit, instruct manual registration
- Re-run after partial completion → idempotency carries forward

### Naming and location

`home/scripts/setup-credentials.sh` (or planner-chosen path). Not a `run_once_` chezmoi script — explicitly invoked by user. Lives in the repo for distribution but does not run automatically on apply.

## SSH Config Template

`home/private_dot_ssh/config.tmpl` (or similar — planner discretion on chezmoi naming conventions). Purpose-based host aliases:

```ssh
Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/personal_ed25519

Host gitlab-bluebeam
  # Only on work Mac (templated)
  HostName <bluebeam-gitlab-host>
  User git
  IdentityFile ~/.ssh/work_ed25519
```

Template gates `gitlab-bluebeam` block on a chezmoi data field (e.g., `.employer == "bluebeam"` or a `.hasWorkGit` boolean). Bluebeam-internal hostname is per-machine data, not template literal.

## VaultWarden Package Pin

`bw` CLI pinned to version compatible with live VW server 1.36.0. Documented in `packages.yaml` comment + a brief note in `bootstrap/` or `docs/` covering the compat pair (Pitfall 3 mitigation). When VW server upgrades, the pin gets bumped in lockstep — separate work, not Phase 1's problem.

## Verification

1. **Signed commit test** — on a clean machine (VM), after Stage 1 + Stage 2, `git commit -S --allow-empty -m "phase 1 verify"` produces a verified-signed commit (verified via `git log --show-signature`).
2. **SSH auth test** — `ssh -T git@github-personal` returns the GitHub welcome message; `ssh -vT git@github-personal` shows the expected fingerprint.
3. **Structural VW-independence check** — grep templates + `.chezmoiscripts/` for `bitwarden`, `bitwardenAttachment`, `bw` invocations. Assert: zero matches in apply-time code paths. (One match permitted in `setup-credentials.sh` documentation comments, none in template logic.) Replaces original "vault-offline drill" — verifies the property structurally rather than by runtime simulation.
4. **Idempotency check** — run `setup-credentials.sh` twice on the same machine; second run is a no-op (or near-no-op, just re-verifies registration), no duplicate keys registered with GitHub.
5. **Rotation check** — run `setup-credentials.sh --rotate-all` (or whichever flag the planner lands on); old key revoked, new key registered, signed commit still works.

### Verification target

Parallels VM running fresh macOS 26.5.1 arm64 at `10.211.55.4` (jteague@10.211.55.4, key-based SSH already set up from this session). Snapshot `vanilla-fresh-boot-pre-chezmoi` taken before any chezmoi work — restore to this snapshot for repeat runs of the bootstrap drill.

This is the first phase where a VM target is part of the verification plan. Mac personal + Mac work are existing-state environments where the drill cannot be cleanly run (they already have keys and configured GPG).
</decisions>

<deferred>
## Deferred / Future

- **Canonical GPG migration.** If a future use case emerges (publishing signed releases, GPG-encrypted email as a security contact, encrypting files between machines that age-with-SSH-recipient can't handle), migrate from per-machine to one canonical GPG identity. One-way upgrade, no urgency. Tracked as a possible future phase or one-shot.
- **Encrypted bootstrap kit.** If the credential plane ever centralizes again (e.g., canonical GPG, or a future SSH key that genuinely must be portable), revisit kit design at that time. Phase 1 explicitly does NOT build this.
- **Vault-offline drill as runtime simulation.** Replaced in Phase 1 by structural VW-independence check. If a future phase reintroduces inline VW template calls (e.g., for time-sensitive cred retrieval), runtime drill comes back as a phase-close requirement.
- **PAT-rotation automation.** If GitHub PAT shows up as a persistent VW item for some operation, design a rotation reminder / automation. Not in Phase 1.
- **Bluebeam GitLab key automation.** If Bluebeam exposes a programmatic SSH key registration path (`glab ssh-key add`, API, etc.), opportunistically fold work-key generation into the script later. Phase 1 leaves it manual.
- **Lonestar onboarding.** When Lonestar materializes, it gets Stage 1 + Stage 2 like any other dev-role machine. Lonestar may want different settings; reassess at that time.
</deferred>

<open-questions>
## Open Questions for Planning

These are unresolved details that the planner agent should pin during plan creation — none are architecturally load-bearing.

1. **Exact chezmoi data field name for `signingkey`.** Where it lives (chezmoi.yaml? a data file? template var?), how `setup-credentials.sh` writes it, how `modify_dot_gitconfig.local` reads it.
2. **`setup-credentials.sh` location in repo.** `home/scripts/`? `bootstrap/`? Something else? Should it survive Phase 0 cleanup naming?
3. **Rotation flag shape.** `--rotate`? `--rotate-ssh` / `--rotate-gpg` / `--rotate-all`? Sensible default behavior.
4. **GitHub-side stale key cleanup.** When a machine is decommissioned, who removes its keys from GitHub? Manual user task documented in README, or scripted? Probably manual + documented.
5. **Multi-host SSH config.** Beyond `github-personal` + `gitlab-bluebeam`, what other host aliases are needed? `homelab` (for Unraid SSH)? `lonestar`? Planner gathers from current usage.
6. **VW pin syntax in packages.yaml.** Homebrew formulae pinning — `bw@<version>` is not directly supported; pin via brew formula version or document expected version with a check.
7. **Test plan for signed-commit verification on VM.** Setup steps before running verification (need a test repo cloned, etc.).
8. **`modify_dot_gitconfig.local` final shape.** Three possible patterns — pure template (no `output` call), conditional output based on key presence, or removed entirely with gitconfig becoming a static template. Planner picks based on chezmoi idiomatic patterns.
</open-questions>

<context>
## Why this scope, not the roadmap's scope

The roadmap entry for Phase 1 ("VaultWarden + Secret Plane + Bootstrap Kit") was written before this session's architectural pivot. During discussion-first 2026-06-04, two re-frames landed:

1. **Inline VW template calls are an anti-pattern for this fleet.** Touching VW on every routine apply makes Pitfall 10 ("VW unreachable bricks routine apply") a permanent fixture. Moving credential ops to an explicit post-apply script makes VW unreachability irrelevant to routine work.

2. **Regenerable credentials don't need a central store.** SSH and GPG keys are cheap to generate and freely re-registrable with services. Storing them centrally adds rotation burden, kit complexity, and a chicken-and-egg problem (you need a credential to retrieve credentials). Per-machine generation eliminates all of this at the cost of: per-machine identity continuity (no single "canonical" key per service).

The cost is real but bounded — multiple verified keys per GitHub account is supported and unremarkable, commit history retains "verified" status under whichever key signed each commit, and the GPG identity-continuity loss only matters if GPG is used for cross-machine encryption (which Teague does not do).

Result: Phase 1 shrinks from a multi-pillar credential-plane build-out to a focused per-machine bootstrap script + template glue. Pitfall 10 dies structurally rather than via mitigation. Pitfall 3 (CLI / server version drift) survives and is addressed via formula pin.
</context>
