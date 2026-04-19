{ pkgs, lib, ... }:

{
  imports = [
    ./options.nix
    ./home-defaults.nix
    ./git.nix
    ./dev/cli-tools.nix
    ./shell/zsh.nix
  ];
}
