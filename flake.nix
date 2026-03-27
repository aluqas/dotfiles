{
  description = "Saqula's unified Darwin and NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    ragenix.url = "github:yaxitech/ragenix";
    ragenix.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.inputs.utils.follows = "flake-utils";
    deploy-rs.inputs.flake-compat.follows = "flake-parts/nixpkgs-lib";

    impermanence.url = "github:nix-community/impermanence";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    flake-root.url = "github:srid/flake-root";

    flake-utils.url = "github:numtide/flake-utils";

    # treefmt-nix.url = "github:numtide/treefmt-nix";
    # treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";

    nix-health.url = "github:juspay/nix-health";
    nix-health.inputs.nixpkgs.follows = "nixpkgs";

    crane = {
      url = "github:ipetkov/crane";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = inputs @ {
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      imports = [
        # inputs.treefmt-nix.flakeModule
        inputs.flake-root.flakeModule
      ];

      perSystem = {
        config,
        pkgs,
        system,
        ...
      }: {
        flake-root.projectRootFile = "flake.nix";
        # treefmt = import ./treefmt.nix;

        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = import ./lib/overlays.nix {inherit inputs;};
          config.allowUnfree = true;
        };

        packages = {
          deploy-rs = inputs.deploy-rs.packages.${system}.default;
        };

        devShells.default = config.devShells.devenv;
        devShells.devenv = inputs.devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [./devenv.nix];
        };
      };

      flake = let
        hostLib = import ./lib/hosts.nix {
          inherit (nixpkgs) lib;
          inherit inputs;
        };

        hostDefinitions = {
          darwin = {
            macbook = {
              system = "aarch64-darwin";
              hostPath = ./hosts/macbook;
              homeImports = [
                ./profiles/home/stylix
                ./profiles/home/develop.nix
                ./hosts/macbook/home.nix
              ];
            };
          };

          nixos = {
            nixos-bootstrap = {
              system = "aarch64-linux";
              hostPath = ./hosts/nixos-bootstrap;
              homeImports = [
                ./profiles/home/stylix
                ./profiles/home/develop.nix
              ];
            };

            oci-nixcloud = {
              system = "aarch64-linux";
              hostPath = ./hosts/oci-nixcloud;
              homeImports = [
                ./profiles/home/stylix
                ./profiles/home/develop.nix
                ./profiles/home/infra.nix
              ];
            };
          };
        };

        hostOutputs = hostLib.mkHosts hostDefinitions;
      in
        hostOutputs
        // {
          deploy.nodes =
            nixpkgs.lib.mapAttrs (name: cfg: let
              def = hostDefinitions.nixos.${name};
              hostVars = import (def.hostPath + "/vars.nix");
              deployHost = def.deployHostname or (hostVars.deployHost or cfg.config.networking.hostName);
            in {
              hostname = deployHost;
              profiles.system = {
                user = "root";
                path = inputs.deploy-rs.lib.${cfg.pkgs.system}.activate.nixos cfg;
              };
            })
            hostOutputs.nixosConfigurations;

          templates = {
            rust = {
              path = ./templates/rust;
              description = "Rust development environment";
            };
            python = {
              path = ./templates/python;
              description = "Python development environment";
            };
            go = {
              path = ./templates/go;
              description = "Go development environment";
            };
            node = {
              path = ./templates/node;
              description = "Node.js development environment";
            };
            nix = {
              path = ./templates/nix;
              description = "Nix development environment";
            };
            ocaml = {
              path = ./templates/ocaml;
              description = "OCaml development environment";
            };
          };
        };
    };
}
