# nix-base

Cross-platform **NixOS + home-manager** library flake. Exposes reusable module
sets and helpers for a private consumer flake to import.

This repo is a **library** — it is not directly activatable. A consumer flake
supplies identity, hardware config, and calls `mkSystem` or `mkHome`.

## Usage

### NixOS with integrated home-manager

```nix
{
  inputs.nix-base.url = "github:<user>/nix-base";

  outputs = { nix-base, ... }: {
    nixosConfigurations.workstation = nix-base.lib.mkSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix
        {
          sys.hostname = "workstation";
          sys.username = "you";
          sys.nvidia.enable = true;
          sys.nvidia.prime.enable = true;
          sys.nvidia.prime.intelBusId = "PCI:0:2:0";
          sys.nvidia.prime.nvidiaBusId = "PCI:1:0:0";
          sys.docker.enable = true;
          sys.bluetooth.enable = true;
          sys.swap.size = 32768;
          sys.swap.enableHibernate = true;
        }
      ];
      homeModules = [
        {
          my.git.userName = "Your Name";
          my.git.userEmail = "you@work.com";
          my.git.signingKey = "~/.ssh/id_ed25519.pub";
        }
        {
          # Work-specific packages and shell config
          home.packages = with pkgs; [ slack awscli2 kubectl ];
          my.zsh.extraInitFragments = [
            ''
              if command -v op >/dev/null 2>&1; then
                export SECRET="$(op read 'op://vault/item/field' 2>/dev/null)"
              fi
            ''
          ];
          my.ssh.extraHosts = {
            dev-server = {
              hostname = "10.0.0.1";
              user = "deploy";
            };
          };
        }
      ];
    };
  };
}
```

Activate: `sudo nixos-rebuild switch --flake .#workstation`

### Standalone home-manager (non-NixOS)

```nix
{
  inputs.nix-base.url = "github:<user>/nix-base";

  outputs = { nix-base, ... }: {
    homeConfigurations = nix-base.lib.mkHome {
      modules = [{
        home.username = "you";
        my.git.userName = "Your Name";
        my.git.userEmail = "you@example.com";
      }];
    };
  };
}
```

Activate: `home-manager switch --flake .#x86_64-linux` or `.#aarch64-darwin`

## NixOS options (`sys.*`)

| Option                           | Type        | Default              | Description                                            |
| -------------------------------- | ----------- | -------------------- | ------------------------------------------------------ |
| `sys.hostname`                   | str         | —                    | `networking.hostName`                                  |
| `sys.username`                   | str         | —                    | Primary user (groups: wheel, networkmanager, libvirtd) |
| `sys.timezone`                   | str         | `"America/New_York"` | `time.timeZone`                                        |
| `sys.locale`                     | str         | `"en_US.UTF-8"`      | `i18n.defaultLocale`                                   |
| `sys.nvidia.enable`              | bool        | `false`              | Proprietary NVIDIA drivers                             |
| `sys.nvidia.prime.enable`        | bool        | `false`              | Hybrid Intel+NVIDIA offload                            |
| `sys.nvidia.prime.intelBusId`    | str         | `""`                 | Intel GPU PCI bus ID                                   |
| `sys.nvidia.prime.nvidiaBusId`   | str         | `""`                 | NVIDIA GPU PCI bus ID                                  |
| `sys.docker.enable`              | bool        | `false`              | Docker + user group                                    |
| `sys.bluetooth.enable`           | bool        | `false`              | Bluez                                                  |
| `sys.printing.enable`            | bool        | `false`              | CUPS                                                   |
| `sys.fingerprint.enable`         | bool        | `false`              | fprintd                                                |
| `sys.thunderbolt.enable`         | bool        | `false`              | bolt (TB4 authorization)                               |
| `sys.autoLogin`                  | bool        | `false`              | Skip greeter (use with FDE)                            |
| `sys.swap.size`                  | int or null | `null`               | Swap file size in MB                                   |
| `sys.swap.enableHibernate`       | bool        | `false`              | Suspend-to-disk                                        |
| `sys.nix.extraSubstituters`      | list        | `[]`                 | Binary cache URLs                                      |
| `sys.nix.extraTrustedPublicKeys` | list        | `[]`                 | Cache public keys                                      |
| `sys.nix.trustedUsers`           | list str    | `[]`                 | Added to nix.settings.trusted-users                    |
| `sys.nix.extraSettings`          | attrs       | `{}`                 | Free-form merge into nix.settings                      |
| `sys.nix.netrcFile`              | nullOr str  | `null`               | Path to externally-managed netrc                       |
| `sys.nix.distributedBuilds`      | bool        | `false`              | Enable remote builders                                 |
| `sys.determinate.enable`         | bool        | `false`              | Use Determinate Nix instead of upstream nix            |
| `sys.boot.loader`                | enum        | `"systemd-boot"`     | Bootloader; "grub" enables cryptodisk                  |
| `sys.boot.fido2Unlock.enable`    | bool        | `false`              | YubiKey LUKS auto-unlock in initrd                     |
| `sys.desktop.cosmic.enable`      | bool        | `true`               | COSMIC desktop + greeter                               |
| `sys.desktop.hyprland.enable`    | bool        | `false`              | Hyprland compositor + portal (+ noctalia cachix)       |

