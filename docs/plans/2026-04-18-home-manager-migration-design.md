# Home-Manager Migration Design

**Date:** 2026-04-18
**Status:** Design approved, ready for implementation plan

## Goal

Replace the current ad-hoc dotfile setup with a home-manager flake that:

1. Reproduces a working dev environment on Linux or macOS with one command.
2. Keeps cross-platform parity — same tools, same UX, on both platforms.
3. Cleanly separates base configuration (public, safe to share) from extended configuration (work-specific: identity, secrets, internal hosts, internal packages).
4. Replaces ad-hoc `apt`/`brew`/`curl|sh` installers with declarative package management where practical.
5. Removes plaintext secrets from disk. Secrets resolve at shell init via the 1Password CLI.

## Non-Goals (v1)

- Migrating `mamba`/`conda`/`nvm`. These self-manage; leave them alone.
- Managing Docker, `kubectl`, or cloud CLIs through nix (optional later).
- nix-darwin for macOS system-level configuration. Home-manager only for v1.
- sops-nix or agenix for secret management. 1Password-at-shell-init is enough for the current secret surface (shell env vars).
- GUI applications (Slack, Chrome, Obsidian, 1Password GUI). Let the OS package manager handle these.

## Architecture

### Two-flake structure

- **`home-manager`** (public, `github.com/julian-irizarry/home-manager`) — base modules, cross-platform, safe to share. Contains no identity, secrets, or internal hostnames.
- **`home-manager-extended`** (private, GHE) — imports the base flake as an input, adds work-specific modules (identity, secrets, internal SSH hosts, internal packages), and exposes its own `homeConfigurations`.

Fresh machine bootstrap on a personal box activates the base flake directly. On a work machine, only the extended flake is activated — it pulls in the base as a flake input.

### Parameterized module surface

Base modules expose a small option surface under `my.*`. Both flakes set these values; modules consume them. No `lib.mkForce` overrides.

```nix
options.my = {
  git = {
    userName       = mkOption { type = str; };
    userEmail      = mkOption { type = str; };
    signingKey     = mkOption { type = nullOr str; default = null; };
    extraIncludes  = mkOption { type = listOf attrs; default = []; };
  };
  nix.extraNixPath       = mkOption { type = listOf str; default = []; };
  zsh.extraInitFragments = mkOption { type = listOf str; default = []; };
  ssh.extraHosts         = mkOption { type = attrs; default = {}; };
};
```

Rule of thumb: only values that genuinely differ between consumers become options. Everything else (editor = nvim, shell plugins, aliases, package list, kitty/tmux/nvim configs) stays hardcoded in its module.

### Platform split

Platform-specific modules live under `modules/platform/`. `modules/default.nix` auto-detects platform and conditionally imports:

```nix
imports = [ ./options.nix /* ...shared modules... */ ]
  ++ lib.optionals pkgs.stdenv.isLinux  [ ./platform/linux.nix ]
  ++ lib.optionals pkgs.stdenv.isDarwin [ ./platform/darwin.nix ];
```

Small in-module platform differences use inline `lib.optionals pkgs.stdenv.is*` (e.g., `IdentityAgent` socket path inside `ssh.nix`).

### No `hosts/` directory

All personal machines share the same `my.*` values; same for all work machines. Values live once per flake in `flake.nix`. A `hosts/` directory would only add value if individual machines needed divergent values, which they don't. Platform differences are handled above.

### Repo layout (base flake)

