{
  nixpkgs,
  home-manager,
  vicinae,
  nixGL,
}:

{
  modules ? [ ],
  systems ? [
    "x86_64-linux"
    "aarch64-darwin"
  ],
}:

let
  forSystem =
    system:
    home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      modules = [
        ../home
        vicinae.homeManagerModules.default
        { targets.genericLinux.nixGL.packages = nixGL.packages; }
      ]
      ++ modules;
    };
in
nixpkgs.lib.genAttrs systems forSystem
