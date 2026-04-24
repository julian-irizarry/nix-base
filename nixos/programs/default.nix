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
}
