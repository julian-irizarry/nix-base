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
    ./dev/kitty.nix
    ./dev/neovim.nix
    ./dev/vscode.nix
    ./shell/zsh.nix
    ./shell/prompt.nix
    ./platform/linux.nix
    ./platform/darwin.nix
  ];
}
