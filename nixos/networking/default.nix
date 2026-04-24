{ config, ... }:

{
  networking.hostName = config.sys.hostname;
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
}
