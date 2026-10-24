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
  # Consumers set programs.nh.flake (NH_FLAKE) to their flake checkout so
  # `nh home switch` / `nh os switch` work from any directory.
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 5";
    };
  };
  # Database comes prebuilt from nix-index-database; enables command-not-found
  # suggestions in zsh and `, <cmd>` to run a package without installing it.
  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;
  programs.nix-your-shell.enable = true;
  programs.readline.enable = true;
  programs.tealdeer.enable = true;
  programs.uv.enable = true;

  home.packages =
    with pkgs;
    [
      nix-output-monitor
      pciutils
      usbutils
      file
      inetutils
      dnsutils
      nmap
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
      nil
      nixd
      pyright
      rust-analyzer
      stylua
      tree-sitter
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      lshw
      dmidecode
      powertop
      wl-clipboard
    ];
}
