{
  lib,
  inputs,
  globalVars,
}: let
  overlays = import ./overlays.nix {inherit inputs;};

  mkSaqulaLib = {
    isDarwin,
    username,
  }: {
    secrets = import ./secrets.nix {
      root = inputs.self;
      inherit isDarwin username;
    };

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
    ../modules/shared/ssh-client.nix
    ../modules/shared/types.nix
  ];

  darwinModules =
    sharedModules
    ++ [
      ../modules/darwin/base.nix
      ../modules/darwin/apps.nix
      ../modules/darwin/lima.nix
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
    ];

  baseNixpkgsModule = {
    nixpkgs = {
      inherit overlays;
      config.allowUnfree = true;
    };
  };

  mkHost = isDarwin: _name: def: let
    hostVars = import (def.hostPath + "/vars.nix");
    user = def.user or hostVars.username or globalVars.defaultUser;
    repoRoot =
      if isDarwin
      then "/Users/${user}/${globalVars.checkoutDirName}"
      else "/home/${user}/${globalVars.checkoutDirName}";
    specialArgs = {
      inherit inputs hostVars globalVars;
      saqulaLib = mkSaqulaLib {
        inherit isDarwin;
        username = user;
      };
    };
    extraModules =
      if isDarwin
      then [
        inputs.home-manager.darwinModules.home-manager
        inputs.stylix.darwinModules.stylix
        inputs.ragenix.darwinModules.default
        inputs.nix-index-database.darwinModules.nix-index
      ]
      else [
        inputs.home-manager.nixosModules.home-manager
        inputs.stylix.nixosModules.stylix
        inputs.ragenix.nixosModules.default
        inputs.disko.nixosModules.disko
        inputs.nix-index-database.nixosModules.nix-index
        inputs.impermanence.nixosModules.impermanence
      ];
    build =
      if isDarwin
      then inputs.nix-darwin.lib.darwinSystem
      else inputs.nixpkgs.lib.nixosSystem;
    homeDirectory =
      if isDarwin
      then lib.mkForce "/Users/${user}"
      else lib.mkDefault "/home/${user}";
  in
    build {
      inherit (def) system;
      inherit specialArgs;
      modules =
        (
          if isDarwin
          then darwinModules
          else nixosModules
        )
        ++ extraModules
        ++ [
          baseNixpkgsModule
          (def.hostPath + "/default.nix")
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = specialArgs // {inherit repoRoot;};
              sharedModules = [
                inputs.stylix.homeModules.stylix
                inputs.nixvim.homeManagerModules.nixvim
              ];
              users.${user} = {
                imports = def.homeImports;
                home = {
                  username = lib.mkDefault user;
                  homeDirectory = homeDirectory;
                  stateVersion = globalVars.stateVersions.home;
                };
                programs.home-manager.enable = true;
              };
            };
          }
        ];
    };
in {
  mkHosts = definitions: {
    darwinConfigurations = lib.mapAttrs (mkHost true) definitions.darwin;
    nixosConfigurations = lib.mapAttrs (mkHost false) definitions.nixos;
  };
}
