{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.stateVersion = lib.mkDefault "25.05";

  # Apps sometimes replace a managed symlink with a real file (atomic
  # temp+rename saves). Move it aside instead of failing the switch;
  # overwrite so a repeat offender doesn't fail on the previous backup.
  home.backupFileExtension = lib.mkDefault "hm-bak";
  home.overwriteBackup = lib.mkDefault true;
  home.homeDirectory = lib.mkDefault (
    if pkgs.stdenv.hostPlatform.isDarwin then
      "/Users/${config.home.username}"
    else
      "/home/${config.home.username}"
  );
}
