{ nixpkgs, home-manager }:

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
      modules = [ ../modules ] ++ modules;
    };
in
nixpkgs.lib.genAttrs systems forSystem
