{ ... }:

{
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  systemd.services.virt-secret-init-encryption.enable = false;
}
