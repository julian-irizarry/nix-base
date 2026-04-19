{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.npm-global/bin"
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" ];
    };

    history = {
      size = 100000;
      save = 100000;
      ignoreAllDups = true;
      ignoreSpace = true;
      extended = true;
      share = true;
    };

    historySubstringSearch = {
      enable = true;
      searchUpKey = [ "^P" ];
      searchDownKey = [ "^N" ];
    };

    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];

    shellAliases = {
      vim = "nvim";
      nd = "nix develop -vvv -c $SHELL";
      ls = "eza -a --icons=always";
      ll = "eza -lhag --icons=always";
      cat = "bat";
      grep = "rg";
      diff = "diff --color=auto";
      ip = "ip -color=auto";
    };

    sessionVariables = {
      EDITOR = "nvim";
      ZSH = "$HOME/.oh-my-zsh";
      GTEST_COLOR = "1";
    };

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        [ -f "$HOME/.zshenv.local" ] && source "$HOME/.zshenv.local"
      '')
      ''
        # Shift+Enter (paired with kitty's send_text all \x1b[13;2u) accepts
        # the zsh-autosuggestions ghost text without executing.
        bindkey '^[[13;2u' autosuggest-accept

        ag() { print -z "$(fc -ln -2 -2)"; }

        hms() { print -z "home-manager switch --flake .#x86_64-linux"; }

        [ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
      ''
      (lib.mkAfter (lib.concatStringsSep "\n" config.my.zsh.extraInitFragments))
    ];
  };
}