**Hardcoded** (always enabled): PipeWire, NetworkManager, fwupd, firewall,
polkit, 1Password, Chromium, Obsidian, libvirt, flakes, zsh. COSMIC is on
by default but now gated via `sys.desktop.cosmic.enable`; hyprland may be
enabled alongside it and the greeter lists both sessions.

### Hyprland + noctalia service deps

Noctalia's panels surface data from services nix-base does not auto-enable
when `sys.desktop.hyprland.enable = true`. Add these to your consumer flake
(typically laptop configs) for full widget coverage:

| Service                                 | Enables                                |
| --------------------------------------- | -------------------------------------- |
| `networking.networkmanager.enable`      | wifi (already hardcoded)               |
| `hardware.bluetooth.enable`             | bluetooth (via `sys.bluetooth.enable`) |
| `services.power-profiles-daemon.enable` | power profile toggle                   |
| `services.upower.enable`                | battery widget                         |

Missing deps don't break noctalia — the affected widgets just show no data.

## Home-manager options (`my.*`)

| Option                       | Type        | Default                | Description                                          |
| ---------------------------- | ----------- | ---------------------- | ---------------------------------------------------- |
| `my.git.userName`            | str         | —                      | Git user.name                                        |
| `my.git.userEmail`           | str         | —                      | Git user.email                                       |
| `my.git.signingKey`          | str or null | `null`                 | SSH/GPG signing key                                  |
| `my.git.signingFormat`       | enum        | `"ssh"`                | openpgp, ssh, x509                                   |
| `my.git.extraIncludes`       | list        | `[]`                   | Conditional gitconfig includes                       |
| `my.zsh.extraInitFragments`  | list        | `[]`                   | Shell snippets appended to .zshrc                    |
| `my.ssh.extraHosts`          | attrs       | `{}`                   | SSH matchBlocks                                      |
| `my.font.nerdFamily`         | str         | `"fira-code"`          | Nerd font attr name                                  |
| `my.font.name`               | str         | `"FiraCode Nerd Font"` | Font family for terminals/editors                    |
| `my.font.size`               | int         | `13`                   | Font size                                            |
| `my.platform.nixGL.enable`   | bool        | `true`                 | GPU wrapping (auto-disabled on NixOS)                |
| `my.desktop.hyprland.enable` | bool        | `false`                | Hyprland home config (keybinds, window rules, shell) |
| `my.desktop.hyprland.shell`  | enum        | `"noctalia"`           | Shell launched on hyprland login                     |

## Development

```bash
# Format
nix fmt

# Run all checks (evaluation + formatting + VM test)
nix flake check --show-trace

# Run individual checks
nix build .#checks.x86_64-linux.home        # home-manager smoke build
nix build .#checks.x86_64-linux.nixos        # NixOS evaluation smoke build
nix build .#checks.x86_64-linux.nixos-vm     # NixOS VM integration test
nix build .#checks.x86_64-linux.formatting   # treefmt check
```

## Structure

```
nix-base/
├── flake.nix
├── lib/
│   ├── mkHome.nix         # homeManagerConfiguration wrapper
│   └── mkSystem.nix       # nixosSystem wrapper + optional home-manager
├── home/                  # home-manager modules
│   ├── options.nix        # my.* options
│   ├── cli/  desktop/  editors/  identity/
│   ├── network/  nix/  platform/  shell/  terminal/
│   └── ...
├── nixos/                 # NixOS modules
│   ├── options.nix        # sys.* options
│   ├── boot/  desktop/  hardware/  networking/
│   ├── nix/  programs/  security/  services/
│   ├── users/  virtualisation/
│   ├── installer/         # ISO installer image (disko + install-image wrapper)
│   └── tests/             # VM integration tests
└── darwin/                # future nix-darwin
```
