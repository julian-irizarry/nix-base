{
  config,
  lib,
  pkgs,
  ...
}:

lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  # genericLinux provides XDG_DATA_DIRS wiring, TERMINFO_DIRS, nix.sh sourcing,
  # and the nixGL wrapper function used by GUI modules on non-NixOS.
  # On NixOS the system handles all of this natively.
  targets.genericLinux.enable = config.my.platform.nixGL.enable;

  # Write the 1Password SSH agent socket path into config.d so it is
  # included alongside hm-hosts.
  home.file.".ssh/config.d/identity-agent".text = ''
    IdentityAgent ~/.1password/agent.sock
  '';
}
