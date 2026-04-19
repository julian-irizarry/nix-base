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
  # Ubuntu's /usr/lib/environment.d/990-snapd.conf only seeds /usr/share
  # via ''${XDG_DATA_DIRS:-default}; once we set XDG_DATA_DIRS here that
  # fallback never fires, so we have to list the FHS dirs explicitly or
  # gnome-session can't find its GSettings schemas and the session fails.
  xdg.systemDirs.data = [
    "${config.home.profileDirectory}/share"
    "/nix/var/nix/profiles/default/share"
    "/usr/local/share"
    "/usr/share"
  ];
}
