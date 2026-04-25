{ config, lib, ... }:

lib.mkIf config.sys.desktop.cosmic.enable {
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  services.displayManager.autoLogin = lib.mkIf config.sys.autoLogin {
    enable = true;
    user = config.sys.username;
  };
}
