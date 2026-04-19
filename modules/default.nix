{ pkgs, lib, ... }:

{
  imports = [
    ./options.nix
    ./unfree.nix
    ./home-defaults.nix
    ./fonts.nix
    ./git.nix
    ./dev/cli-tools.nix
    ./dev/vscode.nix
    ./shell/zsh.nix
    ./shell/prompt.nix
  ];
}
