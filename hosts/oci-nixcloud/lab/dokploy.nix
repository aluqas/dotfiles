# Dokploy PaaS
#
# Arion で Dokploy / Postgres / Redis / Traefik を宣言的に管理する。
{
  pkgs,
  ...
}: {
  virtualisation.docker.enable = true;

  networking.firewall.allowedTCPPorts = [
    3001
    8880
    8843
  ];

  systemd.tmpfiles.rules = [
    "d /data/apps/dokploy 0755 root root -"
    "d /data/apps/dokploy/postgres 0755 root root -"
    "d /data/apps/dokploy/redis 0755 root root -"
    "d /data/apps/dokploy/docker 0755 root root -"
  ];

  virtualisation.arion.projects.dokploy = {
    serviceName = "dokploy";
    settings = {
      project.name = "dokploy";

      services = {
        postgres.service = {
          image = "postgres:16";
          restart = "always";
          networks = ["dokploy-network"];
          environment = {
            POSTGRES_USER = "dokploy";
            POSTGRES_DB = "dokploy";
            POSTGRES_PASSWORD = "dokploy_postgres_password_2026";
          };
          volumes = [
            "/data/apps/dokploy/postgres:/var/lib/postgresql/data"
          ];
        };

        redis.service = {
          image = "redis:7";
          restart = "always";
          networks = ["dokploy-network"];
          volumes = [
            "/data/apps/dokploy/redis:/data"
          ];
        };

        dokploy.service = {
          image = "dokploy/dokploy:latest";
          restart = "always";
          networks = ["dokploy-network"];
          depends_on = [
            "postgres"
            "redis"
          ];
          ports = [
            "3001:3000"
          ];
          extra_hosts = [
            "host.docker.internal:host-gateway"
          ];
          environment = {
            ADVERTISE_ADDR = "host.docker.internal";
          };
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock"
            "/data/apps/dokploy:/etc/dokploy"
            "/data/apps/dokploy/docker:/root/.docker"
          ];
        };

        traefik.service = {
          image = "traefik:v3.6.1";
          restart = "always";
          networks = ["dokploy-network"];
          depends_on = ["dokploy"];
          ports = [
            "8880:80"
            "8843:443"
            "8843:443/udp"
          ];
          command = [
            "--providers.docker=true"
            "--providers.docker.exposedbydefault=false"
            "--entrypoints.web.address=:80"
            "--entrypoints.websecure.address=:443"
          ];
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock:ro"
          ];
        };
      };

      networks.dokploy-network = {
        driver = "bridge";
        name = "dokploy-network";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    (writeScriptBin "dokploy-logs" ''
      #!/usr/bin/env bash
      docker logs -f dokploy-dokploy-1
    '')
  ];
}
