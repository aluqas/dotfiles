# Tailscale Sidecar モジュール
#
# OCI container 用の Tailscale sidecar を宣言的に管理する。
# 自動で作るもの:
# 1. sidecar container（tailscale/tailscale）
# 2. `tailscale serve` を実行する設定 service
#
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.tailscale-sidecar;

  # 各 instance 用の submodule
  instanceOptions = {name, ...}: {
    options = {
      enable = mkEnableOption "Tailscale Sidecar Instance";

      backend = mkOption {
        type = types.enum [
          "docker"
          "podman"
        ];
        default = "podman";
      description = "使う container backend";
      };

      authKeyFile = mkOption {
        type = types.path;
      description = "Tailscale auth key を含む file の path";
      };

      hostname = mkOption {
        type = types.str;
        default = name;
      description = "Tailscale hostname（既定は instance 名）";
      };

      tags = mkOption {
        type = types.listOf types.str;
        default = ["tag:server"];
      description = "適用する Tailscale tag（例: tag:server）。auth key 側で許可されている必要がある。";
      };

      serve = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "tailscale serve の設定を有効化する";
        };

        port = mkOption {
          type = types.int;
          default = 443;
          description = "Tailscale 経由で公開する public port（通常は 443）";
        };

        targetUrl = mkOption {
          type = types.str;
          description = "proxy 先の target URL（例: http://localhost:8080）";
        };
      };

      waitFor = mkOption {
        type = types.listOf types.str;
        default = [];
          description = "serve を設定する前に待つ systemd service の一覧（例: ['coolify.service']）";
      };

      extraOptions = mkOption {
        type = types.listOf types.str;
        default = [];
          description = "oci-containers の追加 option";
      };
    };
  };
in {
  options.services.tailscale-sidecar = {
    instances = mkOption {
      type = types.attrsOf (types.submodule instanceOptions);
      default = {};
      description = "Tailscale sidecar instance 一覧";
    };
  };

  config = mkIf (cfg.instances != {}) {
    # backend service が有効であることを保証する
    virtualisation.podman.enable =
      mkIf (any (i: i.backend == "podman") (
        attrValues cfg.instances
      ))
      true;
    virtualisation.docker.enable =
      mkIf (any (i: i.backend == "docker") (
        attrValues cfg.instances
      ))
      true;

    # 各 instance の設定を生成する
    virtualisation.oci-containers.containers =
      mapAttrs' (name: instance: {
        name = "${name}-tailscale";
        value = {
          image = "docker.io/tailscale/tailscale:latest";
          autoStart = true;

          cmd = [
            "-c"
            "export TS_AUTHKEY=$(cat /run/secrets/tailscale-auth-key) && /usr/local/bin/containerboot"
          ];
          entrypoint = "/bin/sh";

          extraOptions =
            [
              "--cap-add=NET_ADMIN"
              "--network=host"
            ]
            ++ instance.extraOptions;

          volumes = [
            "/var/lib/tailscale-${name}:/var/lib/tailscale"
            "${instance.authKeyFile}:/run/secrets/tailscale-auth-key:ro"
          ];

          environment = {
            TS_HOSTNAME = instance.hostname;
            TS_STATE_DIR = "/var/lib/tailscale";
            TS_USERSPACE = "true";
            TS_EXTRA_ARGS = "--accept-routes=false";
            TS_TAGS = concatStringsSep "," instance.tags;
          };
        };
      })
      cfg.instances;

    # state directory を作る
    systemd.tmpfiles.rules =
      mapAttrsToList (
        name: _instance: "d /var/lib/tailscale-${name} 0700 root root -"
      )
      cfg.instances;

    # 設定 service を作る
    systemd.services =
      mapAttrs' (name: instance: {
        name = "${name}-tailscale-config";
        value = mkIf instance.serve.enable {
          description = "Configure Tailscale Serve for ${name}";
          after = ["${instance.backend}-${name}-tailscale.service"] ++ instance.waitFor;
          requires = ["${instance.backend}-${name}-tailscale.service"];
          wantedBy = ["multi-user.target"];

          path = [pkgs.${instance.backend}];

          script = ''
            # Tailscale container を待つ
            echo "Waiting for Tailscale sidecar..."
            for i in $(seq 1 60); do
              if ${instance.backend} exec ${name}-tailscale tailscale status >/dev/null 2>&1; then
                break
              fi
              sleep 2
            done

            # Serve を設定する
            echo "Configuring Tailscale Serve..."
            ${instance.backend} exec ${name}-tailscale tailscale serve --bg --https=${toString instance.serve.port} ${instance.serve.targetUrl}

            echo "Tailscale serve configured for ${name} -> ${instance.serve.targetUrl}"
          '';

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            TimeoutStartSec = "5min";
          };
        };
      })
      cfg.instances;
  };
}
