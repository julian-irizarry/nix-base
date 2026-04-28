{
  config,
  lib,
  pkgs,
  ...
}:

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  # nixGL is a Linux-only wrapper for non-NixOS OpenGL apps. Darwin ships
  # its own GL stack (Quartz / Metal) so the wrap is a no-op at best and
  # an eval error at worst (lib.nixGL.wrap isn't defined on Darwin since
  # mkHome only imports the provider module on Linux).
  my.platform.nixGL.enable = false;

  home.file.".ssh/config.d/identity-agent" = lib.mkIf config.my.ssh.onePassword.enable {
    text = ''
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    '';
  };
}
