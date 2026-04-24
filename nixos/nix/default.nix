{ config, lib, ... }:

{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    substituters = lib.mkAfter config.sys.nix.extraSubstituters;
    trusted-public-keys = lib.mkAfter config.sys.nix.extraTrustedPublicKeys;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
