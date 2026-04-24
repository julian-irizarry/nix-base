{ config, lib, ... }:

lib.mkIf config.sys.bluetooth.enable {
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
}
