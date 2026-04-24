{ config, lib, ... }:

lib.mkIf config.sys.printing.enable {
  services.printing.enable = true;
}
