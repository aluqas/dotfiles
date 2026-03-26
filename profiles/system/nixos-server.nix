{
  lib,
  hostVars,
  ...
}: {
  saqula.secrets.enable = true;

  saqula.core = {
    boot.enable = true;

    programs = {
      enable = true;
      shell = "fish";
    };

    users.enable = true;

    locale = {
      enable = true;
      inherit (hostVars) timezone;
      inherit (hostVars) locale;
    };
  };

  services.openssh.enable = lib.mkDefault true;

  networking = {
    firewall.enable = lib.mkDefault true;
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
}
