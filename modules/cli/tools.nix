{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.bat.enable = true;
  programs.eza.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config.whitelist.prefix = [ "${config.home.homeDirectory}/sources" ];
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.broot = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.gh.enable = true;
  programs.home-manager.enable = true;
  programs.lazygit.enable = true;
  programs.less.enable = true;
  programs.man.enable = true;
  programs.readline.enable = true;
  programs.tealdeer.enable = true;
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
    (lib.lowPrio rustup)
    just
    hyperfine
    watchexec
    # LSP servers and formatters
    bash-language-server
    clang-tools
    gopls
    lua-language-server
    nixd
    pyright
    rust-analyzer
    stylua
    # Treesitter main-branch compiles parsers locally; needs the CLI.
    tree-sitter
  ];
}
