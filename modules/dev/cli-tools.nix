{ pkgs, ... }:

{
  programs.bat.enable = true;
  programs.eza.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.gh.enable = true;
  programs.less.enable = true;
  programs.man.enable = true;
  programs.readline.enable = true;
  programs.uv.enable = true;

  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    yq-go
    tree
    wget
    curl
    unzip
    zip
    xclip
    btop
    gnumake
    pkg-config
    rustup
  ];
}
