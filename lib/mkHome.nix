{
  nixpkgs,
  home-manager,
  vicinae,
  nixGL,
  inputs,
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
      extraSpecialArgs = { inherit inputs; };
      modules = [
        ../home
        vicinae.homeManagerModules.default
        inputs.noctalia.homeModules.default
      ]
      ++ nixpkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux {
        targets.genericLinux.nixGL.packages = nixGL.packages;
      }
      ++ modules;
    };
in
nixpkgs.lib.genAttrs systems forSystem
