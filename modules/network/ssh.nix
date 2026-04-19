{ config, ... }:

{
  programs.ssh = {
    enable = true;
    matchBlocks = config.my.ssh.extraHosts;
  };
}
