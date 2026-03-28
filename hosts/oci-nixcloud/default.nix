{
  config,
  pkgs,
  lib,
  hostVars,
  globalVars,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./services.nix
  ];

  saqula.secrets.enable = true;

  saqula.core = {
    boot = {
      enable = true;
      kernelSysctl.ipForward = true;
    };
    programs = {
      enable = true;
      shell = "fish";
    };
    locale = {
      enable = true;
      inherit (hostVars) timezone;
      inherit (hostVars) locale;
    };
    impermanence.enable = false;
    optimization.enable = true;
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
  };

  saqula.home.impermanence.enable = true;
  saqula.system.btrbk.enable = true;
  saqula.devex.cachix = {
    enable = true;
    push.enable = true;
  };

  networking = {
    hostName = hostVars.hostname;
    firewall = {
      enable = lib.mkDefault true;
      allowedTCPPorts = [22];
    };
    networkmanager.enable = lib.mkDefault true;
  };

  boot.loader = {
    systemd-boot.enable = lib.mkDefault true;
    efi = {
      canTouchEfiVariables = lib.mkDefault true;
      efiSysMountPoint = lib.mkDefault "/boot";
    };
  };

  nix.settings.experimental-features = lib.mkDefault [
    "nix-command"
    "flakes"
  ];

  fileSystems."/persist".neededForBoot = true;

  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
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
