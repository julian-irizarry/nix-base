{ pkgs, ... }:

let
  cycleLayout = pkgs.writeShellScriptBin "hypr-cycle-layout" ''
    current=$(${pkgs.hyprland}/bin/hyprctl getoption general:layout -j | ${pkgs.jq}/bin/jq -r '.str')
    case "$current" in
      dwindle) next=master ;;
      master)  next=dwindle ;;
      *)       next=dwindle ;;
    esac
    ${pkgs.hyprland}/bin/hyprctl keyword general:layout "$next"
  '';
in
{
  inherit cycleLayout;

  binds = [
    "SUPER, h, movefocus, l"
    "SUPER, j, movefocus, d"
    "SUPER, k, movefocus, u"
    "SUPER, l, movefocus, r"

    "SUPER SHIFT, h, swapwindow, l"
    "SUPER SHIFT, j, swapwindow, d"
    "SUPER SHIFT, k, swapwindow, u"
    "SUPER SHIFT, l, swapwindow, r"

    "SUPER, 1, workspace, 1"
    "SUPER, 2, workspace, 2"
    "SUPER, 3, workspace, 3"
    "SUPER, 4, workspace, 4"
    "SUPER, 5, workspace, 5"
    "SUPER, 6, workspace, 6"
    "SUPER, 7, workspace, 7"
    "SUPER, 8, workspace, 8"
    "SUPER, 9, workspace, 9"

    "SUPER SHIFT, 1, movetoworkspace, 1"
    "SUPER SHIFT, 2, movetoworkspace, 2"
    "SUPER SHIFT, 3, movetoworkspace, 3"
    "SUPER SHIFT, 4, movetoworkspace, 4"
    "SUPER SHIFT, 5, movetoworkspace, 5"
    "SUPER SHIFT, 6, movetoworkspace, 6"
    "SUPER SHIFT, 7, movetoworkspace, 7"
    "SUPER SHIFT, 8, movetoworkspace, 8"
    "SUPER SHIFT, 9, movetoworkspace, 9"

    "SUPER, W, killactive"
    "SUPER, F, fullscreen, 1"
    "SUPER, G, togglefloating"

    "SUPER, O, togglesplit"
    "SUPER SHIFT, O, exec, ${cycleLayout}/bin/hypr-cycle-layout"

    ", Print, exec, hyprshot -m region --freeze"

    "SUPER, Return, exec, wezterm"
    "CTRL, Space, exec, vicinae toggle"

    "SUPER, Escape, exec, noctalia-shell ipc call lockScreen lock"

    "SUPER, Super_L, hyprexpo:expo, toggle"

    "SUPER, Space, exec, noctalia-shell ipc call launcher toggle"
  ];
}
