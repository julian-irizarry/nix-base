{
  nixpkgs,
  home-manager,
  vicinae,
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
        ../modules
        vicinae.homeManagerModules.default
      ]
      ++ modules;
    };
in
nixpkgs.lib.genAttrs systems forSystem
