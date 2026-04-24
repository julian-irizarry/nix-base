{ config, lib, ... }:

lib.mkIf (config.sys.swap.size != null) {
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = config.sys.swap.size;
    }
  ];

  boot.resumeDevice = lib.mkIf config.sys.swap.enableHibernate "/var/lib/swapfile";
}