```
home-manager/
├── flake.nix                # inputs, outputs, homeConfigurations.{linux,mac}
├── flake.lock
├── lib/
│   └── mkHome.nix           # helper: mkHome { system }: homeManagerConfiguration
├── modules/
│   ├── default.nix          # imports all modules + platform conditional
│   ├── options.nix          # my.* option surface
│   ├── shell/
│   │   ├── zsh.nix          # programs.zsh — oh-my-zsh, plugins, history, aliases, keybinds
│   │   └── prompt.nix       # programs.oh-my-posh
│   ├── git.nix              # programs.git — reads my.git.*
│   ├── ssh.nix              # programs.ssh — matchBlocks from my.ssh.extraHosts
│   ├── dev/
│   │   ├── neovim/          # absorbed nvim config (init.lua, lua/, plugins)
│   │   ├── neovim.nix       # xdg.configFile."nvim".source = ./neovim;
│   │   ├── tmux.nix         # programs.tmux
│   │   ├── kitty.nix        # programs.kitty
│   │   └── cli-tools.nix    # programs.{fzf,zoxide,bat,eza,gh,direnv} + home.packages
│   ├── nix-settings.nix     # nix.nixPath from my.nix.extraNixPath
│   └── platform/
│       ├── linux.nix
│       └── darwin.nix
├── docs/
│   └── plans/               # design docs, implementation plans
└── README.md
```

### Repo layout (extended flake)

```
home-manager-extended/
├── flake.nix                # imports base as input, homeConfigurations.{linux,mac}
├── flake.lock
└── modules/
    ├── work-identity.nix    # sets my.git.userEmail, signingKey, extraIncludes
    ├── work-secrets.nix     # my.zsh.extraInitFragments — op-based env vars
    ├── work-ssh.nix         # my.ssh.extraHosts — mimosa-dev, mimosa-dev-arm
    ├── work-packages.nix    # internal CLIs if available in nixpkgs/overlays
    └── work-aliases.nix     # wpc, wpd, scs — via my.zsh.extraInitFragments
```

## Module-by-module plan

All shell tools migrate to native home-manager `programs.*` modules to get full benefit (automatic shell integration, type-checked options, uniform upgrade path). Only nvim was considered for `mkOutOfStoreSymlink`, but since config iteration is rare (~annual), it's absorbed into the flake too.

