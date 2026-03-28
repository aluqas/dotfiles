{
  pkgs,
  lib,
  hostVars,
  globalVars,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  saqula.secrets.enable = true;

  saqula.core = {
    boot.enable = true;
    programs = {
      enable = true;
      shell = "fish";
    };
    locale = {
      enable = true;
      inherit (hostVars) timezone;
      inherit (hostVars) locale;
    };
    users = {
      enable = true;
      inherit (hostVars) username;
      shell = pkgs.fish;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      authorizedKeys = [hostVars.sshKey];
      passwordlessSudo = true;
    };
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

  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  environment.systemPackages = with pkgs; [
    git
    gh
    rage
    nh
    rsync
  ];

  system.stateVersion = globalVars.stateVersions.nixos;
}
