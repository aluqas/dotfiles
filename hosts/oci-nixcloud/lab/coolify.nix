# Coolify PaaS
#
# self-hosted な Vercel / Netlify 代替
# 手動の docker-compose 設定（install.sh の OS check を回避する）
#
{
  pkgs,
  config,
  ...
}: {
  virtualisation.docker.enable = true;
  networking.firewall.allowedTCPPorts = [
    8001
    6001
    6002
    80
    443
  ];

  # Docker Swarm が初期化されていることを保証する（Coolify が使う）
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

  # Coolify の追加 directory（workDir 以外）
  systemd.tmpfiles.rules = [
    "d /data/coolify/ssh 0700 9999 root -"
    "d /data/coolify/ssh/keys 0700 9999 root -"
    "d /data/coolify/ssh/mux 0700 9999 root -"
    "d /data/coolify/applications 0700 9999 root -"
    "d /data/coolify/databases 0700 9999 root -"
    "d /data/coolify/backups 0700 9999 root -"
    "d /data/coolify/services 0700 9999 root -"
    "d /data/coolify/proxy 0700 9999 root -"
    "d /data/coolify/proxy/dynamic 0700 9999 root -"
  ];

  # 抽象化 module 経由で Coolify service を作る
  services.compose-service.instances.coolify = {
    enable = true;
    workDir = "/data/coolify/source";
    user = "9999";
    group = "root";

    # pre-start: label conflict を避けるため既存 network を消す
    preStart = ''
      docker network rm coolify 2>/dev/null || true
    '';

    environmentFiles = [
      config.age.secrets.coolify-secrets.path
    ];

    environment = {
      APP_ID = "coolify-id";
      APP_NAME = "Coolify";
      APP_ENV = "production";
      APP_URL = "http://localhost:8001";
      APP_DEBUG = "false";
      APP_PORT = "8001";

      LOG_CHANNEL = "daily";
      LOG_LEVEL = "debug";

      DB_CONNECTION = "pgsql";
      DB_HOST = "coolify-db";
      DB_PORT = "5432";
      DB_DATABASE = "coolify";
      DB_USERNAME = "coolify";

      REDIS_HOST = "coolify-redis";
      REDIS_PORT = "6379";

      PUSHER_HOST = "coolify.fairy-sargas.ts.net"; # Use Tailscale host for external access
      PUSHER_PORT = "6001";
      PUSHER_APP_ID = "coolify-pusher-id";
      PUSHER_APP_KEY = "coolify-pusher-key";
      PUSHER_SCHEME = "https"; # HTTPS via Tailscale

      MIX_PUSHER_APP_KEY = "coolify-pusher-key";
      MIX_PUSHER_HOST = "coolify.fairy-sargas.ts.net";
      MIX_PUSHER_PORT = "6001";
      MIX_PUSHER_SCHEME = "https";

      QUEUE_CONNECTION = "redis";
      SESSION_DRIVER = "redis";
      SESSION_LIFETIME = "120";

      BROADCAST_DRIVER = "pusher";
      CACHE_DRIVER = "redis";

      HORIZON_BALANCE = "auto";
      HORIZON_MAX_PROCESSES = "10";
      HORIZON_BALANCE_MAX_SHIFT = "1";
      HORIZON_BALANCE_COOLDOWN = "3";

      PHP_MEMORY_LIMIT = "256M";
      SELF_HOSTED = "true";
      SSH_MUX_PERSIST_TIME = "3600";
    };

    composeFile = ''
      services:
        coolify:
          image: ghcr.io/coollabsio/coolify:latest
          container_name: coolify
          restart: always
          working_dir: /var/www/html
          extra_hosts:
            - host.docker.internal:host-gateway
          networks:
            - coolify
          depends_on:
            postgres:
              condition: service_healthy
            redis:
              condition: service_healthy
            soketi:
              condition: service_healthy
          volumes:
            - /data/coolify/source/.env:/var/www/html/.env:ro
            - /data/coolify/ssh:/var/www/html/storage/app/ssh
            - /data/coolify/applications:/var/www/html/storage/app/applications
            - /data/coolify/databases:/var/www/html/storage/app/databases
            - /data/coolify/services:/var/www/html/storage/app/services
            - /data/coolify/backups:/var/www/html/storage/app/backups
          env_file: .env
          ports:
            - "8001:8080"
          healthcheck:
            test: curl --fail http://127.0.0.1:8080/api/health || exit 1
            interval: 5s
            retries: 10
            timeout: 2s

        postgres:
          image: postgres:15-alpine
          container_name: coolify-db
          restart: always
          networks:
            - coolify
          volumes:
            - coolify-db:/var/lib/postgresql/data
          environment:
            POSTGRES_USER: coolify
            POSTGRES_PASSWORD: ''${DB_PASSWORD}
            POSTGRES_DB: coolify
          healthcheck:
            test: ["CMD-SHELL", "pg_isready -U coolify -d coolify"]
            interval: 5s
            retries: 10
            timeout: 2s

        redis:
          image: redis:7-alpine
          container_name: coolify-redis
          restart: always
          networks:
            - coolify
          command: redis-server --save 20 1 --loglevel warning --requirepass ''${REDIS_PASSWORD}
          volumes:
            - coolify-redis:/data
          healthcheck:
            test: redis-cli -a ''${REDIS_PASSWORD} ping
            interval: 5s
            retries: 10
            timeout: 2s

        soketi:
          image: ghcr.io/coollabsio/coolify-realtime:1.0.10
          container_name: coolify-realtime
          restart: always
          networks:
            - coolify
          ports:
            - "6001:6001"
            - "6002:6002"
          volumes:
            - /data/coolify/ssh:/var/www/html/storage/app/ssh
          environment:
            APP_NAME: Coolify
            SOKETI_DEBUG: "false"
            SOKETI_DEFAULT_APP_ID: ''${PUSHER_APP_ID}
            SOKETI_DEFAULT_APP_KEY: ''${PUSHER_APP_KEY}
            SOKETI_DEFAULT_APP_SECRET: ''${PUSHER_APP_SECRET}
          healthcheck:
            test: ["CMD-SHELL", "wget -qO- http://127.0.0.1:6001/ready && wget -qO- http://127.0.0.1:6002/ready || exit 1"]
            interval: 5s
            retries: 10
            timeout: 2s

      networks:
        coolify:
          name: coolify
          driver: bridge

      volumes:
        coolify-db:
          name: coolify-db
        coolify-redis:
          name: coolify-redis
    '';
  };

  # Coolify 用の Tailscale Sidecar
  services.tailscale-sidecar.instances.coolify = {
    enable = true;
    backend = "podman";
    authKeyFile = config.age.secrets.tailscale-auth-key.path;

    serve = {
      enable = true;
      port = 443;
      targetUrl = "http://localhost:8001";
    };

    waitFor = ["coolify.service"];
  };

  # Soketi を 6001 で Tailscale 公開する追加 service
  systemd.services.coolify-tailscale-soketi = {
    description = "Configure Tailscale Serve for Soketi (Coolify Realtime)";
    after = ["coolify-tailscale-config.service"];
    requires = ["podman-coolify-tailscale.service"];
    wantedBy = ["multi-user.target"];

    path = [pkgs.podman];

    script = ''
      echo "Configuring Tailscale Serve for Soketi (6001)..."
      podman exec coolify-tailscale tailscale serve --bg --https=6001 http://localhost:6001
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
