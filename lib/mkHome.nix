{
  nixpkgs,
  home-manager,
  vicinae,
  nixGL,
  noctalia,
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
    let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit noctalia; };
      modules = [
        ../home
        vicinae.homeManagerModules.default
        noctalia.homeModules.default
      ]
      ++ nixpkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux {
        targets.genericLinux.nixGL.packages = nixGL.packages;
      }
      ++ modules;
    };
in
nixpkgs.lib.genAttrs systems forSystem
