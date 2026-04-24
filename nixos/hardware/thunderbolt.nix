{ config, lib, ... }:

lib.mkIf config.sys.thunderbolt.enable {
  services.hardware.bolt.enable = true;
}
