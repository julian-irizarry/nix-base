{
  nixpkgs,
  home-manager,
  inputs,
  nixosInputs,
  nixosModule,
  homeModule,
}:

{
  system,
  modules ? [ ],
  homeModules ? null,
  extraInputs ? { },
}:

nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inputs = nixosInputs // extraInputs;
  };
  modules = [
    nixosModule
    { nixpkgs.config.allowUnfree = true; }
  ]
  ++ modules
  ++ nixpkgs.lib.optionals (homeModules != null) [
    home-manager.nixosModules.home-manager
    (
      { config, ... }:
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs; };
        home-manager.users.${config.sys.username} = {
          imports = [ homeModule ] ++ homeModules;
          my.platform.nixGL.enable = false;
        };
      }
    )
  ];
}
