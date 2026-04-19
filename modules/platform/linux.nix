{ lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  # TODO: drop when migrating to NixOS — it handles all of this natively.
  # Provides XDG_DATA_DIRS wiring, TERMINFO_DIRS, nix.sh sourcing, and the
  # nixGL wrapper function used by GUI modules to wrap GPU apps.
  targets.genericLinux.enable = true;
}
