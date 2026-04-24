{ config, lib, ... }:

{
  security.polkit.enable = true;
  security.rtkit.enable = true;

  services.fprintd.enable = lib.mkIf config.sys.fingerprint.enable true;
}
