{
  config,
  pkgs,
  hostVars,
  globalVars,
  ...
}: {
  imports = [
    ../../profiles/system/nixos-server.nix
    ../../profiles/system/nixos-oci-node.nix
    ./hardware-configuration.nix
    ./disk-config.nix
    ./services.nix
  ];

  saqula.core = {
    network.tailscale = {
      enable = true;
      authKeyFile = config.age.secrets.tailscale-auth-key.path;
      inherit (hostVars.networking) acceptRoutes;
      inherit (hostVars.networking) advertiseExitNode;
      advertiseRoutes = hostVars.networking.subnets;
      inherit (hostVars.networking) hostname;
      ssh = true;
      advertiseTags = ["tag:server"];
    };

    users = {
      enable = true;
      inherit (hostVars) username;
      shell = pkgs.fish;
      extraGroups = [
        "networkmanager"
        "fuse"
        "wheel"
      ];
      authorizedKeys = [hostVars.sshKey];
      passwordlessSudo = true;
    };

    boot = {
      enable = true;
      kernelSysctl.ipForward = true;
    };
  };

  networking.hostName = hostVars.hostname;
  networking.firewall.allowedTCPPorts = [22];
  fileSystems."/persist".neededForBoot = true;

  services.openssh.settings = {
    PermitRootLogin = "prohibit-password";
    PasswordAuthentication = false;
  };

  systemd.tmpfiles.rules = let
    inherit (hostVars.disks.blockStorage) paths;
  in [
    "d ${paths.docker} 0755 root root -"
    "d ${paths.podman} 0755 root root -"
    "d ${paths.k3s} 0755 root root -"
    "d ${paths.k3s}-system 0700 root root -"
    "d ${paths.apps} 0755 root root -"
    "d ${paths.backups} 0755 root root -"
  ];

  virtualisation.docker.daemon.settings.data-root = hostVars.disks.blockStorage.paths.docker;

  virtualisation.containers.storage.settings.storage.graphroot = hostVars.disks.blockStorage.paths.podman;

  saqula.system.services.k3s.k3s.extraFlags = [
    "--default-local-storage-path ${hostVars.disks.blockStorage.paths.k3s}"
    "--data-dir ${hostVars.disks.blockStorage.paths.k3s}-system"
  ];

  system.stateVersion = globalVars.stateVersions.nixos;
}
