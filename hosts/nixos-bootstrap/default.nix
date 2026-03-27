{
  pkgs,
  hostVars,
  globalVars,
  ...
}: {
  imports = [
    ../../profiles/system/nixos-server.nix
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  saqula.core.users = {
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

  networking.hostName = hostVars.hostname;
  networking.firewall.allowedTCPPorts = [22];

  services.openssh.settings = {
    PermitRootLogin = "prohibit-password";
    PasswordAuthentication = false;
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
