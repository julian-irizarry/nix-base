{ config, lib, ... }:

lib.mkIf config.sys.docker.enable {
  virtualisation.docker.enable = true;

  users.users.${config.sys.username}.extraGroups = [ "docker" ];
}
