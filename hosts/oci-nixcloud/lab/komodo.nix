# Komodo Container Management
#
# Arion で Komodo Core / Periphery を動かす。
{...}: {
  networking.firewall.allowedTCPPorts = [
    9120
    8120
  ];

  systemd.tmpfiles.rules = [
    "d /data/apps/komodo 0755 root root -"
    "d /data/apps/komodo/backups 0755 root root -"
    "d /data/apps/komodo/mongo-data 0755 root root -"
    "d /data/apps/komodo/mongo-config 0755 root root -"
  ];
  virtualisation.arion.projects.komodo = {
    serviceName = "komodo";
    settings = {
      project.name = "komodo";

      services = {
        mongo.service = {
          image = "mongo:7";
          command = [
            "--quiet"
            "--wiredTigerCacheSizeGB"
            "0.25"
          ];
          restart = "unless-stopped";
          environment = {
            MONGO_INITDB_ROOT_USERNAME = "admin";
            MONGO_INITDB_ROOT_PASSWORD = "komodo_secure_password_2024";
          };
          volumes = [
            "/data/apps/komodo/mongo-data:/data/db"
            "/data/apps/komodo/mongo-config:/data/configdb"
          ];
        };

        core.service = {
          image = "ghcr.io/moghtech/komodo-core:2";
          restart = "unless-stopped";
          depends_on = ["mongo"];
          ports = [
            "9120:9120"
          ];
          environment = {
            TZ = "Asia/Tokyo";
            KOMODO_DB_USERNAME = "admin";
            KOMODO_DB_PASSWORD = "komodo_secure_password_2024";
            KOMODO_PASSKEY = "komodo_passkey_secure_2024";
            KOMODO_DATABASE_ADDRESS = "mongo:27017";
            KOMODO_DATABASE_USERNAME = "admin";
            KOMODO_DATABASE_PASSWORD = "komodo_secure_password_2024";
            KOMODO_LOCAL_AUTH = "true";
            KOMODO_DISABLE_USER_REGISTRATION = "false";
            KOMODO_SERVERS = "[]";
          };
          volumes = [
            "/data/apps/komodo/backups:/backups"
          ];
        };

        periphery.service = {
          image = "ghcr.io/moghtech/komodo-periphery:latest";
          restart = "unless-stopped";
          environment = {
            TZ = "Asia/Tokyo";
          };
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock"
            "/proc:/proc"
            "/data/apps/komodo:/etc/komodo"
          ];
        };
      };

    };
  };
}
