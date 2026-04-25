# nix-base

Cross-platform **NixOS + home-manager** library flake. Exposes `nixosModules.default`,
`homeModules.default`, `lib.mkSystem`, and `lib.mkHome` for a private consumer flake
to import. Keep this repo public-safe: no identity, no secrets, no internal hostnames.

See `README.md` for usage and the full option reference.

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
- `nixos/installer/default.nix` — imports `disko.nixosModules.disko` and emits
  `image.modules.iso-installer` with an `install-image` shell wrapper. Build with
  `nh os build-image --image-variant=iso-installer -H <host>` or
  `nix build .#nixosConfigurations.<host>.config.system.build.images.iso-installer`.

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
- `my.desktop.hyprland.{enable,shell}` — enable the Hyprland home config
  (keybinds, window rules, exec-once for the shell). `shell` is an enum
  currently fixed at `"noctalia"`; shaped for future alternatives.
  Independent of `sys.desktop.hyprland.enable` on the NixOS side — pair them
  yourself. `noctalia` is threaded in via `extraSpecialArgs` so the home
  sub-module can reference `noctalia.packages.${system}.default`.

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
- `sys.swap.{size,path,enableHibernate,resumeOffset}` — swap file (size in MB) at
  `path` (default `/var/lib/swapfile`). With `enableHibernate = true`, the module
  derives `boot.resumeDevice` from the fileSystems entry containing `path`.
  `resumeOffset` must be set to the swapfile's physical block offset for the
  kernel to actually resume from disk — compute post-install via
  `btrfs inspect-internal map-swapfile -r <path>` (btrfs) or
  `filefrag -e <path>` (ext4). On btrfs, point `path` at a NoCOW `@swap`
  subvolume; the kernel rejects hibernate from a CoW subvolume.
- `sys.nix.{extraSubstituters,extraTrustedPublicKeys}` — additional binary caches.
- `sys.determinate.enable` — use Determinate Nix's nixd daemon instead of upstream
  NixOS nix. When true, Determinate owns `/etc/nix/nix.conf`; the library skips its
  own `experimental-features`, `auto-optimise-store`, and `nix.gc` wiring.
- `sys.boot.loader` — enum `"systemd-boot" | "grub"`, default `"systemd-boot"`. GRUB
  enables `enableCryptodisk` for encrypted root without a separate `/boot` partition.
- `sys.boot.fido2Unlock.enable` — toggle `boot.initrd.systemd.{enable,fido2.enable}`
  for YubiKey LUKS unlock. Consumers must set
  `crypttabExtraOpts = [ "fido2-device=auto" ]` in their disko LUKS spec themselves.
- `sys.nix.trustedUsers` — users added to `nix.settings.trusted-users` (plus root).
- `sys.nix.extraSettings` — free-form attrs merged into `nix.settings` for keys not
  worth first-class options.
- `sys.nix.netrcFile` — path assigned to `nix.settings.netrc-file`. File is managed
  outside nix (e.g., sops-provisioned).
- `sys.nix.distributedBuilds` — toggle `nix.distributedBuilds`; consumers must also
  declare `nix.buildMachines` or `sys.nix.extraSettings.builders`.
- `sys.desktop.{cosmic.enable,hyprland.enable}` — independent compositor toggles.
  `cosmic.enable` defaults `true` to preserve historical behavior (cosmic used
  to be imported unconditionally). Both may be `true` simultaneously; cosmic-
  greeter lists whichever session files are installed. `hyprland.enable` also
  wires `nix.settings.extra-substituters` for `noctalia.cachix.org` so the
  deployed daemon can fetch pre-built noctalia-shell.

## Non-obvious patterns / gotchas

- **SSH config is not owned by home-manager.** `latticectl` writes to
  `~/.ssh/config`, so `home/network/ssh.nix` renders `my.ssh.extraHosts` to
  `~/.ssh/config.d/hm-hosts` and expects the user to `Include config.d/*`
  once at the top of `~/.ssh/config` so both `hm-hosts` and `identity-agent` are
  picked up. Do **not** switch this to `programs.ssh` — latticectl will clobber it.
- **1Password SSH agent is wired automatically.** `home/platform/linux.nix` and
  `home/platform/darwin.nix` each write a `~/.ssh/config.d/identity-agent` snippet
  with the platform-specific `IdentityAgent` socket path (Linux:
  `~/.1password/agent.sock`, macOS:
  `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`). The 1Password
  app must be running with SSH agent enabled for it to resolve. Consumers that don't
  use 1Password simply get a dead socket path, which OpenSSH tolerates.
