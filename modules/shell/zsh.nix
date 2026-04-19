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
      share = true;
    };

    shellAliases = {
      vim = "nvim";
      nd = "nix develop -vvv -c $SHELL";
      cd = "z";
      ls = "eza -a --icons=always";
      ll = "eza -lhag --icons=always";
      cat = "bat";
      grep = "grep --color=auto";
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
        bindkey '^R' .history-incremental-search-backward
        bindkey "^[[A" .up-line-or-history
        bindkey "^[[B" .down-line-or-history
        # Shift+Enter (paired with kitty's send_text all \x1b[13;2u) accepts
        # the zsh-autosuggestions ghost text without executing.
        bindkey '^[[13;2u' autosuggest-accept

        # Completion system tweaks.
        zstyle ':completion:*' auto-description 'specify: %d'
        zstyle ':completion:*' completer _expand _complete _correct _approximate
        zstyle ':completion:*' format 'Completing %d'
        zstyle ':completion:*' group-name ""
        zstyle ':completion:*' menu select=2
        zstyle ':completion:*:default' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*' list-colors ""
        zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
        zstyle ':completion:*' matcher-list "" 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
        zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
        zstyle ':completion:*' use-compctl false
        zstyle ':completion:*' verbose true
        zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
        zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

        autoload -Uz edit-command-line
        zle -N edit-command-line

        find_and_cd_widget() {
          local dir
          dir=$(fd --type d --hidden --follow --exclude .git . ~/ \
            | fzf --preview 'tree -C {} | head -100' \
                  --preview-window=right:50%:wrap \
                  --height=40% --layout=reverse)

          if [[ -n "$dir" ]]; then
            BUFFER="cd $dir"
            zle accept-line
          else
            zle reset-prompt
          fi
        }
        zle -N find_and_cd_widget
        bindkey '^F' find_and_cd_widget

        ag() { print -z "$(fc -ln -2 -2)"; }

        hms() { print -z "home-manager switch --flake .#x86_64-linux"; }

        [ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
      ''
      (lib.mkAfter (lib.concatStringsSep "\n" config.my.zsh.extraInitFragments))
    ];
  };
}
