{
  lib,
  inputs,
}: let
  globalVars = import ./vars.nix;
  paths = import ./paths.nix {root = inputs.self;};
  overlays = import ./overlays.nix {inherit inputs;};

  mkSaqulaLib = {
    isDarwin,
    username,
  }: {
    secrets = import ./secrets.nix {
      root = inputs.self;
      inherit isDarwin username;
    };

    mkFeatureOptions = description: {
      enable = lib.mkEnableOption description;
    };

    mkFeatureOptionsExt = description: extraOptions:
      {
        enable = lib.mkEnableOption description;
      }
      // extraOptions;

    wrapConfig = cfg: content: lib.mkIf cfg.enable content;

    mkPlatformAssert = {
      name,
      platforms,
      pkgs,
    }: let
      currentPlatform =
        if pkgs.stdenv.isDarwin
        then "darwin"
        else "nixos";
    in {
      assertions = [
        {
          assertion = builtins.elem currentPlatform platforms;
          message = "Feature '${name}' requires one of: ${toString platforms}, but current platform is: ${currentPlatform}";
        }
      ];
    };
  };

  sharedModules = [
    ../modules/shared/options.nix
    ../modules/shared/types.nix
  ];

  darwinModules =
    sharedModules
    ++ [
      ../modules/darwin/base.nix
      ../modules/darwin/apps.nix
    ];

  nixosModules =
    sharedModules
    ++ [
      ../modules/nixos/boot.nix
      ../modules/nixos/disks.nix
      ../modules/nixos/guardrails.nix
      ../modules/nixos/impermanence.nix
      ../modules/nixos/locale.nix
      ../modules/nixos/minimal.nix
      ../modules/nixos/network.nix
      ../modules/nixos/optimization.nix
      ../modules/nixos/programs.nix
      ../modules/nixos/security.nix
      ../modules/nixos/users.nix
      ../modules/nixos/services
    ];

  baseNixpkgsModule = {
    nixpkgs = {
      inherit overlays;
      config.allowUnfree = true;
    };
  };

  mkDarwinHost = _name: def: let
    hostVars = import (def.hostPath + "/vars.nix");
    user = def.user or hostVars.username or globalVars.defaultUser;
    specialArgs = {
      inherit inputs hostVars globalVars paths;
      saqulaLib = mkSaqulaLib {
        isDarwin = true;
        username = user;
      };
    };
  in
    inputs.nix-darwin.lib.darwinSystem {
      inherit (def) system;
      inherit specialArgs;
      modules =
        darwinModules
        ++ [
          baseNixpkgsModule
          inputs.home-manager.darwinModules.home-manager
          inputs.stylix.darwinModules.stylix
          inputs.ragenix.darwinModules.default
          inputs.nix-index-database.darwinModules.nix-index
          (def.hostPath + "/default.nix")
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = specialArgs;
              sharedModules = [ inputs.stylix.homeModules.stylix ];
              users.${user} = {
                imports = def.homeImports;
                home = {
                  username = lib.mkDefault user;
                  homeDirectory = lib.mkForce "/Users/${user}";
                };
              };
            };
          }
        ];
    };

  mkNixosHost = _name: def: let
    hostVars = import (def.hostPath + "/vars.nix");
    user = def.user or hostVars.username or globalVars.defaultUser;
    specialArgs = {
      inherit inputs hostVars globalVars paths;
      saqulaLib = mkSaqulaLib {
        isDarwin = false;
        username = user;
      };
    };
  in
    inputs.nixpkgs.lib.nixosSystem {
      inherit (def) system;
      inherit specialArgs;
      modules =
        nixosModules
        ++ [
          baseNixpkgsModule
          inputs.home-manager.nixosModules.home-manager
          inputs.stylix.nixosModules.stylix
          inputs.ragenix.nixosModules.default
          inputs.disko.nixosModules.disko
          inputs.nix-index-database.nixosModules.nix-index
          inputs.impermanence.nixosModules.impermanence
          (def.hostPath + "/default.nix")
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = specialArgs;
              sharedModules = [ inputs.stylix.homeModules.stylix ];
              users.${user} = {
                imports = def.homeImports;
                home = {
                  username = lib.mkDefault user;
                  homeDirectory = lib.mkDefault "/home/${user}";
                };
              };
            };
          }
        ];
    };
in {
  mkHosts = definitions: {
    darwinConfigurations = lib.mapAttrs mkDarwinHost definitions.darwin;
    nixosConfigurations = lib.mapAttrs mkNixosHost definitions.nixos;
  };
}
