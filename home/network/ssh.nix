{ config, lib, ... }:

let
  renderValue =
    v:
    if builtins.isBool v then
      (if v then "yes" else "no")
    else if builtins.isList v then
      lib.concatStringsSep " " (map toString v)
    else
      toString v;

  # Translate our matchBlock attr keys (matching HM's programs.ssh schema)
  # into the capitalized ssh_config(5) directive name.
  directiveName =
    key:
    {
      hostname = "HostName";
      user = "User";
      port = "Port";
      forwardAgent = "ForwardAgent";
      identityFile = "IdentityFile";
      proxyCommand = "ProxyCommand";
      proxyJump = "ProxyJump";
      certificateFile = "CertificateFile";
    }
    .${key} or null;

  renderDirective = key: value: "  ${directiveName key} ${renderValue value}";

  renderExtraOption = key: value: "  ${key} ${renderValue value}";

  renderHost =
    name: spec:
    let
      structured = lib.filterAttrs (k: _: directiveName k != null) spec;
      extras = spec.extraOptions or { };
    in
    lib.concatStringsSep "\n" (
      [ "Host ${name}" ]
      ++ lib.mapAttrsToList renderDirective structured
      ++ lib.mapAttrsToList renderExtraOption extras
    );

  renderedHosts = lib.concatStringsSep "\n\n" (
    lib.mapAttrsToList renderHost config.my.ssh.extraHosts
  );
in
{
  # Home-manager does not own ~/.ssh/config because latticectl writes there
  # directly. Instead we render my.ssh.extraHosts into a snippet under
  # ~/.ssh/config.d/hm-hosts; users include it once via:
  #     Include config.d/hm-hosts
  # at the top of ~/.ssh/config.
  home.file.".ssh/config.d/hm-hosts" = lib.mkIf (config.my.ssh.extraHosts != { }) {
    text = renderedHosts + "\n";
  };
}
