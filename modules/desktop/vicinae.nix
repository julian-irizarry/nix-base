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
      # nix-built Qt6 can't find a hardware GL driver on non-NixOS
      # (Ubuntu has no /run/opengl-driver). Force the software scenegraph
      # so RHI init doesn't fatal-out when the window first opens.
      environment.QT_QUICK_BACKEND = "software";
    };
  };
}
