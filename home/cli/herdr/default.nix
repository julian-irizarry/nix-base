{ pkgs, ... }:

{
  # Patched to match the wezterm tabline: active tab in `selection_bg` with
  # Powerline caps, tinted process icons, and `accent = true` pills in
  # ui.tab_bar_right (stock herdr rejects it). Also unfilled popups (no black
  # half-cell outside the border), no prefix-mode hint bar, and focused pane
  # borders in `peach` rather than `accent`, and Shift+Enter as CSI-u for
  # legacy panes (zsh autosuggest-accept). The Go to navigator highlights like
  # the active tab, tints icons and takes h/l for workspaces next to j/k rows,
  # and q closes popups and navigate mode when nothing is taking text. A
  # `[terminal] new_workspace_cwd` setting gives new workspaces their own
  # starting directory, so it doesn't move new panes and tabs like `new_cwd`. This rebuilds herdr from source
  # (Rust + Zig, not on cache.nixos.org); if a nixpkgs bump stops the patch
  # applying, regenerate it against the new release. Tests are skipped because
  # upstream asserts the stock tab colors. config.toml and plugins stay
  # hand-managed: herdr's settings UI writes to the config.
  home.packages = [
    (pkgs.herdr.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./tab-colors.patch ];
      doCheck = false;
    }))
    # Holds the long-lived shell session behind herdr's prefix+t orchestrator
    # popup; the popup only runs `shpool attach`, so hiding it detaches.
    pkgs.shpool
  ];
}
