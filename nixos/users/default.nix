{ config, pkgs, ... }:

{
  users.users.${config.sys.username} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "libvirtd"
      "video"
      "render"
    ];
  };

  programs.zsh.enable = true;
}
