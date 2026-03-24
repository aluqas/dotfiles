# Podman 上の Portainer Server と Tailscale sidecar
#
# 構成:
# - Portainer Server: Podman container + 直接アクセス用の Tailscale sidecar
# - Portainer Agent: K3s 専用（ここではなく K3s module で管理する）
#
# 実装: NixOS の `virtualisation.oci-containers` を使い、
# 安定した宣言的 container 管理を行う（NixOS で扱いが難しい Quadlet は使わない）
#
{
  pkgs,
  lib,
  config,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.system.services.cluster.portainer;
  inherit (saqulaLib) mkFeatureOptionsExt mkPlatformAssert wrapConfig;
  inherit (lib) mkOption types mkEnableOption mkIf;
in {
  # hybrid merge を避けるため、mkFeatureOptionsExt で統一する
  options.saqula.system.services.cluster.portainer = mkFeatureOptionsExt "Portainer Management Platform" {
    server = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Deploy Portainer Server via Podman with Tailscale sidecar";
      };
      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/portainer";
        description = "Data directory for Portainer";
      };
    };

    tailscale = {
      hostname = mkOption {
        type = types.str;
        default = "portainer";
        description = "Tailscale hostname for Portainer";
      };
    };

    # K3s Agent の配置
    k3sAgent = {
      enable = mkEnableOption "Deploy Portainer Agent to K3s cluster";
    };

    # Docker Agent の配置（Coolify / Dokploy / Komodo との共存向け）
    dockerAgent = {
      enable = mkEnableOption "Deploy Portainer Agent to Docker Environment";
    };
  };

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "portainer";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (wrapConfig cfg {
      # Podman を有効化する
      virtualisation.podman.enable = true;

      # Portainer persistence（impermanence 有効時）
      environment.persistence."/persist".directories = mkIf cfg.server.enable [
        cfg.server.dataDir
      ];

      # data directory を作る
      systemd.tmpfiles.rules = mkIf cfg.server.enable [
        "d ${cfg.server.dataDir} 0700 root root -"
        "d /var/lib/tailscale-portainer 0700 root root -"
      ];

      # -----------------------------------------------------------------------
      # OCI Containers 設定（NixOS native）
      # -----------------------------------------------------------------------

      # container 通信用の bridge network を作る
      systemd.services.portainer-network-setup = mkIf cfg.server.enable {
        description = "Create Portainer container network";
        before = ["podman-portainer-tailscale.service"];
        wantedBy = ["multi-user.target"];
        path = [pkgs.podman];
        script = ''
          podman network exists portainer-net || podman network create portainer-net
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };

      virtualisation.oci-containers = mkIf cfg.server.enable {
        backend = "podman";
        containers = {
          # Tailscale sidecar container（host の TUN 衝突を避けるため userspace mode）
          portainer-tailscale = {
            image = "docker.io/tailscale/tailscale:latest";
            autoStart = true;

            extraOptions = [
              "--network=portainer-net"
              "--cap-add=NET_ADMIN"
            ];

            volumes = [
              "/var/lib/tailscale-portainer:/var/lib/tailscale"
              "${config.age.secrets.tailscale-auth-key.path}:/run/secrets/tailscale-auth-key:ro"
            ];

            environment = {
              TS_HOSTNAME = cfg.tailscale.hostname;
              TS_STATE_DIR = "/var/lib/tailscale";
              # host の TUN device 衝突を避けるため userspace networking を使う
              TS_USERSPACE = "true";
              TS_EXTRA_ARGS = "--accept-routes=false";
            };

            # auth key を読むため entrypoint を使う
            entrypoint = "/bin/sh";
            cmd = ["-c" "export TS_AUTHKEY=$(cat /run/secrets/tailscale-auth-key) && /usr/local/bin/containerboot"];
          };

          # Portainer Server container
          portainer-server = {
            image = "docker.io/portainer/portainer-ce:latest";
            autoStart = true;
            dependsOn = ["portainer-tailscale"];

            # Tailscale container と network namespace を共有する（sidecar pattern）
            extraOptions = [
              "--network=container:portainer-tailscale"
            ];

            volumes = [
              "${cfg.server.dataDir}:/data"
              "/run/podman/podman.sock:/var/run/docker.sock:ro"
            ];
          };
        };
      };

      # container が network 作成を待つようにする
      # oci-containers は `podman-<container-name>` という service 名を生成する
      systemd.services."podman-portainer-tailscale" = {
        requires = ["portainer-network-setup.service"];
        after = ["portainer-network-setup.service"];
      };
      systemd.services."podman-portainer-server" = {
        requires = ["portainer-network-setup.service" "podman-portainer-tailscale.service"];
        after = ["portainer-network-setup.service" "podman-portainer-tailscale.service"];
      };

      # container 起動後に tailscale serve を設定する
      systemd.services.portainer-tailscale-config = mkIf cfg.server.enable {
        description = "Configure Tailscale Serve for Portainer";
        after = ["podman-portainer-tailscale.service" "podman-portainer-server.service"];
        requires = ["podman-portainer-tailscale.service"];
        wantedBy = ["multi-user.target"];

        path = [pkgs.podman];

        script = ''
          # Tailscale container が ready になるのを待つ
          for i in $(seq 1 60); do
            if podman exec portainer-tailscale tailscale status >/dev/null 2>&1; then
              break
            fi
            echo "Waiting for Tailscale... ($i/60)"
            sleep 5
          done

          # serve を設定する（Portainer は 9000 で待ち受け、shared netns 内の localhost からアクセス可能）
          podman exec portainer-tailscale tailscale serve --bg --https=443 http://127.0.0.1:9000

          echo "Tailscale serve configured for Portainer"
          echo "Access at: https://${cfg.tailscale.hostname}.fairy-sargas.ts.net"
        '';

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          # 無限待ちを防ぐため timeout を入れる
          TimeoutStartSec = "5min";
        };
      };

      # -----------------------------------------------------------------------
      # K3s 上の Portainer Agent（変更なし）
      # -----------------------------------------------------------------------
      systemd.services.portainer-agent-k3s = mkIf (cfg.k3sAgent.enable && config.saqula.system.services.k3s.enable) {
        description = "Deploy Portainer Agent to K3s";
        after = ["k3s.service" "network-online.target"];
        requires = ["k3s.service"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];

        path = [pkgs.kubectl pkgs.k3s];

        environment = {
          KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
        };

        script = ''
          # K3s を待つ
          until kubectl get nodes >/dev/null 2>&1; do
            echo "Waiting for K3s..."
            sleep 5
          done

          # Portainer Agent を配置する（Podman から安定してアクセスできる NodePort mode）
          kubectl apply -f https://downloads.portainer.io/ce2-22/portainer-agent-k8s-nodeport.yaml

          # deployment を待つ
          kubectl rollout status deployment/portainer-agent -n portainer --timeout=120s || true

          echo "Portainer Agent (NodePort) deployed to K3s"
        '';

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };

      # -----------------------------------------------------------------------
      # Portainer Agent on Docker (Swarm Mode)
      # -----------------------------------------------------------------------
      systemd.services.portainer-agent-docker = mkIf cfg.dockerAgent.enable {
        description = "Portainer Agent for Docker Swarm";
        wantedBy = ["multi-user.target"];
        after = ["docker.service" "network-online.target"];
        requires = ["docker.service" "network-online.target"];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;

          # Cleanup previous instances and pull image
          ExecStartPre = [
            "-${pkgs.docker}/bin/docker service rm portainer_agent"
            "-${pkgs.docker}/bin/docker network rm portainer_agent_network"
            "${pkgs.docker}/bin/docker image pull portainer/agent:latest"
            # Create network (ignore failure if exists or swarm issue)
            "+${pkgs.bash}/bin/bash -c '${pkgs.docker}/bin/docker network create --driver overlay --attachable portainer_agent_network || true'"
          ];

          # Deploy as a Global Service
          ExecStart = ''
            ${pkgs.docker}/bin/docker service create \
            --name portainer_agent \
            --network portainer_agent_network \
            --publish mode=host,target=9001,published=9001 \
            --mode global \
            --mount type=bind,src=//var/run/docker.sock,dst=/var/run/docker.sock \
            --mount type=bind,src=//var/lib/docker/volumes,dst=/var/lib/docker/volumes \
            portainer/agent:latest
          '';

          # Stop by removing the service
          ExecStop = "-${pkgs.docker}/bin/docker service rm portainer_agent";
        };
      };
    })
  ];
}
