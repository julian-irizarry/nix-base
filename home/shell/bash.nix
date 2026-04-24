{
  # GDM sources ~/.profile in the login shell before Xsession.d imports
  # the resulting environment into systemd --user. programs.bash.enable
  # generates a .profile that sources hm-session-vars.sh, which in turn
  # sources nix.sh (via targets.genericLinux) — so the graphical session
  # inherits a PATH with nix profile bin dirs. Without this, GNOME's
  # launcher filters out nix .desktop entries because TryExec can't find
  # the binaries.
  programs.bash.enable = true;
}
