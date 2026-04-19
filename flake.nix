{
  description = "Base home-manager module library (cross-platform)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      mkHome = import ./lib/mkHome.nix { inherit nixpkgs home-manager; };

      supportedSystems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forSupportedSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      smokeConfigs = mkHome {
        systems = supportedSystems;
        modules = [
          {
            home.username = "smoke-test";
            my.git.userName = "smoke";
            my.git.userEmail = "smoke@example.com";
          }
        ];
      };
    in
    {
      homeModules.default = ./modules;

      lib = { inherit mkHome; };

      formatter = forSupportedSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

      checks = forSupportedSystems (system: {
        default = smokeConfigs.${system}.activationPackage;
      });
    };
}
