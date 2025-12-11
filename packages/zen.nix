{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellScriptBin "zen" ''
      #!/usr/bin/env bash

      # Get current state: is fullscreen already on?
      #!/usr/bin/env bash

      state=$(kitty @ ls | jq '.[0].tabs[0].windows[0].fullscreen')

      if [ "$state" = "true" ]; then
        kitty @ set-window --self fullscreen no
      else
        kitty @ set-window --self fullscreen yes
      fi
    '')
  ];
}
