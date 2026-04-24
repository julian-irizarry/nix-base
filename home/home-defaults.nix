{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.stateVersion = lib.mkDefault "25.05";
  home.homeDirectory = lib.mkDefault (
    if pkgs.stdenv.hostPlatform.isDarwin then
      "/Users/${config.home.username}"
    else
      "/home/${config.home.username}"
  );
}
