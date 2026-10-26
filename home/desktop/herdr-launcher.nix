{
  config,
  lib,
  pkgs,
  ...
}:

let
  bin = "${config.home.profileDirectory}/bin";

  # Raycast lists installed apps with their bundle icon, so a tiny .app gives
  # a launcher entry with the herdr logo without registering a Raycast
  # extension by hand. Absolute paths because launchd's PATH is minimal.
  launcher = pkgs.writeShellScript "herdr-launcher" ''
    wezterm=${bin}/wezterm
    jq=${pkgs.jq}/bin/jq

    # Focus a wezterm window that is already running herdr, found by looking
    # for a herdr process on each pane's tty. Each GUI instance has its own
    # socket, named after its pid.
    for pid in $(/usr/bin/pgrep -x wezterm-gui); do
      export WEZTERM_UNIX_SOCKET="$HOME/.local/share/wezterm/gui-sock-$pid"
      panes=$("$wezterm" cli list --format json 2>/dev/null) || continue
      for row in $(echo "$panes" | "$jq" -r '.[] | "\(.pane_id):\(.tty_name)"'); do
        tty=''${row#*:}
        if /bin/ps -t "''${tty#/dev/}" -o comm= | /usr/bin/grep -q '\(^\|/\)herdr$'; then
          "$wezterm" cli activate-pane --pane-id "''${row%%:*}"
          exec /usr/bin/open -b com.github.wez.wezterm
        fi
      done
    done

    exec "$wezterm" start -- ${bin}/herdr
  '';

  herdrApp = pkgs.runCommand "herdr-launcher" { nativeBuildInputs = [ pkgs.libicns ]; } ''
    app=$out/Applications/Herdr.app/Contents
    mkdir -p $app/MacOS $app/Resources
    png2icns $app/Resources/herdr.icns ${./herdr-launcher/icon.png}

    cp ${launcher} $app/MacOS/herdr-launcher

    cat > $app/Info.plist <<'EOF'
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleName</key><string>Herdr</string>
      <key>CFBundleIdentifier</key><string>dev.nix-base.herdr-launcher</string>
      <key>CFBundleExecutable</key><string>herdr-launcher</string>
      <key>CFBundleIconFile</key><string>herdr</string>
      <key>CFBundlePackageType</key><string>APPL</string>
    </dict>
    </plist>
    EOF
  '';
in
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.packages = [ herdrApp ];
}
