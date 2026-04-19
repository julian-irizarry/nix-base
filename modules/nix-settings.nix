{ config, lib, ... }:

{
  home.sessionVariables = lib.mkIf (config.my.nix.extraNixPath != [ ]) {
    NIX_PATH = lib.concatStringsSep ":" config.my.nix.extraNixPath;
  };

  xdg.configFile."nix/nix.conf".text = ''
    experimental-features = nix-command flakes
  '';
}
