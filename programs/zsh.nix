{ pkgs, dotfiles, ... }:

{
  home.sessionPath = [
    "$HOME/.npm-global/bin"
    "$HOME/.local/bin"
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

    initExtra = ''
      [ -f "$HOME/.zshenv" ] && source "$HOME/.zshenv"

      # oh-my-posh prompt
      eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/omp.json)"

      # fzf extras (history/file search already set by programs.fzf)
      # Custom keybindings
      bindkey "^[[A" .up-line-or-history
      bindkey "^[[B" .down-line-or-history

      autoload -Uz edit-command-line
      zle -N edit-command-line

      # --- Custom fd + fzf "find and cd" widget ---
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

      ag() {
        print -z "$(fc -ln -2 -2)"
      }

      hms() {
        print -z "home-manager switch --flake .#julian"
      }
    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide.enable = true;

  home.file.".config/oh-my-posh/omp.json".source = "${dotfiles}/.config/oh-my-posh/omp.json";
}
