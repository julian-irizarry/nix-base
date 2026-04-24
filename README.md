# nix-base

Cross-platform **NixOS + home-manager** library flake. Exposes reusable module
sets and helpers for a private consumer flake to import.

This repo is a **library** — it is not directly activatable. A consumer flake
supplies identity, hardware config, and calls `mkSystem` or `mkHome`.

See `docs/specs/2026-04-24-nix-base-design.md` for the full design rationale.

## Structure

- `flake.nix` — exposes `nixosModules.default`, `homeModules.default`,
  `lib.mkSystem`, `lib.mkHome`, and `checks`
- `lib/mkSystem.nix` — wraps `nixpkgs.lib.nixosSystem`; optionally integrates
  home-manager as a NixOS module
- `lib/mkHome.nix` — wraps `home-manager.lib.homeManagerConfiguration`
- `home/` — home-manager modules grouped by concern
  - `options.nix` — `my.*` option surface (the public contract)
  - `home-defaults.nix` — derives `home.homeDirectory` from `home.username`
  - `cli/`, `desktop/`, `editors/`, `identity/`, `network/`, `nix/`,
    `platform/`, `shell/`, `terminal/`
- `nixos/` — NixOS modules grouped by concern
  - `options.nix` — `sys.*` option surface (the public contract)
  - `boot/`, `desktop/`, `hardware/`, `networking/`, `nix/`, `programs/`,
    `security/`, `services/`, `users/`, `virtualisation/`
- `darwin/` — placeholder for future nix-darwin support

## Supported systems

`x86_64-linux` and `aarch64-darwin` by default. `mkHome` accepts a `systems`
argument to override.

## Consumer flake

### NixOS with integrated home-manager

```nix
{
  description = "Work NixOS config";

  inputs.nix-base.url = "github:<user>/nix-base";

  outputs =
    { nix-base, ... }:
    {
      nixosConfigurations = nix-base.lib.mkSystem {
        system = "x86_64-linux";
        modules = [
          ./hardware-configuration.nix
          {
            sys.hostname = "workstation";
            sys.username = "you";
            sys.nvidia.enable = true;
          }
        ];
        homeModules = [
          {
            my.git.userName  = "Your Name";
            my.git.userEmail = "you@work.com";
          }
        ];
      };
    };
}
```

Activate with `sudo nixos-rebuild switch --flake .#workstation`.

### Standalone home-manager (non-NixOS)

```nix
{
  description = "Personal home-manager config";

  inputs.nix-base.url = "github:<user>/nix-base";

  outputs =
    { nix-base, ... }:
    {
      homeConfigurations = nix-base.lib.mkHome {
        modules = [
          {
            home.username = "you";
            my.git.userName  = "Your Name";
            my.git.userEmail = "you@example.com";
          }
        ];
      };
    };
}
```

Activate with `home-manager switch --flake .#x86_64-linux` or `.#aarch64-darwin`.

## Verify in isolation

```bash
nix flake check --show-trace
# or build individual checks:
nix build .#checks.x86_64-linux.home
nix build .#checks.x86_64-linux.nixos
```
