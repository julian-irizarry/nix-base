{ pkgs, lib, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  # home-manager overrides NIX_XDG_DESKTOP_PORTAL_DIR to its per-user profile
  # path so xdg-desktop-portal only sees portals installed there. Adding the
  # cosmic portal package here puts cosmic.portal into that search path.
  home.packages = [ pkgs.xdg-desktop-portal-cosmic ];

  # Custom keyboard shortcuts. COSMIC Settings > Keyboard > Custom Shortcuts
  # writes to this file atomically (temp + rename), which breaks the symlink
  # between hm switches; force = true ensures it's restored on each switch.
  xdg.configFile."cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom" = {
    force = true;
    text = ''
      {
          (modifiers: [Ctrl], key: "space"): Spawn("vicinae toggle"),
          (modifiers: [Super], key: "Return"): Spawn("wezterm"),
      }
    '';
  };
}
