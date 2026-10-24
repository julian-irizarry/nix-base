{
  nixpkgs,
  home-manager,
  inputs,
  homeModule,
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
      extraSpecialArgs = { inherit inputs; };
      modules = [ homeModule ] ++ modules;
    };
in
nixpkgs.lib.genAttrs systems forSystem
