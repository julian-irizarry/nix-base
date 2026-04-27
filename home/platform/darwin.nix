{ lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  # nixGL is a Linux-only wrapper for non-NixOS OpenGL apps. Darwin ships
  # its own GL stack (Quartz / Metal) so the wrap is a no-op at best and
  # an eval error at worst (lib.nixGL.wrap isn't defined on Darwin since
  # mkHome only imports the provider module on Linux).
  my.platform.nixGL.enable = false;

  # Write the 1Password SSH agent socket path into config.d so it is
  # included alongside hm-hosts.  The Group Containers path has spaces,
  # hence the quoting.
  home.file.".ssh/config.d/identity-agent".text = ''
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  '';
}
