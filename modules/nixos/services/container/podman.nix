{
  pkgs,
  lib,
  config,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.system.services.container.podman;
  inherit (saqulaLib) mkFeatureOptions mkPlatformAssert wrapConfig;
in {
  options.saqula.system.services.container.podman = mkFeatureOptions "Podman container runtime";

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "podman";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (wrapConfig cfg {
      # Podman / containers persistence（impermanence 有効時）
      environment.persistence."/persist".directories = [
        "/var/lib/containers"
      ];

      # Podman を有効化する
      virtualisation.podman = {
        enable = true;
        dockerCompat = true; # docker alias を作る
        defaultNetwork.settings.dns_enabled = true;
      };

      # container networking を有効化する
      virtualisation.containers.enable = true;

      environment.systemPackages = with pkgs; [
        podman-compose
        buildah
        skopeo
        (writeScriptBin "podman-info" ''
          #!/usr/bin/env bash
          echo "=== Podman Version ==="
          podman version
          echo ""
          echo "=== Running Containers ==="
          podman ps
          echo ""
          echo "=== Images ==="
          podman images
        '')
      ];
    })
  ];
}
