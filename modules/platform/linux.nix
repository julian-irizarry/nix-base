{ lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  # environment.d is read by systemd --user before the graphical session
  # launches; home.sessionVariables only reaches child shells, so .desktop
  # entries from nix profiles would otherwise be invisible to the DE.
  home.file.".config/environment.d/10-nix.conf".text = ''
    XDG_DATA_DIRS=''${XDG_DATA_DIRS}:''${HOME}/.nix-profile/share:/nix/var/nix/profiles/default/share
  '';
}
