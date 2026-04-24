{ config, ... }:

{
  imports = [
    ./options.nix
    ./boot
    ./desktop/cosmic.nix
    ./hardware/nvidia.nix
    ./hardware/firmware.nix
    ./hardware/thunderbolt.nix
    ./networking
    ./nix
    ./programs
    ./security
    ./services/audio.nix
    ./services/bluetooth.nix
    ./services/docker.nix
    ./services/printing.nix
    ./services/swap.nix
    ./users
    ./virtualisation
  ];

  time.timeZone = config.sys.timezone;
  i18n.defaultLocale = config.sys.locale;
}
