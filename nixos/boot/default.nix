{
  config,
  lib,
  pkgs,
  ...
}:

{
  boot.loader = lib.mkMerge [
    { efi.canTouchEfiVariables = true; }
    (lib.mkIf (config.sys.boot.loader == "systemd-boot") {
      systemd-boot.enable = true;
    })
    (lib.mkIf (config.sys.boot.loader == "grub") {
      efi.efiSysMountPoint = "/boot/efi";
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        enableCryptodisk = true;
      };
    })
  ];

  boot.initrd.systemd = lib.mkIf config.sys.boot.fido2Unlock.enable {
    enable = true;
    fido2.enable = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
