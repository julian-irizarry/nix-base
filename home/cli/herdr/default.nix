{ pkgs, lib, ... }:

let
  herdr = pkgs.herdr.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./tab-colors.patch ];
    doCheck = false;
  });
in
{
  # Patched to match the wezterm tabline: active tab in `selection_bg` with
  # Powerline caps, tinted process icons, and `accent = true` pills in
  # ui.tab_bar_right (stock herdr rejects it). Also unfilled popups (no black
  # half-cell outside the border), no prefix-mode hint bar, and focused pane
  # borders in `peach` rather than `accent`, and Shift+Enter as CSI-u for
  # legacy panes (zsh autosuggest-accept). The Go to navigator highlights like
  # the active tab, tints icons and takes h/l for workspaces next to j/k rows,
  # and q closes popups and navigate mode when nothing is taking text. A
  # `[terminal] new_workspace_cwd` setting gives new workspaces their own
  # starting directory, so it doesn't move new panes and tabs like `new_cwd`. This rebuilds herdr from source
  # (Rust + Zig, not on cache.nixos.org); if a nixpkgs bump stops the patch
  # applying, regenerate it against the new release. Tests are skipped because
  # upstream asserts the stock tab colors. config.toml and plugins stay
  # hand-managed: herdr's settings UI writes to the config.
  home.packages = [
    herdr
    # Holds the long-lived shell session behind herdr's prefix+t orchestrator
    # popup; the popup only runs `shpool attach`, so hiding it detaches.
    pkgs.shpool
  ];

  # The default session's server runs as its own unit so it's no longer in the
  # cgroup of whichever terminal started it: under wezterm's scope one OOM kill
  # (OOMPolicy=stop) took down wezterm, the server and every pane. The client
  # connects to this server rather than spawning its own. OOMPolicy=continue
  # keeps a killed pane process (rust-analyzer, rustc) from stopping the unit.
  # Live handoff starts the new server as a child, then the old one exits, so
  # ExitType=cgroup keeps the unit up until the whole cgroup is gone. keep-old
  # stops a home-manager switch from restarting the server and killing panes;
  # the next client to connect hands off to the new binary.
  #
  # Every pane process counts against the memory limits, including the
  # rust-analyzer an agent's LSP plugin starts. At MemoryMax the kernel
  # OOM-kills the biggest process inside herdr instead of something on the
  # desktop; MemoryHigh throttles it just before that. MemorySwapMax stops a
  # runaway pane from thrashing through all of swap before it gets there.
  # systemd-oomd kills a whole cgroup under sustained pressure in user@.service,
  # which would take every pane with it, so herdr is the last thing it picks.
  systemd.user.services.herdr = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    Unit = {
      Description = "herdr server (default session)";
      After = [ "graphical-session.target" ];
      X-SwitchMethod = "keep-old";
    };
    Service = {
      ExecStart = "${herdr}/bin/herdr server";
      ExitType = "cgroup";
      OOMPolicy = "continue";
      MemoryHigh = "60%";
      MemoryMax = "70%";
      MemorySwapMax = "4G";
      ManagedOOMPreference = "avoid";
      Restart = "on-failure";
      RestartSec = 5;
    };
    # graphical-session.target is reached after GDM imports PATH, SSH_AUTH_SOCK
    # and DISPLAY into systemd --user, which panes inherit from the server.
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
