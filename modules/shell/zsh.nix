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
    };

    sessionVariables = {
      EDITOR = "nvim";
      ZSH = "$HOME/.oh-my-zsh";
    };

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        [ -f "$HOME/.zshenv.local" ] && source "$HOME/.zshenv.local"
      '')
      ''
        bindkey "^[[A" .up-line-or-history
        bindkey "^[[B" .down-line-or-history

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
