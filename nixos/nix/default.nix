{ config, lib, ... }:

{
  imports = [ ./determinate.nix ];

  nix.settings = lib.mkMerge [
    {
      trusted-users = [ "root" ] ++ config.sys.nix.trustedUsers;
      extra-substituters = lib.mkAfter config.sys.nix.extraSubstituters;
      extra-trusted-public-keys = lib.mkAfter config.sys.nix.extraTrustedPublicKeys;
    }
    config.sys.nix.extraSettings
    (lib.mkIf (config.sys.nix.netrcFile != null) {
      netrc-file = config.sys.nix.netrcFile;
    })
    (lib.mkIf (!config.sys.determinate.enable) {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    })
  ];

  nix.distributedBuilds = lib.mkIf config.sys.nix.distributedBuilds true;

  nix.gc = lib.mkIf (!config.sys.determinate.enable) {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
