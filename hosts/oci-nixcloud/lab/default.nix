{
  lib,
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
    ./compose-service.nix
    ./coolify.nix
    ./dokploy.nix
    ./komodo.nix
    ./tau.nix
  ];

  saqula.system.services = {
    container = {
      podman.enable = true;
      containerd.enable = true;
    };
  };

  virtualisation.podman.dockerCompat = lib.mkForce false;
}
