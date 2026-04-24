{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.vicinae;

  # Build the TypeScript extension hermetically via nix. `vici build`
  # bundles src/ into a single .js per command plus copies the manifest
  # and assets. Output is dropped under $out/; we then symlink $out into
  # vicinae's user extensions dir.
  sessionizerExtension = pkgs.buildNpmPackage {
    pname = "vicinae-sessionizer";
    version = "0.1.0";

    src = lib.cleanSourceWith {
      src = ./.;
      filter =
        name: type:
        let
          base = baseNameOf name;
        in
        !(base == "node_modules" || base == "default.nix" || base == "result");
    };

    # Regenerate with:
    #   nix-shell -p prefetch-npm-deps --run "prefetch-npm-deps <path>/package-lock.json"
    npmDepsHash = "sha256-Cg8wazOk7IpXCZQNUvqOq8n7vaBdt0f0csSXp9ubiGc=";

    # `vici build` writes to ~/.local/share/vicinae/extensions/<name>/ by
    # default. Override HOME so it writes somewhere inside the build
    # sandbox, which we then capture in the install phase.
    preBuild = ''
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
      description = "Vicinae sessionizer extension";
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
lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && cfg.enableSessionizer) {
  xdg.configFile."vicinae/sessionizer.json".source = sessionizerJson;

  # Vicinae reads user-installed extensions from XDG_DATA_HOME; symlink
  # the built derivation there.
  xdg.dataFile."vicinae/extensions/sessionizer".source = sessionizerExtension;
}
