# Headlamp Kubernetes Dashboard
#
# Modern な Kubernetes web UI
# https://headlamp.dev
#
{pkgs, ...}: {
  # Headlamp は Docker を必要とする
  virtualisation.docker.enable = true;

  # firewall port を開く
  networking.firewall.allowedTCPPorts = [4466];

  # Headlamp 用の systemd service
  systemd.services.headlamp = {
    description = "Headlamp Kubernetes Dashboard";
    after = [
      "docker.service"
      "k3s.service"
      "network-online.target"
    ];
    requires = ["docker.service"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];

    path = [pkgs.docker];

    script = ''
      # 最新 image を pull する
      docker pull ghcr.io/headlamp-k8s/headlamp:latest

      # 既存 container があれば削除する
      docker rm -f headlamp 2>/dev/null || true

      # Headlamp を起動する
      docker run -d \
        --name headlamp \
        --restart unless-stopped \
        -p 4466:4466 \
        -v /etc/rancher/k3s/k3s.yaml:/root/.kube/config:ro \
        ghcr.io/headlamp-k8s/headlamp:latest

      # log を追う
      exec docker logs -f headlamp
    '';

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "10s";
    };
  };

  environment.systemPackages = with pkgs; [
    (writeScriptBin "headlamp-logs" ''
      #!/usr/bin/env bash
      sudo docker logs -f headlamp
    '')
  ];
}
