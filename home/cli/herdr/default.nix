{ pkgs, lib, ... }:

let
  # Patches are an ordered stack, generated from the herdr checkout next to
  # nix-base (branch jrizzy/local-patches, one commit or merge per file):
  #   git diff <prev> <next> > home/cli/herdr/<name>.patch
  # Later patches rework hunks of tab-colors.patch, so apply them in order.
  herdr = pkgs.herdr.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      # The original personal patch: tab look, navigator restyle, process icon
      # colors, popups, q/h/l keys, Shift+Enter, new_workspace_cwd. Most of its
      # behavior is now config, the later patches route it through options.
      ./tab-colors.patch
      # `[ui.status_icons]`: per-state icons, animated spinner, icon colors.
      ./status-icons.patch
      # Docs for `[terminal] new_workspace_cwd`.
      ./workspace-cwd.patch
      # `[ui] hide_prefix_mode_bar` and `[terminal] shift_enter_csi_u`, both
      # opt-in instead of always on.
      ./ui-toggles.patch
      # `[theme.elements]`: named UI slots over the palette (full catalog),
      # `[ui.tab_bar] active_caps`, and `style`/`padding` on tab_bar_right
      # entries. Replaces the hardcoded tab, border, popup, navigator and
      # accent-pill styling; only the process icon colors stay hardcoded.
      ./theme-elements.patch
    ];
    # The full suite passes outside the sandbox except three tests that fail on
    # stock v0.9.5 here too; skipped to keep rebuilds fast.
    doCheck = false;
  });
in
{
  # Everything the patches add is opt-in: with no matching config keys herdr
  # renders and behaves like stock. My look lives in config.toml
  # ([theme.elements], [ui.status_icons], tab_bar_right styles, ...).
  #
  # This rebuilds herdr from source (Rust + Zig, not on cache.nixos.org); if a
  # nixpkgs bump stops the patches applying, rebase jrizzy/local-patches onto
  # the new release in the herdr checkout and regenerate the stack.
  # config.toml and plugins stay hand-managed: herdr's settings UI writes to
  # the config.
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
  # stops a home-manager switch from restarting the server and killing panes.
  # herdr's live handoff is opt-in and doesn't run for Nix installs, so after
  # a switch a reattached client runs the new binary against the old server:
  # client-side changes apply right away, server-side ones need
  # `herdr server stop` (kills panes; supported agents resume).
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
