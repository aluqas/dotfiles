{
  config,
  lib,
  saqulaLib,
  ...
}: {
  age.secrets.tailscale-auth-key = saqulaLib.secrets.mkSecret {
    name = "tailscale-auth-key";
    owner = "root";
    mode = "400";
  };

  age.secrets.tailscale-oauth-client-secret = saqulaLib.secrets.mkSecret {
    name = "tailscale-oauth-client-secret";
    owner = "root";
    mode = "400";
  };

  imports = [
    ./dokploy.nix
    ./komodo.nix
    ./tau.nix
  ];

  saqula.system.services = {
    cluster = {
      enable = true;
      portainer = {
        enable = true;
        dockerAgent.enable = true;
      };
    };

    k3s = {
      enable = true;
      runtimes = {
        enable = true;
        youki.enable = true;
        crun.enable = true;
      };
      tailscale = {
        enable = true;
        oauth = {
          clientId = "kfDb6FYm7C21CNTRL";
          clientSecretFile = config.age.secrets.tailscale-oauth-client-secret.path;
        };
      };
      argocd.tailscale.enable = true;
      rancher.tailscale.enable = true;
    };

    container = {
      podman.enable = true;
      containerd.enable = true;
    };
  };

  virtualisation.podman.dockerCompat = lib.mkForce false;
}
