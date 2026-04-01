# Komodo Container Management
#
# Podman 上で Komodo Core / Periphery を動かす。
#
{config, ...}: {
  networking.firewall.allowedTCPPorts = [
    9120
    8120
  ];

  services.compose-service.instances.komodo = {
    enable = true;
    backend = "podman";
    workDir = "/data/apps/komodo";
    extraDirs = ["backups"];

    environment = {
      COMPOSE_KOMODO_IMAGE_TAG = "latest";
      COMPOSE_KOMODO_BACKUPS_PATH = "/data/apps/komodo/backups";

      KOMODO_DB_USERNAME = "admin";
      KOMODO_DB_PASSWORD = "komodo_secure_password_2024";
      KOMODO_PASSKEY = "komodo_passkey_secure_2024";

      TZ = "Asia/Tokyo";

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
            - /run/podman/podman.sock:/var/run/docker.sock
            - /proc:/proc
            - /data/apps/komodo:/etc/komodo

      volumes:
        mongo-data:
        mongo-config:
    '';
  };

  services.tailscale-sidecar.instances.komodo = {
    enable = true;
    backend = "podman";
    authKeyFile = config.age.secrets.tailscale-auth-key.path;

    serve = {
      enable = true;
      port = 443;
      targetUrl = "http://localhost:9120";
    };

    waitFor = ["komodo.service"];
  };
}
