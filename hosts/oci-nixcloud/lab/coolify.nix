# Coolify PaaS
#
# Arion で Coolify stack を宣言的に管理する。
{
  pkgs,
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

  systemd.tmpfiles.rules = [
    "d /data/coolify/ssh 0700 9999 root -"
    "d /data/coolify/ssh/keys 0700 9999 root -"
    "d /data/coolify/ssh/mux 0700 9999 root -"
    "d /data/coolify/postgres 0700 9999 root -"
    "d /data/coolify/redis 0700 9999 root -"
    "d /data/coolify/applications 0700 9999 root -"
    "d /data/coolify/databases 0700 9999 root -"
    "d /data/coolify/backups 0700 9999 root -"
    "d /data/coolify/services 0700 9999 root -"
  ];

  systemd.services.coolify-ssh-bootstrap = {
    description = "Bootstrap SSH key for Coolify localhost server";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    path = with pkgs; [
      coreutils
      gnugrep
      openssh
    ];
    script = ''
      KEY_PATH="/data/coolify/ssh/keys/id.root@host.docker.internal"
      PUB_PATH="''${KEY_PATH}.pub"
      ROOT_SSH_DIR="/root/.ssh"
      AUTH_KEYS="''${ROOT_SSH_DIR}/authorized_keys"

      install -d -m 0700 /data/coolify/ssh /data/coolify/ssh/keys /data/coolify/ssh/mux
      install -d -m 0700 "''${ROOT_SSH_DIR}"

      if [ ! -f "''${KEY_PATH}" ]; then
        ssh-keygen -t ed25519 -N "" -C "root@coolify" -f "''${KEY_PATH}"
      fi

      touch "''${AUTH_KEYS}"
      chmod 0600 "''${AUTH_KEYS}"

      PUB_KEY=$(cat "''${PUB_PATH}")
      if ! grep -qxF "''${PUB_KEY}" "''${AUTH_KEYS}"; then
        echo "''${PUB_KEY}" >> "''${AUTH_KEYS}"
      fi

      chown 9999:root "''${KEY_PATH}" "''${PUB_PATH}"
      chmod 0600 "''${KEY_PATH}"
      chmod 0644 "''${PUB_PATH}"
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  virtualisation.arion.projects.coolify = {
    serviceName = "coolify";
    settings = {
      project.name = "coolify";

      services = {
        coolify.service = {
          image = "ghcr.io/coollabsio/coolify:latest";
          container_name = "coolify";
          restart = "always";
          working_dir = "/var/www/html";
          extra_hosts = [
            "host.docker.internal:host-gateway"
          ];
          networks = ["coolify"];
          depends_on = [
            "postgres"
            "redis"
            "soketi"
          ];
          ports = [
            "8001:8080"
          ];
          environment = {
            APP_ID = "coolify-id";
            APP_NAME = "Coolify";
            APP_ENV = "production";
            APP_KEY = "base64:8Tk/pcKueMdAhRv1CRc8owylsCd5EhjePgAFpwlPyJ0=";
            APP_URL = "https://coolify.fairy-sargas.ts.net";
            APP_DEBUG = "false";
            APP_PORT = "8001";

            LOG_CHANNEL = "daily";
            LOG_LEVEL = "debug";

            DB_CONNECTION = "pgsql";
            DB_HOST = "coolify-db";
            DB_PORT = "5432";
            DB_DATABASE = "coolify";
            DB_USERNAME = "coolify";
            DB_PASSWORD = "coolify_db_password_2024";

            REDIS_HOST = "coolify-redis";
            REDIS_PASSWORD = "coolify_redis_password_2024";
            REDIS_PORT = "6379";

            PUSHER_HOST = "coolify.fairy-sargas.ts.net";
            PUSHER_PORT = "6001";
            PUSHER_APP_ID = "coolify-pusher-id";
            PUSHER_APP_KEY = "coolify-pusher-key";
            PUSHER_APP_SECRET = "coolify-pusher-secret-2024";
            PUSHER_SCHEME = "http";
            PUSHER_BACKEND_HOST = "coolify-realtime";
            PUSHER_BACKEND_PORT = "6001";

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
          volumes = [
            "/data/coolify/ssh:/var/www/html/storage/app/ssh"
            "/data/coolify/applications:/var/www/html/storage/app/applications"
            "/data/coolify/databases:/var/www/html/storage/app/databases"
            "/data/coolify/services:/var/www/html/storage/app/services"
            "/data/coolify/backups:/var/www/html/storage/app/backups"
          ];
        };

        postgres.service = {
          image = "postgres:15-alpine";
          container_name = "coolify-db";
          restart = "always";
          networks = ["coolify"];
          environment = {
            POSTGRES_USER = "coolify";
            POSTGRES_PASSWORD = "coolify_db_password_2024";
            POSTGRES_DB = "coolify";
          };
          volumes = [
            "/data/coolify/postgres:/var/lib/postgresql/data"
          ];
        };

        redis.service = {
          image = "redis:7-alpine";
          container_name = "coolify-redis";
          restart = "always";
          networks = ["coolify"];
          command = [
            "redis-server"
            "--save"
            "20"
            "1"
            "--loglevel"
            "warning"
            "--requirepass"
            "coolify_redis_password_2024"
          ];
          volumes = [
            "/data/coolify/redis:/data"
          ];
        };

        soketi.service = {
          image = "ghcr.io/coollabsio/coolify-realtime:1.0.10";
          container_name = "coolify-realtime";
          restart = "always";
          networks = ["coolify"];
          ports = [
            "6001:6001"
            "6002:6002"
          ];
          environment = {
            APP_NAME = "Coolify";
            SOKETI_DEBUG = "false";
            SOKETI_DEFAULT_APP_ID = "coolify-pusher-id";
            SOKETI_DEFAULT_APP_KEY = "coolify-pusher-key";
            SOKETI_DEFAULT_APP_SECRET = "coolify-pusher-secret-2024";
          };
          volumes = [
            "/data/coolify/ssh:/var/www/html/storage/app/ssh"
          ];
        };
      };

      networks.coolify = {
        name = "coolify";
        driver = "bridge";
      };
    };
  };

  systemd.services.coolify = {
    after = ["coolify-ssh-bootstrap.service"];
    requires = ["coolify-ssh-bootstrap.service"];
  };
}
