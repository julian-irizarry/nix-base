{
  config,
  lib,
  pkgs,
  ...
}:

let
  zshCustomPrefix = "oh-my-zsh";
  # Stage a third-party plugin's source into $ZSH_CUSTOM/plugins/<plugin>/ so
  # oh-my-zsh's loader can find it by plain name. OMZ expects each plugin dir
  # to contain <plugin>/<plugin>.plugin.zsh.
  mkZshPlugin =
    {
      pkg,
      plugin ? pkg.pname,
    }:
    {
      "${zshCustomPrefix}/plugins/${plugin}" = {
        source = "${pkg.src}";
        recursive = true;
      };
    };
in
{
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.npm-global/bin"
  ];

  xdg.dataFile = lib.mergeAttrsList [
    (mkZshPlugin { pkg = pkgs.zsh-autopair; })
    (mkZshPlugin { pkg = pkgs.zsh-completions; })
    (mkZshPlugin {
      pkg = pkgs.zsh-fzf-tab;
      plugin = "fzf-tab";
    })
    (mkZshPlugin {
      pkg = pkgs.zsh-fast-syntax-highlighting;
      plugin = "fast-syntax-highlighting";
    })
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = false;

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "ssh"
        "kitty"
        # Order matters for these: completions must load before compinit,
        # fzf-tab must load after compinit but before any plugin that wraps
        # widgets, and fast-syntax-highlighting should load last so it can
        # wrap widgets registered by earlier plugins.
        "zsh-autopair"
        "zsh-completions"
        "fzf-tab"
        "fast-syntax-highlighting"
      ];
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

    shellAliases = {
      vim = "nvim";
      nd = "nix develop -vvv";
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
      ZSH_CUSTOM = "${config.xdg.dataHome}/${zshCustomPrefix}";
      GTEST_COLOR = "1";
    };

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        [ -f "$HOME/.zshenv.local" ] && source "$HOME/.zshenv.local"
      '')
      ''
        # Ring the bell after commands that take longer than 5s so
        # wezterm's visual_bell + inactive_tab_alert can surface it.
        zmodload zsh/datetime
        __notify_preexec() { typeset -gi __cmd_start=$EPOCHSECONDS }
        __notify_precmd() {
          (( __cmd_start > 0 && EPOCHSECONDS - __cmd_start >= 5 )) && printf '\a'
          __cmd_start=0
        }
        add-zsh-hook preexec __notify_preexec
        add-zsh-hook precmd __notify_precmd

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
