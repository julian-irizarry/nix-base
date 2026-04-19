{ pkgs, lib, ... }:

{
  imports = [
    ./options.nix
    ./unfree.nix
    ./home-defaults.nix
    ./fonts.nix
    ./git.nix
    ./ssh.nix
    ./nix-settings.nix
    ./dev/cli-tools.nix
    ./dev/tmux.nix
    ./dev/vscode.nix
    ./shell/zsh.nix
    ./shell/prompt.nix
  ];
}
