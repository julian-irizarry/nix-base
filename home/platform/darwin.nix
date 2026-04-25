{ lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  # Write the 1Password SSH agent socket path into config.d so it is
  # included alongside hm-hosts.  The Group Containers path has spaces,
  # hence the quoting.
  home.file.".ssh/config.d/identity-agent".text = ''
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  '';
}
