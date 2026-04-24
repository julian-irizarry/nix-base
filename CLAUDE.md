# nix-base

Cross-platform **NixOS + home-manager** library flake. Exposes `nixosModules.default`,
`homeModules.default`, `lib.mkSystem`, and `lib.mkHome` for a private consumer flake
to import. Keep this repo public-safe: no identity, no secrets, no internal hostnames.

See `docs/specs/2026-04-24-nix-base-design.md` for the full design rationale.

## Commands

```bash
# Format (treefmt-nix: nixfmt + stylua + prettier)
nix fmt

# Evaluate modules + formatting check (the "test suite")
nix flake check --show-trace

# Smoke-build the home-manager activation package (dummy identity)
nix build .#checks.x86_64-linux.home
nix build .#checks.aarch64-darwin.home

# Smoke-build the NixOS system toplevel (Linux only)
nix build .#checks.x86_64-linux.nixos
```

Supported systems: `x86_64-linux`, `aarch64-darwin`. `mkHome` accepts a `systems`
arg to add more.

## Architecture

- `flake.nix` — exposes `homeModules.default`, `nixosModules.default`,
  `lib.mkHome`, `lib.mkSystem`, `formatter`, `checks`. Smoke builds verify
  both module trees with placeholder values.
- `lib/mkHome.nix` — thin wrapper over `home-manager.lib.homeManagerConfiguration`;
  returns an attrset keyed by system string.
- `lib/mkSystem.nix` — thin wrapper over `nixpkgs.lib.nixosSystem`; optionally
  integrates home-manager as a NixOS module when `homeModules` is provided.
  Sets `my.platform.nixGL.enable = false` for NixOS-integrated home-manager.
- `home/options.nix` — the home-manager **public contract** under `my.*`.
- `home/default.nix` — imports every topical home-manager folder.
- `home/home-defaults.nix` — derives `home.homeDirectory` from `home.username`.
- `home/{cli,desktop,editors,identity,network,nix,platform,shell,terminal}/` —
  topical home-manager module folders.
- `nixos/options.nix` — the NixOS **public contract** under `sys.*`.
- `nixos/default.nix` — imports every NixOS submodule.
- `nixos/{boot,desktop,hardware,networking,nix,programs,security,services,users,virtualisation}/`
  — topical NixOS module folders. Feature-gated modules use `lib.mkIf config.sys.*`.

## The `my.*` option surface

Only values that genuinely differ between consumers are options. Everything else
(aliases, plugins, tool list, kitty/tmux/nvim configs) stays hardcoded.

