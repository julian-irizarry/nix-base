# NixOS VM integration tests for the nix-base modules.
#
# These tests boot a QEMU VM and verify that services, users, and
# configuration are wired correctly. COSMIC DE is excluded — it
# requires a GPU and cannot run in a headless test VM.
#
# Run: nix build .#checks.x86_64-linux.nixos-vm
{
  nixpkgs,
  home-manager,
  homeModulesDefault,
}:

let
  # Import the test framework with unfree allowed — obsidian/1password need it.
  pkgs = import nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };

  # Base module set shared by all test VMs. Imports the full nixos/
  # module tree but excludes COSMIC (no GPU in test VMs).
  baseTestModule =
    { lib, ... }:
    {
      imports = [
        ../options.nix
        ../boot
        ../hardware/nvidia.nix
        ../hardware/firmware.nix
        ../hardware/thunderbolt.nix
        ../networking
        ../nix
        ../programs
        ../security
        ../services/audio.nix
        ../services/bluetooth.nix
        ../services/docker.nix
        ../services/printing.nix
        ../services/swap.nix
        ../users
        ../virtualisation
      ];

      time.timeZone = "America/New_York";
      i18n.defaultLocale = "en_US.UTF-8";
      system.stateVersion = lib.mkDefault "25.05";
    };
in
pkgs.testers.runNixOSTest {
  name = "nix-base-integration";

  nodes.machine =
    { ... }:
    {
      imports = [
        baseTestModule
        home-manager.nixosModules.home-manager
      ];

      sys.hostname = "test-vm";
      sys.username = "testuser";
      sys.docker.enable = true;
      sys.printing.enable = true;

      # Integrate home-manager for user config testing
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.testuser = {
        imports = homeModulesDefault;
        my.git.userName = "Test User";
        my.git.userEmail = "test@example.com";
        my.platform.nixGL.enable = false;
        home.stateVersion = "25.05";
      };

      virtualisation.memorySize = 2048;
      virtualisation.cores = 2;
    };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")

    # --- Hostname ---
    with subtest("hostname is set correctly"):
        hostname = machine.succeed("hostname").strip()
        assert hostname == "test-vm", f"expected 'test-vm', got '{hostname}'"

    # --- User account ---
    with subtest("user account exists with correct groups"):
        machine.succeed("id testuser")
        groups = machine.succeed("groups testuser")
        assert "wheel" in groups, f"testuser not in wheel: {groups}"
        assert "networkmanager" in groups, f"testuser not in networkmanager: {groups}"
        assert "docker" in groups, f"testuser not in docker: {groups}"
        assert "libvirtd" in groups, f"testuser not in libvirtd: {groups}"

    with subtest("zsh is the login shell"):
        shell = machine.succeed("getent passwd testuser | cut -d: -f7").strip()
        assert "zsh" in shell, f"expected zsh, got {shell}"

    # --- System services ---
    with subtest("NetworkManager is running"):
        machine.wait_for_unit("NetworkManager.service")

    with subtest("Docker is running"):
        machine.wait_for_unit("docker.service")
        machine.succeed("docker info")

    with subtest("CUPS socket is available"):
        machine.succeed("test -e /run/cups/cups.sock || systemctl is-enabled cups.socket")

    with subtest("libvirtd is running"):
        machine.wait_for_unit("libvirtd.service")

    with subtest("firewall is enabled"):
        machine.wait_for_unit("firewall.service")

    with subtest("1password CLI is installed"):
        machine.succeed("test -e /run/current-system/sw/bin/op")

    # --- Nix configuration ---
    with subtest("flakes are enabled"):
        machine.succeed("nix --version")
        machine.succeed("nix flake --help")

    # --- Home-manager integration (user session tests last) ---
    with subtest("home-manager generation exists"):
        machine.succeed("test -L /home/testuser/.local/state/home-manager/gcroots/current-home")

    with subtest("git is configured"):
        result = machine.succeed("su - testuser -c 'git config --global user.name'").strip()
        assert result == "Test User", f"expected 'Test User', got '{result}'"
        result = machine.succeed("su - testuser -c 'git config --global user.email'").strip()
        assert result == "test@example.com", f"expected 'test@example.com', got '{result}'"

    with subtest("neovim is available"):
        machine.succeed("su - testuser -c 'which nvim'")

    with subtest("PipeWire is configured"):
        machine.succeed("test -e /etc/systemd/user/pipewire.service || test -e /etc/systemd/user/default.target.wants/pipewire.service || find /etc/systemd/user -name 'pipewire*' | grep -q pipewire")
  '';
}
