{
  description = "Base NixOS + home-manager module library";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Vicinae ships its own home-manager module via homeManagerModules.default.
    # We pass pkgs.vicinae as the package (skips upstream's cachix), so we can
    # let inputs.nixpkgs.follows pin matching so the module version lines up.
    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nixGL wraps GPU apps so libGL/libEGL can find system drivers on non-NixOS.
    # Consumed via targets.genericLinux.nixGL; remove when migrating to NixOS.
    nixGL = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      treefmt-nix,
      vicinae,
      nixGL,
      ...
    }:
    let
      mkHome = import ./lib/mkHome.nix {
        inherit
          nixpkgs
          home-manager
          vicinae
          nixGL
          ;
      };
      mkSystem = import ./lib/mkSystem.nix {
        inherit nixpkgs home-manager;
        homeModulesDefault = [
          ./home
          vicinae.homeManagerModules.default
          { targets.genericLinux.nixGL.packages = nixGL.packages; }
        ];
      };

      supportedSystems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forSupportedSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      treefmtFor = system: treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix;

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

      nixosSmokeConfig = mkSystem {
        system = "x86_64-linux";
        modules = [
          {
            sys.hostname = "smoke-test";
            sys.username = "smoke-test";

            # Stub: smoke test has no real disk
            fileSystems."/" = {
              device = "/dev/null";
              fsType = "tmpfs";
            };
          }
        ];
      };

      nixosVmTest = import ./nixos/tests {
        inherit nixpkgs home-manager;
        homeModulesDefault = [
          ./home
          vicinae.homeManagerModules.default
          { targets.genericLinux.nixGL.packages = nixGL.packages; }
        ];
      };
    in
    {
      homeModules.default = ./home;
      nixosModules.default = ./nixos;

      lib = { inherit mkHome mkSystem; };

      formatter = forSupportedSystems (system: (treefmtFor system).config.build.wrapper);

      checks = forSupportedSystems (
        system:
        {
          home = smokeConfigs.${system}.activationPackage;
          formatting = (treefmtFor system).config.build.check self;
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          nixos = nixosSmokeConfig.config.system.build.toplevel;
          nixos-vm = nixosVmTest;
        }
      );
    };
}
