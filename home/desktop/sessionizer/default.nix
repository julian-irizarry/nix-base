{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.vicinae;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

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

  sessionizerJson = pkgs.writeText "sessionizer.json" (
    builtins.toJSON {
      roots = cfg.codeRoots;
      terminal = cfg.terminal;
    }
  );
in
lib.mkIf cfg.enableSessionizer (
  lib.mkMerge [
    { xdg.configFile."vicinae/sessionizer.json".source = sessionizerJson; }

    # Linux: install into vicinae extensions dir.
    (lib.mkIf isLinux {
      xdg.dataFile."vicinae/extensions/sessionizer".source = vicinaeBuild;
    })
  ]
)
