{
  config,
  pkgs,
  lib,
  ...
}:

let
  fontPkg = pkgs.nerd-fonts.${config.my.font.nerdFamily} or null;
in
{
  assertions = [
    {
      assertion = fontPkg != null;
      message = ''
        my.font.nerdFamily = "${config.my.font.nerdFamily}" does not map
        to a package under pkgs.nerd-fonts. Check the attribute name at
        https://search.nixos.org/packages?query=nerd-fonts.
      '';
    }
  ];

  home.packages = lib.optional (fontPkg != null) fontPkg;

  fonts.fontconfig.enable = true;
}
