{
  config,
  lib,
  pkgs,
  ...
}:

lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  # TODO: drop when migrating to NixOS — it handles XDG wiring natively.
  # On non-NixOS distros the graphical session doesn't know about nix
  # profiles, so .desktop entries are invisible to GNOME without this.
  xdg.systemDirs.data = [
    "${config.home.profileDirectory}/share"
    "/nix/var/nix/profiles/default/share"
  ];
}
