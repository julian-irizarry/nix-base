{ config, pkgs, ... }:

{
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ config.sys.username ];
  };

  environment.systemPackages = with pkgs; [
    chromium
    obsidian
  ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (builtins.parseDrvName (pkg.name or pkg.pname or "")).name [
      "chromium"
      "obsidian"
      "1password"
      "1password-cli"
    ];
}
