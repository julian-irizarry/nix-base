{ lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  # Placeholder. Run `chsh -s $(which zsh)` manually on fresh machines.
}
