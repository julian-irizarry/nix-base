{ lib, ... }:

{
  options.my = {
    git = {
      userName = lib.mkOption {
        type = lib.types.str;
        description = "Git user.name.";
      };
      userEmail = lib.mkOption {
        type = lib.types.str;
        description = "Git user.email.";
      };
      signingKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Git signing key (SSH private key path for ssh format, or GPG key id). Null disables signing.";
      };
      signingFormat = lib.mkOption {
        type = lib.types.enum [
          "openpgp"
          "ssh"
          "x509"
        ];
        default = "ssh";
        description = "Git commit signing format. Default ssh matches Anduril's signing flow.";
      };
      extraIncludes = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [ ];
        description = ''
          List of conditional includes for ~/.gitconfig. Each entry is
          { condition = "gitdir:..."; contents = { ... }; }.
        '';
      };
    };

    nix = {
      extraNixPath = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional entries appended to NIX_PATH.";
      };
      extraExperimentalFeatures = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Extra experimental-features appended to the base set
          [ nix-command flakes ] in ~/.config/nix/nix.conf.
        '';
      };
      extraSubstituters = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Extra binary caches appended via extra-substituters. The daemon
          must trust these (configured in /etc/nix/nix.custom.conf on
          Determinate installs).
        '';
      };
      extraTrustedPublicKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra trusted-public-keys appended via extra-trusted-public-keys.";
      };
      extraSettings = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.oneOf [
            lib.types.str
            lib.types.bool
            lib.types.int
            (lib.types.listOf lib.types.str)
          ]
        );
        default = { };
        description = ''
          Additional freeform key=value entries written to
          ~/.config/nix/nix.conf. List values are space-joined per
          nix.conf semantics.
        '';
      };
    };

    zsh.extraInitFragments = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Shell fragments appended to the generated .zshrc. Used by the extended
        flake for secret wiring (op-based env vars) and work-only aliases.
      '';
    };

    ssh.extraHosts = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = ''
        Additional ssh matchBlocks keyed by host name. Merged into
        programs.ssh.matchBlocks.
      '';
    };

    font = {
      nerdFamily = lib.mkOption {
        type = lib.types.str;
        default = "fira-code";
        description = ''
          Nerd Font family, matching the attribute name under
          pkgs.nerd-fonts (e.g. "fira-code", "jetbrains-mono", "hack").
        '';
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "FiraCode Nerd Font";
        description = ''
          Rendered font family name used by terminals and editors.
          Must match the font's actual family name after install.
        '';
      };
      size = lib.mkOption {
        type = lib.types.int;
        default = 13;
        description = "Default editor/terminal font size in points.";
      };
    };
  };
}