- **Determinate owns nix.conf when enabled.** When `sys.determinate.enable = true`,
  `nixos/nix/default.nix` does not emit `experimental-features`,
  `auto-optimise-store`, or `nix.gc` — Determinate manages those via
  `/etc/nix/nix.conf` (read-only, auto-generated, reads `/etc/nix/nix.custom.conf`
  via `!include`). Use `sys.nix.extraSettings` for extra keys; they land in
  `nix.custom.conf`. Use the `extra-substituters` / `extra-trusted-public-keys`
  additive keys (not `substituters` / `trusted-public-keys`) so Determinate's
  built-in cache defaults (flakehub, cache.nixos.org) are preserved.
- **GRUB+cryptodisk requires a compatible disko layout.** When
  `sys.boot.loader = "grub"`, GRUB reads kernel/initrd from the encrypted root
  directly — consumers must ensure their disko layout has an ESP (at `/boot/efi`)
  and LUKS root with no separate `/boot`, or GRUB will silently fail to find kernels.
  FIDO2-unlock (`sys.boot.fido2Unlock.enable = true`) requires the LUKS content spec
  to include `crypttabExtraOpts = [ "fido2-device=auto" ]` — this is consumer-owned.
- **btrfs swap requires a NoCOW subvolume.** When using `sys.swap` on a btrfs
  root, the consumer's disko spec must declare a dedicated `@swap` subvolume
  for the swapfile to live on. Btrfs CoW + swap is forbidden by the kernel,
  and snapshots of a swap subvolume break the file. `sys.swap.path` should
  point inside that subvolume's mountpoint (e.g. `/swap/swapfile`).
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
- **Hyprland and cosmic are independent toggles.** `sys.desktop.cosmic.enable`
  and `sys.desktop.hyprland.enable` may both be `true`; cosmic-greeter lists
  whichever session files are installed. Shared Wayland env vars
  (`NIXOS_OZONE_WL`, `MOZ_ENABLE_WAYLAND`) live in `nixos/desktop/default.nix`
  and land whenever either desktop is on.
- **Hyprland home config is independent from the NixOS toggle.** Setting
  `my.desktop.hyprland.enable = true` without `sys.desktop.hyprland.enable`
  on the NixOS side installs user config for a compositor that isn't running.
  By design — the user is responsible for pairing both halves. The home
  module is additionally gated on `pkgs.stdenv.hostPlatform.isLinux` because
  hyprland has no Darwin build.
- **Hyprland keybinds mirror popshell/cosmic muscle memory.** See
  `home/desktop/hyprland/keybinds.nix` for the full list (Super+hjkl focus,
  Super+Shift+hjkl swap, Super+W close, Super+F zoom, Super+G float,
  Super+O split, Super+Shift+O cycle layout, Ctrl+Space vicinae,
  Super+Return wezterm). Layout cycle is a `pkgs.writeShellScriptBin` wrapper
  around `hyprctl keyword general:layout` because hyprland has no built-in
  layout-cycle dispatcher.
- **Noctalia is threaded via extraSpecialArgs.** `lib/mkHome.nix`,
  `lib/mkSystem.nix`, and `nixos/tests/default.nix` all pass the `noctalia`
  flake input into home-manager's `extraSpecialArgs`. `home/desktop/hyprland/
noctalia.nix` receives it as a module arg and wires
  `programs.noctalia-shell.package = noctalia.packages.${system}.default`.
  If you add new mkHome/mkSystem paths, remember to thread noctalia the same
  way or the module will eval-error.
- **Hyprland on NVIDIA needs extra env vars.** If `sys.nvidia.enable = true`
  is combined with `sys.desktop.hyprland.enable = true`, the consumer should
  set `WLR_NO_HARDWARE_CURSORS=1` (and friends) via their extended flake —
  nix-base does not auto-wire these.
- **Noctalia cachix cache is wired in two layers.** `flake.nix` top-level
  `nixConfig` adds `noctalia.cachix.org` as an `extra-substituter` for
  evaluators (helps CI/smoke builds). `nixos/desktop/hyprland.nix` mirrors
  that in `nix.settings` when `sys.desktop.hyprland.enable = true` so the
  deployed daemon uses the cache on rebuild. Both use the **additive** keys
  (`extra-substituters`/`extra-trusted-public-keys`) so Determinate's
  defaults are preserved. Key: `noctalia.cachix.org-1:pCOR47nn...`.
- **Noctalia's wifi/bluetooth/battery/power-profile widgets need upstream
  NixOS services.** Noctalia's panels surface data from services that
  nix-base does NOT auto-wire when hyprland is enabled:
  - `networking.networkmanager.enable` — already hardcoded on by nix-base (wifi OK).
  - `hardware.bluetooth.enable` — consumer opts in via `sys.bluetooth.enable`.
  - `services.power-profiles-daemon.enable` **or** `services.tuned.enable` —
    consumer-wired; no nix-base option.
  - `services.upower.enable` — consumer-wired; no nix-base option.
    Missing deps don't break noctalia; the corresponding widgets just go dead.
    Laptop consumers should turn these on in their own config.

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
