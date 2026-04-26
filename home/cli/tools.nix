{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.bat.enable = true;
  programs.dircolors.enable = true;
  programs.difftastic.enable = true;
  programs.eza = {
    enable = true;
    extraOptions = [
      "--group-directories-first"
      "--git"
    ];
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config.whitelist.prefix = [ "${config.home.homeDirectory}/sources" ];
    # Store .direnv layouts under $XDG_CACHE_HOME keyed by project-path hash
    # instead of polluting each project root with a .direnv/ directory.
    stdlib = ''
      declare -A direnv_layout_dirs
      direnv_layout_dir() {
        echo "''${direnv_layout_dirs[$PWD]:=$(
          echo -n "${config.xdg.cacheHome}/direnv/layouts/"
          echo -n "$PWD" | shasum | cut -d ' ' -f 1
        )}"
      }
    '';
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
  programs.nh.enable = true;
  programs.nix-your-shell.enable = true;
  programs.readline.enable = true;
  programs.tealdeer.enable = true;
  programs.uv.enable = true;

  home.packages = with pkgs; [
    nix-output-monitor
    pciutils
    usbutils
    lshw
    file
    inetutils
    dnsutils
    nmap
    powertop
    llvmPackages.llvm
    ripgrep
    fd
    jq
    yq-go
    tree
    wget
    curl
    unzip
    zip
    wl-clipboard
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
    tree-sitter
  ];
}
