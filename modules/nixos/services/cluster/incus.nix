{
  pkgs,
  lib,
  config,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.system.services.cluster.incus;
  inherit (saqulaLib) mkFeatureOptionsExt mkPlatformAssert wrapConfig;
  inherit (lib) mkOption types;
in {
  options.saqula.system.services.cluster.incus = mkFeatureOptionsExt "Incus System Containers & VMs" {
    package = mkOption {
      type = types.package;
      default = pkgs.incus;
      description = "使用する Incus package";
    };
  };

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "incus";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (wrapConfig cfg {
      # Incus persistence（impermanence 有効時）
      environment.persistence."/persist".directories = [
        "/var/lib/incus"
      ];

      # Incus を有効化する
      virtualisation.incus = {
        enable = true;
        inherit (cfg) package;
        preseed = {
          networks = [
            {
              name = "incusbr0";
              type = "bridge";
              config = {
                "ipv4.address" = "10.0.100.1/24";
                "ipv4.nat" = "true";
              };
            }
          ];
          profiles = [
            {
              name = "default";
              devices = {
                eth0 = {
                  name = "eth0";
                  network = "incusbr0";
                  type = "nic";
                };
                root = {
                  path = "/";
                  pool = "default";
                  size = "10GiB";
                  type = "disk";
                };
              };
            }
          ];
          storage_pools = [
            {
              name = "default";
              driver = "dir";
              config = {
                source = "/var/lib/incus/storage-pools/default";
              };
            }
          ];
        };
      };

      # Incus の UI / API 用 firewall を開く（有効化 / 設定済みなら）
      networking.firewall.allowedTCPPorts = [8443];

      environment.systemPackages = with pkgs; [
        (writeScriptBin "incus-info" ''
          #!/usr/bin/env bash
          echo "=== Incus Version ==="
          incus version
          echo ""
          echo "=== Running Instances ==="
          incus list
          echo ""
          echo "=== Images ==="
          incus image list
        '')
        (writeScriptBin "incus-launch-ubuntu" ''
          #!/usr/bin/env bash
          NAME="''${1:-ubuntu-test}"
          echo "Launching Ubuntu container: $NAME"
          incus launch images:ubuntu/24.04 "$NAME"
          incus list
        '')
      ];
    })
  ];
}
