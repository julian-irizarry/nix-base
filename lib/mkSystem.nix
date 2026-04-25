{
  nixpkgs,
  home-manager,
  homeModulesDefault,
  inputs,
  noctalia,
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
    inputs = inputs // extraInputs;
  };
  modules = [
    ../nixos
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
        home-manager.extraSpecialArgs = { inherit noctalia; };
        home-manager.users.${config.sys.username} = {
          imports = homeModulesDefault ++ homeModules;
          my.platform.nixGL.enable = false;
        };
      }
    )
  ];
}
