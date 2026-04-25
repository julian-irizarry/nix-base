{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

let
  # At this scope `config` is the outer (non-installer) evaluation, before
  # iso-image.nix layers on the live-ISO root filesystem and strips the target
  # bootloader. So targetToplevel and diskoScript here describe the system we
  # want on disk, not the ISO itself.
  targetToplevel = config.system.build.toplevel;

  installScript = pkgs.writeShellApplication {
    name = "install-image";
    runtimeInputs = with pkgs; [
      nixos-install-tools
      util-linux
      cryptsetup
      lvm2
    ];
    text = ''
      if ! mountpoint -q /iso; then
        echo "ERROR: install-image should only be run from a live ISO environment."
        echo "       Refusing to run on an installed system to prevent data loss."
        exit 1
      fi

      echo "NixOS Offline Installer"
      echo "======================="
      echo "System closure: ${targetToplevel}"
      echo ""
      echo "WARNING: This will format disks according to the disko configuration."
      read -rp "Type YES to continue: " confirm
      [ "$confirm" = "YES" ] || { echo "Aborted."; exit 1; }

      echo ""
      echo "=== Step 1: Partitioning and formatting with disko ==="
      ${config.system.build.diskoScript}

      echo ""
      echo "=== Step 2: Installing NixOS (offline) ==="
      nixos-install \
        --system ${targetToplevel} \
        --no-root-passwd \
        --no-channel-copy \
        --option substituters ""

      echo ""
      echo "=== Done — reboot into your new system ==="
    '';
  };
in
{
  imports = [ inputs.disko.nixosModules.disko ];

  image.modules.iso-installer = {
    environment.systemPackages = [
      installScript
      pkgs.parted
    ];

    # Drop ZFS from the live ISO. Upstream nixpkgs occasionally ships a
    # broken zfs-kernel for the latest kernel, and isoImage.contents pulls
    # it via boot.initrd.systemd's storePaths. We only need btrfs/vfat/ext4
    # in the installer environment; the target system module set decides
    # what the installed system supports.
    boot.supportedFilesystems.zfs = lib.mkForce false;

    # Suppress the host's swap config in the live ISO. The host's
    # sys.swap.{path,enableHibernate} settings describe the *installed*
    # system, not the live USB — a hibernate-wired swapfile makes no sense
    # in a tmpfs-rooted installer environment, and would cause
    # boot.resumeDevice to resolve to the tmpfs root device.
    sys.swap.size = lib.mkForce null;
  };
}
