{ config, lib, ... }:

{
  home.sessionVariables = lib.mkIf (config.my.nix.extraNixPath != [ ]) {
    NIX_PATH = lib.concatStringsSep ":" config.my.nix.extraNixPath;
  };
}
