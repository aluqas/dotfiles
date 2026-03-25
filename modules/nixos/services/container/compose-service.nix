# Docker Compose Service モジュール
#
# systemd に紐づく Docker Compose service を宣言的に管理する。
# 役割:
# 1. docker-compose.yml の生成
# 2. Nix 設定からの .env 生成
# 3. up / down 管理用の systemd service
# 4. helper script（logs, restart）
#
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.compose-service;

  # 各 instance 用の submodule
  instanceOptions = {name, ...}: {
    options = {
      enable = mkEnableOption "Compose Service Instance";

      workDir = mkOption {
        type = types.str;
        default = "/var/lib/${name}";
      description = "service の working directory";
      };

      composeFile = mkOption {
        type = types.nullOr types.lines;
        default = null;
      description = "docker-compose.yml の内容（文字列）";
      };

      environment = mkOption {
        type = types.attrsOf types.str;
        default = {};
      description = ".env ファイルへ書き出す environment variable";
      };

      extraDirs = mkOption {
        type = types.listOf types.str;
        default = [];
      description = "workDir 配下に追加で作る directory の一覧（例: ['db' 'config']）";
      };

      user = mkOption {
        type = types.str;
        default = "root";
      description = "directory の所有 user";
      };

      group = mkOption {
        type = types.str;
        default = "root";
      description = "directory の所有 group";
      };

      preStart = mkOption {
        type = types.lines;
        default = "";
      description = "docker-compose up の前に実行する追加 shell command";
      };
    };
  };
in {
  options.services.compose-service = {
    instances = mkOption {
      type = types.attrsOf (types.submodule instanceOptions);
      default = {};
      description = "Docker Compose service instance の一覧";
    };
  };

  config = mkIf (cfg.instances != {}) {
    virtualisation.docker.enable = true;

    # directory 用の tmpfiles ルールを作る
    systemd.tmpfiles.rules = flatten (
      mapAttrsToList (
        _name: instance:
          ["d ${instance.workDir} 0700 ${instance.user} ${instance.group} -"]
          ++ (map (
              dir: "d ${instance.workDir}/${dir} 0700 ${instance.user} ${instance.group} -"
            )
            instance.extraDirs)
      )
      cfg.instances
    );

    # systemd service を生成する
    systemd.services =
      mapAttrs' (name: instance: {
        inherit name;
        value = mkIf instance.enable {
          description = "Docker Compose Service: ${name}";
          after = [
            "docker.service"
            "network-online.target"
          ];
          requires = ["docker.service"];
          wants = ["network-online.target"];
          wantedBy = ["multi-user.target"];

          path = with pkgs; [
            docker
            docker-compose
            coreutils
            openssl
          ];

          script = ''
            # workdir を用意する
            mkdir -p ${instance.workDir}
            cd ${instance.workDir}

            # .env を更新する（宣言的）
            cat > .env <<EOF
            ${concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${v}") instance.environment)}
            EOF
            chmod 600 .env

            # docker-compose.yml を更新する（宣言的）
            cat > docker-compose.yml <<'EOF'
            ${instance.composeFile}
            EOF

            # pre-start command
            ${instance.preStart}

            # service を開始する
            echo "Starting ${name}..."
            docker compose up -d --remove-orphans
          '';

          preStop = ''
            cd ${instance.workDir}
            docker compose down
          '';

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            TimeoutStartSec = "10min";
            Restart = "on-failure";
            RestartSec = "30s";
            StartLimitBurst = 3;
            StartLimitIntervalSec = "10min";
          };
        };
      })
      cfg.instances;

    # helper script を生成する
    environment.systemPackages = flatten (
      mapAttrsToList (name: instance: [
        (pkgs.writeScriptBin "${name}-logs" ''
          #!/usr/bin/env bash
          cd ${instance.workDir} && sudo docker compose logs -f "$@"
        '')
        (pkgs.writeScriptBin "${name}-restart" ''
          #!/usr/bin/env bash
          sudo systemctl restart ${name}
        '')
        (pkgs.writeScriptBin "${name}-shell" ''
          #!/usr/bin/env bash
          cd ${instance.workDir} && sudo docker compose exec "$@"
        '')
      ])
      cfg.instances
    );
  };
}
