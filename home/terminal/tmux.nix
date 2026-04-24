{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    keyMode = "vi";
    mouse = true;
    baseIndex = 1;
    escapeTime = 10;
    historyLimit = 50000;

    plugins = with pkgs.tmuxPlugins; [
      sensible
      vim-tmux-navigator
      yank
    ];

    extraConfig = ''
      set -ga terminal-overrides ",*256col*:Tc"

      # Let kitty's graphics and keyboard protocol escapes reach the outer
      # terminal so image previews (yazi, image.nvim, kitten icat) and
      # disambiguated keys (e.g. Shift+Enter) still work inside tmux.
      set -g allow-passthrough on

      # Refresh TERM/TERM_PROGRAM in new panes when reattaching from a
      # different terminal so tools detect the current terminal's
      # capabilities correctly.
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM

      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      bind -n M-h select-pane -L
      bind -n M-j select-pane -D
      bind -n M-k select-pane -U
      bind -n M-l select-pane -R
    '';
  };
}
