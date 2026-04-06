# Tailscale Service 設定
#
# このファイルで Service 設定 JSON を一元管理し、set-config --all で反映する。
{
  lib,
  pkgs,
  ...
}: {
  systemd.services.tailscale-service = let
    desiredConfig = {
      version = "0.0.1";
      services = {
        "svc:coolify" = {
          endpoints = {
            "tcp:443" = "http://127.0.0.1:8001";
          };
        };

        "svc:dokploy" = {
          endpoints = {
            "tcp:443" = "http://127.0.0.1:3001";
          };
        };

        "svc:komodo" = {
          endpoints = {
            "tcp:443" = "http://127.0.0.1:9120";
          };
        };

        "svc:n8n" = {
          endpoints = {
            "tcp:443" = "http://127.0.0.1:5678";
          };
        };

        "svc:openclaw" = {
          endpoints = {
            "tcp:443" = "http://127.0.0.1:18789";
          };
        };
      };
    };

    serviceNames = lib.attrNames desiredConfig.services;
    desiredConfigJson = builtins.toJSON desiredConfig;
    tailscaleBin = lib.getExe' pkgs.tailscale "tailscale";
    configFile = pkgs.writeText "tailscale-services.json" desiredConfigJson;
    advertiseCommands = map (serviceName: "-${tailscaleBin} serve advertise --service=${serviceName}") serviceNames;
  in {
    description = "Configure Tailscale Services from static JSON";
    after = [
      "tailscaled.service"
      "coolify.service"
      "dokploy.service"
      "komodo.service"
    ];
    requires = ["tailscaled.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "5min";
      Restart = "no";
      ExecStart =
        [
          "-${tailscaleBin} serve set-config --all ${configFile}"
        ]
        ++ advertiseCommands;
    };
  };
}
