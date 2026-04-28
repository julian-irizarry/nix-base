{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.vicinae;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  cleanSrc = lib.cleanSourceWith {
    src = ./.;
    filter =
      name: type:
      let
        base = baseNameOf name;
      in
      !(base == "node_modules" || base == "default.nix" || base == "result");
  };

  # Linux: build as a vicinae extension via `vici build`.
  vicinaeBuild = pkgs.buildNpmPackage {
    pname = "sessionizer-vicinae";
    version = "0.1.0";
    src = cleanSrc;

    # Regenerate with:
    #   nix-shell -p prefetch-npm-deps --run "prefetch-npm-deps <path>/package-lock.json"
    npmDepsHash = "sha256-Cg8wazOk7IpXCZQNUvqOq8n7vaBdt0f0csSXp9ubiGc=";

    preBuild = ''
      # Point the launcher abstraction at vicinae.
      echo 'export * from "./vicinae";' > src/launcher/index.ts
      export HOME="$TMPDIR/vici-home"
      mkdir -p "$HOME"
    '';

    installPhase = ''
      runHook preInstall
      local built="$HOME/.local/share/vicinae/extensions/sessionizer"
      if [ ! -d "$built" ]; then
        echo "expected vici build output at $built — not found" >&2
        exit 1
      fi
      mkdir -p $out
      cp -r "$built"/. $out/
      runHook postInstall
    '';

    meta = {
      description = "Sessionizer extension for vicinae";
      license = lib.licenses.mit;
    };
  };

  # Darwin: raycast refuses to auto-discover extensions dropped into
  # ~/.config/raycast/extensions/. The only supported way to register a
  # local extension is `ray develop`, which expects *source* (not a built
  # bundle) in a *writable* directory with node_modules installed.
  #
  # So instead of building, we stage source into a nix-store path with the
  # raycast manifest + lockfile + launcher wiring in place, then the home
  # activation copies that tree to a writable dev path where the user runs
  # `npm ci && npx @raycast/api develop` once to register the extension.
  raycastSrc = pkgs.runCommand "sessionizer-src-raycast" { } ''
    cp -r ${cleanSrc} $out
    chmod -R +w $out
    mv $out/package.raycast.json $out/package.json
    mv $out/package-lock.raycast.json $out/package-lock.json
    rm -f $out/package-lock.json.vicinae 2>/dev/null || true
    echo 'export * from "./raycast";' > $out/src/launcher/index.ts
    # build.mjs is vicinae-specific (esbuild scaffolding); raycast uses `ray build`.
    rm -f $out/build.mjs
  '';

  # Raycast (Darwin) spawns extensions under launchd's minimal PATH, so
  # bare `wezterm`/`kitten` command names don't resolve. Thread an absolute
  # /nix/store path through sessionizer.json so the extension can execFile
  # directly. Harmless on vicinae — it just ignores the field.
  terminalBin =
    if cfg.terminal == "kitty" then "${pkgs.kitty}/bin/kitten" else "${pkgs.wezterm}/bin/wezterm";

  sessionizerJson = pkgs.writeText "sessionizer.json" (
    builtins.toJSON {
      roots = cfg.codeRoots;
      terminal = cfg.terminal;
      inherit terminalBin;
    }
  );

  raycastDevPath = "Developer/raycast-extensions/sessionizer";
in
lib.mkIf cfg.enableSessionizer (
  lib.mkMerge [
    # Shared config file — same path on both platforms.
    { xdg.configFile."vicinae/sessionizer.json".source = sessionizerJson; }

    # Linux: install into vicinae extensions dir.
    (lib.mkIf isLinux {
      xdg.dataFile."vicinae/extensions/sessionizer".source = vicinaeBuild;
    })

    # Darwin: stage source into a writable dev path and refresh node_modules
    # on every activation. User runs `npx @raycast/api develop` once from
    # ~/${raycastDevPath} to register with Raycast; the registration persists
    # across activations even after the watcher exits.
    (lib.mkIf isDarwin {
      home.activation.stageSessionizerRaycast = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        dev="$HOME/${raycastDevPath}"
        $DRY_RUN_CMD mkdir -p "$dev"
        # rsync preserves the dir so `ray develop` state (metadata/, built
        # bundles, .raycastignore) survives re-activation. --chmod rewrites
        # read-only nix-store permissions so npm/ray can mutate files.
        $DRY_RUN_CMD ${pkgs.rsync}/bin/rsync -a --delete \
          --chmod=u+w,go-w \
          --exclude node_modules --exclude metadata --exclude .raycast \
          "${raycastSrc}/" "$dev/"
      '';
    })
  ]
)
