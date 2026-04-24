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
      enableHibernate = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable hibernate (suspend-to-disk). Requires swap.size >= RAM.";
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
    };
  };
}
