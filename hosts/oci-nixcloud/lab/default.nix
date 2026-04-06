{
  lib,
  pkgs,
  saqulaLib,
  ...
}: {
  age.secrets.tailscale-auth-key = saqulaLib.secrets.mkSecret {
    name = "tailscale-auth-key";
    owner = "root";
    mode = "400";
  };

  imports = [
    ./containerd.nix
    ./podman.nix
    ./runtimes.nix
    ./tailscale-service.nix
    ./coolify.nix
    ./dokploy.nix
    ./komodo.nix
    ./tau.nix
  ];

  saqula.system.services = {
    container = {
      podman.enable = true;
    };
  };

  virtualisation.arion.backend = "docker";

  environment.systemPackages = [
    pkgs.arion
    pkgs.docker-client
  ];

  virtualisation.podman.dockerCompat = lib.mkForce false;
}
