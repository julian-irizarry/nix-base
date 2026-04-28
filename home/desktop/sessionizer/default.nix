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

  # Darwin: build as a raycast extension via esbuild.
  raycastBuild = pkgs.buildNpmPackage {
    pname = "sessionizer-raycast";
    version = "0.1.0";
    src = cleanSrc;

    # TODO: regenerate once package.raycast.json lockfile is created.
    # For now this will need a package-lock.json that covers raycast deps.
    npmDepsHash = lib.fakeHash;

    preBuild = ''
      # Swap in the raycast manifest and launcher.
      cp package.raycast.json package.json
      echo 'export * from "./raycast";' > src/launcher/index.ts
    '';

    buildPhase = ''
      runHook preBuild
      node build.mjs
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r dist/. $out/
      cp -r assets $out/
      cp package.json $out/
      runHook postInstall
    '';

    meta = {
      description = "Sessionizer extension for raycast";
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
    # Shared config file — same path on both platforms.
    { xdg.configFile."vicinae/sessionizer.json".source = sessionizerJson; }

    # Linux: install into vicinae extensions dir.
    (lib.mkIf isLinux {
      xdg.dataFile."vicinae/extensions/sessionizer".source = vicinaeBuild;
    })

    # Darwin: install into raycast extensions dir.
    (lib.mkIf isDarwin {
      home.file.".config/raycast/extensions/sessionizer".source = raycastBuild;
    })
  ]
)
