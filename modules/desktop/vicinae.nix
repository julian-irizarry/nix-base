{ pkgs, lib, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  # Vicinae — Raycast-style launcher for Linux. The module comes from the
  # vicinae flake input (see lib/mkHome.nix). We pin package to pkgs.vicinae
  # so builds skip the upstream cachix and cache through nixpkgs instead.
  services.vicinae = {
    enable = true;
    package = pkgs.vicinae;
    systemd = {
      enable = true;
      autoStart = true;
    };
  };
}
