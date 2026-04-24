{
  nixpkgs,
  home-manager,
  homeModulesDefault,
}:

{
  system,
  modules ? [ ],
  homeModules ? null,
}:

nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ../nixos
  ]
  ++ modules
  ++ nixpkgs.lib.optionals (homeModules != null) [
    home-manager.nixosModules.home-manager
    (
      { config, ... }:
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${config.sys.username} = {
          imports = [ homeModulesDefault ] ++ homeModules;
          my.platform.nixGL.enable = false;
        };
      }
    )
  ];
}
