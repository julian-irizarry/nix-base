{
  config,
  lib,
  pkgs,
  ...
}:

lib.mkIf config.sys.desktop.cosmic.enable {
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  services.displayManager.autoLogin = lib.mkIf config.sys.autoLogin {
    enable = true;
    user = config.sys.username;
  };

  # cosmic-screenshot (and other apps) use the Screenshot portal interface.
  # The NixOS COSMIC module does not wire this automatically; without the
  # portal backend, cosmic-screenshot panics with PortalNotFound.
  #
  # configPackages alone is insufficient: home-manager overrides
  # NIX_XDG_DESKTOP_PORTAL_DIR to the per-user profile path (because
  # wayland.windowManager.hyprland installs xdg-desktop-portal-hyprland
  # there), so xdg-desktop-portal never sees the system-profile cosmic.portal.
  # Using xdg.portal.config generates /etc/xdg/xdg-desktop-portal/COSMIC-portals.conf
  # which is read from XDG_CONFIG_DIRS regardless of the portal search path.
  # The per-user cosmic portal package is added via home.packages in
  # home/desktop/cosmic.nix so the implementation is also in NIX_XDG_DESKTOP_PORTAL_DIR.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-cosmic ];
    config.COSMIC = {
      default = [
        "cosmic"
        "gtk"
      ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    };
  };
}
