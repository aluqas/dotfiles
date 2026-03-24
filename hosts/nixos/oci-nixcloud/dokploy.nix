# Dokploy PaaS
#
# Docker Swarm ベースの application deployment platform
#
{
  pkgs,
  config,
  ...
}: {
  virtualisation.docker.enable = true;
  networking.firewall.allowedTCPPorts = [
    3001
    8880
    8843
  ];

  # generic な Tailscale Sidecar abstraction を使う
  services.tailscale-sidecar.instances.dokploy = {
    enable = true;
    backend = "podman";
    authKeyFile = config.age.secrets.tailscale-auth-key.path;

    serve = {
      enable = true;
      port = 443;
      targetUrl = "http://localhost:3001";
    };
  };

  # Docker Swarm が初期化されていることを保証する
  systemd.services.docker-swarm-init = {
    description = "Initialize Docker Swarm";
    after = ["docker.service"];
    requires = ["docker.service"];
    wantedBy = ["multi-user.target"];
    path = with pkgs; [
      docker
      tailscale
      gawk
      hostname
    ];
    script = ''
      if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
         ADVERTISE_ADDR=$(tailscale ip -4 2>/dev/null || hostname -I | awk '{print $1}')
         if [ -z "$ADVERTISE_ADDR" ]; then
            ADVERTISE_ADDR="127.0.0.1"
         fi
         echo "Initializing Swarm with advertise-addr: $ADVERTISE_ADDR"
         docker swarm init --advertise-addr "$ADVERTISE_ADDR" || true
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  # Dokploy を install する oneshot service
  systemd.services.dokploy-install = {
    description = "Install Dokploy PaaS";
    after = [
      "docker.service"
      "docker-swarm-init.service"
      "network-online.target"
    ];
    requires = [
      "docker.service"
      "docker-swarm-init.service"
    ];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];

    path = with pkgs; [
      docker
      curl
      bash
      coreutils
      gnugrep
      tailscale
      gawk
      hostname
    ];

    script = ''
      # advertise address を決める
      export ADVERTISE_ADDR=$(tailscale ip -4 2>/dev/null || hostname -I | awk '{print $1}')
      if [ -z "$ADVERTISE_ADDR" ]; then
          export ADVERTISE_ADDR="127.0.0.1"
      fi
      echo "Detected ADVERTISE_ADDR: $ADVERTISE_ADDR"



      echo "Installing Dokploy..."

      # Network
      docker network create --driver overlay --attachable dokploy-network 2>/dev/null || true

      # Directories
      mkdir -p /data/apps/dokploy
      chmod 777 /data/apps/dokploy

      # Postgres
      echo "Creating Postgres..."
      docker service create \
        --name dokploy-postgres \
        --constraint 'node.role==manager' \
        --network dokploy-network \
        --env POSTGRES_USER=dokploy \
        --env POSTGRES_DB=dokploy \
        --env POSTGRES_PASSWORD=amukds4wi9001583845717ad2 \
        --mount type=volume,source=dokploy-postgres,target=/var/lib/postgresql/data \
        postgres:16 || true

      # Redis
      echo "Creating Redis..."
      docker service create \
        --name dokploy-redis \
        --constraint 'node.role==manager' \
        --network dokploy-network \
        --mount type=volume,source=dokploy-redis,target=/data \
        redis:7 || true

      # Dokploy Core（UI は port 3001）
      echo "Creating Dokploy Core..."
      docker service create \
        --name dokploy \
        --replicas 1 \
        --network dokploy-network \
        --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
        --mount type=bind,source=/data/apps/dokploy,target=/etc/dokploy \
        --mount type=volume,source=dokploy,target=/root/.docker \
        --publish published=3001,target=3000,mode=host \
        --update-parallelism 1 \
        --update-order stop-first \
        --constraint 'node.role == manager' \
        -e ADVERTISE_ADDR=$ADVERTISE_ADDR \
        dokploy/dokploy:latest || true

      # Traefik（HTTP は 8880、HTTPS は 8843）
      echo "Starting Traefik..."
      docker rm -f dokploy-traefik 2>/dev/null || true
      docker run -d \
        --name dokploy-traefik \
        --restart always \
        -v /data/apps/dokploy/traefik/traefik.yml:/etc/traefik/traefik.yml \
        -v /data/apps/dokploy/traefik/dynamic:/etc/dokploy/traefik/dynamic \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        -p 8880:80/tcp \
        -p 8843:443/tcp \
        -p 8843:443/udp \
        traefik:v3.6.1 || true

      docker network connect dokploy-network dokploy-traefik || true

      echo "Dokploy installation complete!"
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  environment.systemPackages = with pkgs; [
    (writeScriptBin "dokploy-logs" ''
      #!/usr/bin/env bash
      sudo docker logs -f dokploy
    '')
    (writeScriptBin "dokploy-reinstall" ''
      #!/usr/bin/env bash
      echo "Removing existing Dokploy installation..."
      sudo docker stop dokploy dokploy-postgres dokploy-redis dokploy-traefik 2>/dev/null || true
      sudo docker rm dokploy dokploy-postgres dokploy-redis dokploy-traefik 2>/dev/null || true
      sudo docker volume rm dokploy-data dokploy-postgres-data dokploy-redis-data 2>/dev/null || true
      echo "Reinstalling Dokploy..."
      curl -sSL https://dokploy.com/install.sh | sudo bash
    '')
  ];
}