- `my.git.{userName,userEmail,signingKey,signingFormat,extraIncludes}` — identity
  and signing. `signingFormat` defaults to `"ssh"` (matches Anduril's flow).
- `my.nix.{extraNixPath,extraExperimentalFeatures,extraSubstituters,extraTrustedPublicKeys,extraSettings}`
  — appended to the base nix.conf. `extra-substituters` requires daemon trust
  (configured outside nix on Determinate installs).
- `my.zsh.extraInitFragments` — list of shell snippets concatenated at the **end**
  of the generated `.zshrc`. Primary secret-wiring mechanism (e.g. `op read` at
  shell init). Graceful fallback when `op` is missing is the fragment author's job.
- `my.ssh.extraHosts` — attrset of matchBlock specs, rendered to
  `~/.ssh/config.d/hm-hosts` (not `~/.ssh/config` — see SSH gotcha below).
- `my.font.{nerdFamily,name,size}` — `nerdFamily` indexes `pkgs.nerd-fonts.*`;
  `name` is the rendered family name terminals/editors reference. They must match.

## The `sys.*` option surface

Only values that genuinely differ between NixOS consumers are options.
Everything else (COSMIC, PipeWire, firewall, libvirt, 1Password) stays hardcoded.

- `sys.hostname` — maps to `networking.hostName`.
- `sys.username` — primary user account, groups, shell.
- `sys.timezone` — defaults to `"America/New_York"`.
- `sys.locale` — defaults to `"en_US.UTF-8"`.
- `sys.nvidia.{enable,prime.enable,prime.intelBusId,prime.nvidiaBusId}` — NVIDIA
  drivers and hybrid offload. Prime requires bus IDs from `lspci`.
- `sys.docker.enable` — Docker daemon + user group.
- `sys.bluetooth.enable` — bluez.
- `sys.printing.enable` — CUPS.
- `sys.fingerprint.enable` — fprintd.
- `sys.thunderbolt.enable` — bolt for TB4 device authorization.
- `sys.autoLogin` — skip the greeter (for FDE machines).
- `sys.swap.{size,enableHibernate}` — swap file (size in MB) with optional hibernate.
- `sys.nix.{extraSubstituters,extraTrustedPublicKeys}` — additional binary caches.

## Non-obvious patterns / gotchas

- **SSH config is not owned by home-manager.** `latticectl` writes to
  `~/.ssh/config`, so `home/network/ssh.nix` renders `my.ssh.extraHosts` to
  `~/.ssh/config.d/hm-hosts` and expects the user to `Include config.d/hm-hosts`
  once at the top of `~/.ssh/config`. Do **not** switch this to `programs.ssh` —
  latticectl will clobber it.
- **1Password SSH agent wiring is deferred.** `home/platform/darwin.nix` is a
  placeholder for the `IdentityAgent` socket path. Linux path is
  `~/.1password/agent.sock`, macOS is under
  `~/Library/Group Containers/.../agent.sock`. Configure per-platform, not shared.
- **Login shell is not managed by home-manager.** Run `chsh -s $(which zsh)` once
  per fresh machine. An earlier activation hook did this automatically via
  `sudo chsh` but was removed — it prompted for a password on every switch and
  broke non-interactive activations.
- **`initContent` ordering matters.** `home/shell/zsh.nix` uses `lib.mkMerge`
  with `mkBefore` (sources `.zshenv.local`), the default slot (bindkeys, completion
  zstyles, widgets, sources `.zshrc.local`), and `mkAfter` (concatenates
  `my.zsh.extraInitFragments`). Extended-flake secrets must land last.
- **Tools use real binaries, not Debian aliases.** `fd`/`bat`/`eza` come from
  nixpkgs — don't reintroduce `fdfind`/`batcat` shims.
- **`home/shell/omp.json`** is excluded from prettier in `treefmt.nix`
  (oh-my-posh's schema uses nonstandard formatting). Don't re-enable it.
- **Secrets never live in this repo.** Any secret wiring belongs in the extended
  flake's `work-secrets.nix` via `my.zsh.extraInitFragments`. Reject PRs that add
  plaintext tokens, identity emails, or internal hostnames here.
- **nixGL wrapping is conditional.** `my.platform.nixGL.enable` (default `true`)
  controls whether GPU apps are wrapped with nixGL. On NixOS (via `mkSystem`),
  this is set to `false` automatically. Individual modules (`wezterm.nix`,
  `kitty.nix`, `vicinae.nix`) check this option before wrapping.

## Consumer flake shape

```nix
# NixOS with integrated home-manager (work machine)
nix-base.lib.mkSystem {
  system = "x86_64-linux";
  modules = [
    ./hardware-configuration.nix
    {
      sys.hostname = "workstation";
      sys.username = "you";
      sys.nvidia.enable = true;
    }
  ];
  homeModules = [{
    my.git.userName  = "Your Name";
    my.git.userEmail = "you@work.com";
  }];
};
```

```nix
# Standalone home-manager (non-NixOS)
nix-base.lib.mkHome {
  modules = [{
    home.username = "you";
    my.git.userName  = "Your Name";
    my.git.userEmail = "you@example.com";
  }];
};
```

Activate with `--flake .#x86_64-linux` or `.#aarch64-darwin`. `home.homeDirectory`
and `home.stateVersion` are derived; override via `lib.mkForce` if needed.

## Workflow expectations

- One commit per logical change; keep commit subjects in the style of
  `feat(<area>): ...`, `refactor(<area>): ...`, `chore: ...` (see `git log`).
- Run `nix fmt && nix flake check --show-trace` before claiming work is done —
  evaluation errors and formatting drift are the two most common breakages.
- **Never run `git commit` without explicit user approval** (see global
  `~/.claude/CLAUDE.md`).
- Prefer adding a new `my.*` option only when a value genuinely differs between
  personal and work use. Hardcode otherwise.
- **Comment sparingly.** Only comment when the code is not obvious — hidden
  constraints, workarounds, ordering requirements, or surprising choices.
  Don't restate what the code plainly does.
