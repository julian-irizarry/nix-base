{ lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  # Placeholder. Darwin-specific wiring will land here (e.g. 1Password
  # SSH agent IdentityAgent path once we configure 1Password).
}
