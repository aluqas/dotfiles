# Komodo Container Management
#
# Docker container と stack の管理 platform
# https://komo.do
#
# 完全機能には MongoDB 付きの Docker Compose を使う
#
{config, ...}: {
  networking.firewall.allowedTCPPorts = [
    9120
    8120
  ];

  # generic な Compose Service abstraction を使う
  services.compose-service.instances.komodo = {
    enable = true;
    workDir = "/data/apps/komodo";
    extraDirs = ["backups"];

    environmentFiles = [
      config.age.secrets.komodo-secrets.path
    ];

    environment = {
      COMPOSE_KOMODO_IMAGE_TAG = "latest";
      COMPOSE_KOMODO_BACKUPS_PATH = "/data/apps/komodo/backups";

      # DB credentials
      KOMODO_DB_USERNAME = "admin";

      # Timezone
      TZ = "Asia/Tokyo";

      # ローカル login を有効化する
      KOMODO_LOCAL_AUTH = "true";
      KOMODO_DISABLE_USER_REGISTRATION = "false";
    };

    composeFile = ''
      version: "3.8"
      services:
        mongo:
          image: mongo
          command: --quiet --wiredTigerCacheSizeGB 0.25
          restart: unless-stopped
          volumes:
            - mongo-data:/data/db
            - mongo-config:/data/configdb
          environment:
            MONGO_INITDB_ROOT_USERNAME: $KOMODO_DB_USERNAME
            MONGO_INITDB_ROOT_PASSWORD: $KOMODO_DB_PASSWORD

        core:
          image: ghcr.io/moghtech/komodo-core:latest
          restart: unless-stopped
          depends_on:
            - mongo
          ports:
            - "9120:9120"
          env_file: .env
          environment:
            KOMODO_DATABASE_ADDRESS: mongo:27017
            KOMODO_DATABASE_USERNAME: $KOMODO_DB_USERNAME
            KOMODO_DATABASE_PASSWORD: $KOMODO_DB_PASSWORD
          volumes:
            - /data/apps/komodo/backups:/backups

        periphery:
          image: ghcr.io/moghtech/komodo-periphery:latest
          restart: unless-stopped
          env_file: .env
          volumes:
            - /var/run/docker.sock:/var/run/docker.sock
            - /proc:/proc
            - /data/apps/komodo:/etc/komodo

      volumes:
        mongo-data:
        mongo-config:
    '';
  };

  # generic な Tailscale Sidecar abstraction を使う
  services.tailscale-sidecar.instances.komodo = {
    enable = true;
    backend = "podman"; # Komodo sidecar runs in Podman (backend container runs in Docker via compose-service)
    authKeyFile = config.age.secrets.tailscale-auth-key.path;

    serve = {
      enable = true;
      port = 443;
      targetUrl = "http://localhost:9120";
    };

    waitFor = ["komodo.service"];
  };
}
