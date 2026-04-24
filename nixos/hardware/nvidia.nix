{ config, lib, ... }:

lib.mkIf config.sys.nvidia.enable {
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = false;
    powerManagement.enable = true;
    powerManagement.finegrained = false;

    prime = lib.mkIf config.sys.nvidia.prime.enable {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = config.sys.nvidia.prime.intelBusId;
      nvidiaBusId = config.sys.nvidia.prime.nvidiaBusId;
    };
  };

  boot.kernelParams = [ "nvidia-drm.modeset=1" ];
}