| Tool | Module | Notes |
|---|---|---|
| zsh | `programs.zsh` | Replaces manual `source $ZSH/oh-my-zsh.sh`, plugin list, history settings, aliases, keybinds. Custom zle widgets (`find_and_cd_widget`) go in `programs.zsh.initContent`. |
| oh-my-posh | `programs.oh-my-posh` | Port existing `omp.json` into `settings` or point `useTheme` at a file. No prompt change. |
| git | `programs.git` | Replaces `~/.gitconfig`. Identity from `my.git.*`. |
| ssh | `programs.ssh` | `matchBlocks` from `my.ssh.extraHosts`. `IdentityAgent` configured per platform in `modules/platform/*.nix` — 1Password socket path differs between Linux and macOS. |
| tmux | `programs.tmux` | Absorb existing config. Plugins via `tmuxPlugins`. |
| kitty | `programs.kitty` | Absorb existing config. |
| nvim | `xdg.configFile."nvim"` | Config absorbed into `modules/dev/neovim/`. Stable enough not to need out-of-store editing. |
| fzf | `programs.fzf` | Native module handles shell integration (replaces `[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh`). |
| zoxide | `programs.zoxide` | Native module replaces manual `eval "$(zoxide init zsh)"`. |
| bat, eza, fd, ripgrep, jq, yq | `home.packages` + `programs.bat`/`programs.eza` where modules exist | Real binaries (not Debian's `batcat`/`fdfind`). Update aliases: `alias cat=bat`, `fd` directly. |
| gh | `programs.gh` | Configured identity. |
| direnv | `programs.direnv` | Auto-hooks into zsh. |
| atuin | (dropped) | Not currently in active use. |
| mamba/conda/nvm | (unmanaged) | Self-managing. Omit from flake. If needed, let them live in `~/.zshrc.local` on machines that have them installed. |

### Useful patterns from the existing `home.nix` to keep

- **`home.activation.make-zsh-default-shell`** — a DAG-ordered activation hook that runs `chsh` on Linux if the login shell isn't already zsh. Preserves "one-command bootstrap" on fresh machines. Port forward to the new `modules/platform/linux.nix`.
- **`nixpkgs.config.allowUnfreePredicate`** — targeted unfree allowance. Carry the pattern even though the current unfree list (obsidian, google-chrome, spotify) may be empty initially since GUI apps are out of scope for v1.

## Secret handling

No secret values live in any flake, any file on disk, or any git repo.

**Mechanism:** `modules/work-secrets.nix` in the extended flake contributes a shell fragment via `my.zsh.extraInitFragments`. The fragment uses `op read` at shell-init time to populate env vars:

```nix
my.zsh.extraInitFragments = [
  ''
    if command -v op >/dev/null 2>&1 && op account list >/dev/null 2>&1; then
      export SRC_ACCESS_TOKEN="$(op read 'op://Employee/Sourcegraph/credential' 2>/dev/null)"
      export SRC_ENDPOINT="https://scs.anduril.dev"
    fi
  ''
];
```

Base `programs.zsh.initContent` concatenates all fragments into the generated `.zshrc`. Graceful fallback: if `op` is not installed or not signed in, the block is skipped silently and shell startup continues.

**Alternatives rejected:**

- **sops-nix/agenix** — overkill for shell env vars; value add comes when secrets must be present in nix store paths (systemd units, nix-managed config files). Revisit if that surface grows.
- **`op inject` at activation time** — home-manager activation runs without a session; `op` fails. Fragile.
- **`~/.zshrc.local`** — retained as a cheap escape hatch but no longer the home for secrets. The source-if-exists line remains in the generated `.zshrc` for ad-hoc per-machine overrides.

## SSH

- **Private keys:** 1Password SSH agent. Not on disk. Not in any flake.
- **`~/.ssh/config`:** generated by `programs.ssh` from `my.ssh.extraHosts`. Base flake may add cross-cutting blocks (e.g., `Host *` with `IdentityAgent`); extended flake adds `mimosa-dev`, `mimosa-dev-arm`.
- **`IdentityAgent` socket path:** differs between Linux (`~/.1password/agent.sock`) and macOS (`~/Library/Group Containers/.../agent.sock`). Configured in `modules/platform/{linux,darwin}.nix`.
- **`authorized_keys`:** out of scope (dev machines, not servers).

## Bootstrap sequence (fresh machine)

1. Install nix via Determinate Systems installer:
   `curl -fsSL https://install.determinate.systems/nix | sh -s -- install`
2. Install 1Password GUI (OS package manager or 1password.com download). Sign in. Enable SSH agent + CLI integration in settings.
3. (Work only) Confirm SSH access to extended flake's remote: `ssh -T git@ghe.anduril.dev`.
4. Clone the appropriate flake:
   - Personal: `git clone git@github.com:julian-irizarry/home-manager ~/repos/home-manager`
   - Work: `git clone git@ghe.anduril.dev:jirizarry/home-manager-extended ~/repos/home-manager-extended`
5. Activate: `nix run home-manager/master -- switch --flake .#linux` (or `.#mac`).
6. (Linux only) `chsh -s $(which zsh)` — or rely on the activation hook ported from the old flake.
7. Restart shell.

Ongoing updates on any machine: `cd ~/repos/<flake> && git pull && home-manager switch --flake .#linux`.

## Git identity across machines

Home-manager does **not** manage per-directory git identity overrides. This is a rare-enough situation (a personal repo on a work machine, or vice versa) to handle manually:

- **Auth:** HTTPS + Git Credential Manager. Browser-based login per host+account. `credential.useHttpPath = true` set in base `git.nix` so GCM keys credentials by repo path, avoiding account collisions on github.com.
- **Identity:** per-repo `git config user.name` / `user.email` as a stopgap for the rare mixed-case repo. Default identity comes from the active flake (work default on work machines, personal default on personal).

## Migration plan (big-bang cutover)

User is comfortable with one-shot migration given backups and existing nix familiarity.

### Phase 0 — Safety net

```bash
cp ~/.zshrc       ~/.zshrc.backup
cp ~/.zshrc.local ~/.zshrc.local.backup
cp ~/.gitconfig   ~/.gitconfig.backup
cp -r ~/.ssh/config ~/.ssh/config.backup  # if present
```

Rotate the Sourcegraph token currently stored in `~/.zshrc.local`. Store the new value in 1Password at `op://Employee/Sourcegraph/credential` (or chosen path). Remove from `~/.zshrc.local`.

The `~/Downloads/repos/dotfiles` repo stays untouched as a reference until the new setup is stable. Symlinks under `~/.config/` (nvim, kitty, tmux, oh-my-posh) remain until Phase 2 cutover.

### Phase 1 — Build both flakes end-to-end

Write every module. `nix flake check` passes on both. Do not activate yet.

### Phase 2 — Cutover

```bash
# remove existing symlinks that conflict with home-manager output
rm ~/.config/nvim ~/.config/kitty ~/.config/tmux ~/.config/oh-my-posh

cd ~/repos/home-manager-extended
nix run home-manager/master -- switch --flake .#linux
```

Home-manager refuses to overwrite existing files by default. Each refused path becomes a checklist item: delete or back up, re-run. Converges in a couple iterations.

### Phase 3 — Verify and clean up

In a fresh shell, check: prompt, aliases, zsh keybinds, `git config --list`, `ssh mimosa-dev`, `scs` (token from `op`), tmux/kitty/nvim with correct config. Fix anything broken by editing the flake and `home-manager switch`.

Once stable: remove `.backup` files, archive the old `~/Downloads/repos/dotfiles` repo at leisure.

### Rollback

- **Soft:** `home-manager switch --switch-generation <N-1>` — one command, instant.
- **Nuclear:** remove home-manager state (`~/.local/state/home-manager`, `~/.config/home-manager`), restore `.backup` files, restore dotfile symlinks.

## Phase 5 — Nice-to-haves (out of scope for v1)

- nix-darwin for macOS system defaults (dock, finder, global shortcuts, brew integration).
- sops-nix or agenix if the secret surface grows beyond shell env vars.
- CI: `nix flake check` on push; auto-update flake inputs.
- Promoting cross-platform GUI apps into nix if pain points arise (Linux).
- Aerospace or other platform-specific window managers on macOS.

## Key decisions log

| Decision | Choice | Why |
|---|---|---|
| Flake structure | Two flakes: base (public) + extended (private) as flake input | Clean separation, extended can ride version of base, base stays shareable |
| Config style | Parameterized modules with `my.*` option surface | Honest contract, no `mkForce` noise, clean extension point |
| Option count | ~5 (`git.*`, `nix.extraNixPath`, `zsh.extraInitFragments`, `ssh.extraHosts`) | Only parameterize what genuinely varies |
| Platform handling | `lib.optionals pkgs.stdenv.is*` in `modules/default.nix` | Idiomatic, no `hosts/` dir needed |
| Prompt | Keep oh-my-posh | Avoid scope creep; easy swap to starship later |
| nvim | Absorb into flake | Rare iteration, benefits from full reproducibility |
| Other dotfiles (tmux, kitty, oh-my-posh) | Absorb via native modules | Use full home-manager capabilities |
| Atuin | Dropped | Not in active use |
| Secrets | 1Password CLI at shell init via `my.zsh.extraInitFragments` | No secrets in repos, graceful fallback, minimal ceremony |
| SSH keys | 1Password agent only | Keys never on disk; cross-platform mechanism |
| Git identity (cross-account) | Manual per-repo config + GCM for HTTPS auth | Too rare to bake into flake |
| Migration strategy | Big-bang cutover | User comfortable with risk given backups and home-manager's generation rollback |
