{ lib, ... }:

{
  options.sys = {
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "System hostname. Maps to networking.hostName.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      description = "Primary user account name.";
    };

    timezone = lib.mkOption {
      type = lib.types.str;
      default = "America/New_York";
      description = "System timezone. Maps to time.timeZone.";
    };

    locale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
      description = "System locale. Maps to i18n.defaultLocale.";
    };

    nvidia = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable proprietary NVIDIA drivers with modesetting.";
      };
      prime = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable hybrid Intel+NVIDIA offload (laptops).";
        };
        intelBusId = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "PCI bus ID of the Intel GPU (e.g. \"PCI:0:2:0\"). Required when prime is enabled.";
        };
        nvidiaBusId = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "PCI bus ID of the NVIDIA GPU (e.g. \"PCI:1:0:0\"). Required when prime is enabled.";
        };
      };
    };

    docker.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Docker daemon and add the primary user to the docker group.";
    };

    bluetooth.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Bluetooth (bluez).";
    };

    printing.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable CUPS printing.";
    };

    fingerprint.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable fingerprint reader (fprintd).";
    };

    thunderbolt.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Thunderbolt device authorization (bolt).";
    };

    autoLogin = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Skip the greeter and auto-login. Only use with full-disk encryption.";
    };

    swap = {
      size = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Swap file size in MB. null disables swap management. Example: 32768 for 32GB.";
      };
      path = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/swapfile";
        description = ''
          Filesystem path of the swap file. On btrfs root, override to a path
          on a NoCOW @swap subvolume (e.g. "/swap/swapfile") — kernel rejects
          hibernate from a swapfile on a CoW subvolume.
        '';
      };
      enableHibernate = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable hibernate (suspend-to-disk). Requires swap.size >= RAM.";
      };
      resumeOffset = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = ''
          Physical block offset of the swap file, used as `resume_offset=` on
          the kernel cmdline for hibernate-from-swapfile. Compute post-install
          via `btrfs inspect-internal map-swapfile -r <path>` (btrfs) or
          `filefrag -e <path> | head -2` (ext4). When null, hibernate-from-
          swapfile won't resume; the module emits a warning.
        '';
      };
    };

    nix = {
      extraSubstituters = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional binary cache URLs.";
      };
      extraTrustedPublicKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Public keys for extra substituters.";
      };
      trustedUsers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Users added to nix.settings.trusted-users (in addition to root).";
      };
      extraSettings = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.oneOf [
            lib.types.bool
            lib.types.str
            lib.types.int
            (lib.types.listOf lib.types.str)
          ]
        );
        default = { };
        description = ''
          Attrs merged into nix.settings. Use for keys that don't warrant
          first-class options (e.g. nix-219-compat, lazy-trees,
          builders-use-substitutes, builders = "@/etc/nix/machines").
        '';
      };
      netrcFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          If set, assigned to nix.settings.netrc-file. On-disk path to a file
          managed outside nix (user-provisioned or sops-provisioned). Uses str
          (not path) so the file stays at the literal path rather than being
          copied into the Nix store.
        '';
      };
      distributedBuilds = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Enable nix.distributedBuilds (remote builders). Consumers must also
          provide nix.buildMachines or point builders at a file via
          sys.nix.extraSettings.builders (e.g. "@/etc/nix/machines") — enabling
          this alone without a builders list is a silent no-op.
        '';
      };
    };

    determinate = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Use Determinate Nix's nixd daemon instead of the upstream NixOS nix
          module. When enabled, nix.conf management is delegated to Determinate's
          tooling.
        '';
      };
    };

    boot = {
      loader = lib.mkOption {
        type = lib.types.enum [
          "systemd-boot"
          "grub"
        ];
        default = "systemd-boot";
        description = ''
          Bootloader choice. "grub" enables enableCryptodisk so kernel/initrd
          can live on LUKS-encrypted root with no separate /boot. "systemd-boot"
          remains the default for unencrypted or separately-booted layouts.
        '';
      };

      fido2Unlock.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Enable boot.initrd.systemd.{enable,fido2.enable} so a LUKS volume
          configured with crypttabExtraOpts = [ "fido2-device=auto" ] unlocks
          via a tap on an enrolled YubiKey/FIDO2 device. Consumers own the
          disko LUKS spec that triggers this — this option just enables the
          initrd support.
        '';
      };
    };
  };
}
