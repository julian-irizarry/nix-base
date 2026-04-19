{
  config,
  lib,
  ...
}:

let
  cfg = config.my.nix;

  experimentalFeatures = [
    "nix-command"
    "flakes"
  ]
  ++ cfg.extraExperimentalFeatures;

  renderValue =
    v:
    if builtins.isBool v then
      (if v then "true" else "false")
    else if builtins.isList v then
      lib.concatStringsSep " " v
    else
      toString v;

  baseSettings = {
    experimental-features = experimentalFeatures;
  }
  // lib.optionalAttrs (cfg.extraSubstituters != [ ]) {
    extra-substituters = cfg.extraSubstituters;
  }
  // lib.optionalAttrs (cfg.extraTrustedPublicKeys != [ ]) {
    extra-trusted-public-keys = cfg.extraTrustedPublicKeys;
  };

  allSettings = baseSettings // cfg.extraSettings;

  renderedConf = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (k: v: "${k} = ${renderValue v}") allSettings
  );
in
{
  home.sessionVariables = lib.mkIf (cfg.extraNixPath != [ ]) {
    NIX_PATH = lib.concatStringsSep ":" cfg.extraNixPath;
  };

  xdg.configFile."nix/nix.conf".text = renderedConf + "\n";
}
