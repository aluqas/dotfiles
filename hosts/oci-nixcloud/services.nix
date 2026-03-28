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

  age.secrets.komodo-env = saqulaLib.secrets.mkSecret {
    name = "komodo-env";
    owner = "root";
    mode = "400";
  };

  imports = [
    ./dokploy.nix
    ./komodo.nix
    ./tau.nix
    ./lab/coolify.nix
    ./lab/cyclops.nix
    ./lab/headlamp.nix
  ];

  saqula.system.services = {
    cluster = {
      enable = true;
      portainer = {
        enable = true;
        dockerAgent.enable = true;
        tailscale = {
          hostname = "portainer";
          publicDomain = "fairy-sargas.ts.net";
        };
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
      argocd = {
        ingressHost = "argocd.fairy-sargas.ts.net";
        nodePorts = {
          http = 30080;
          https = 30443;
        };
        tailscale.enable = true;
      };
      rancher = {
        publicDomain = "fairy-sargas.ts.net";
        tailscale.enable = true;
      };
    };

    container = {
      podman.enable = true;
      containerd.enable = true;
    };
  };

  virtualisation.podman.dockerCompat = lib.mkForce false;
}
