{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Core utilities
    wget
    curl
    btop
    ripgrep
    fd
    tree
    jq
    unzip
    gnupg
    zip
    xclip
    oh-my-posh
    tmux
    virt-top

    # Dev toolchains (add/remove as needed)
    git-crypt
    nodejs
    python3
    rustup
    cmake
    ninja
    clang
    llvmPackages_latest.lldb # debugger for clang
    autoconf
    automake
    libtool
    gnumake
    gdb
    pkg-config
    nixd
    git-credential-manager
    pre-commit
    nixfmt-rfc-style
    compiledb

    # GUI apps
    vlc
    obsidian
    spotify
    google-chrome
  ];
}
