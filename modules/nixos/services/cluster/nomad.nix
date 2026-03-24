{
  pkgs,
  lib,
  config,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.system.services.cluster.nomad;
  inherit (saqulaLib) mkFeatureOptionsExt mkPlatformAssert wrapConfig;
  inherit (lib) mkOption types;
in {
  options.saqula.system.services.cluster.nomad = mkFeatureOptionsExt "HashiCorp Nomad" {
    package = mkOption {
      type = types.package;
      default = pkgs.nomad;
      description = "使用する Nomad package";
    };
  };

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "nomad";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (wrapConfig cfg {
      # Nomad を有効化する
      services.nomad = {
        enable = true;
        inherit (cfg) package;
        enableDocker = true;

        settings = {
          datacenter = "dc1";
          data_dir = "/var/lib/nomad";

          server = {
            enabled = true;
            bootstrap_expect = 1;
          };

          client = {
            enabled = true;
            servers = ["127.0.0.1:4647"];
          };

          ui = {
            enabled = true;
          };
        };
      };

      # firewall port を開く
      networking.firewall.allowedTCPPorts = [
        4646 # HTTP API / UI
        4647 # RPC
        4648 # Serf WAN
      ];

      environment.systemPackages = with pkgs; [
        cfg.package
        (writeScriptBin "nomad-info" ''
          #!/usr/bin/env bash
          echo "=== Nomad Server Status ==="
          nomad server members
          echo ""
          echo "=== Nomad Node Status ==="
          nomad node status
          echo ""
          echo "=== Running Jobs ==="
          nomad job status
        '')
        (writeScriptBin "nomad-ui" ''
          #!/usr/bin/env bash
          echo "Opening Nomad UI at http://localhost:4646"
          xdg-open http://localhost:4646 2>/dev/null || echo "Access: http://localhost:4646"
        '')
      ];
    })
  ];
}
