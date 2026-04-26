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
    home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      extraSpecialArgs = { inherit noctalia; };
      modules = [
        ../home
        vicinae.homeManagerModules.default
        noctalia.homeModules.default
        { targets.genericLinux.nixGL.packages = nixGL.packages; }
      ]
      ++ modules;
    };
in
nixpkgs.lib.genAttrs systems forSystem
