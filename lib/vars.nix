{
  # グローバル既定値
  defaultUser = "saqula";
  defaultTimezone = "Asia/Tokyo";
  defaultLocale = "en_US.UTF-8";
  checkoutDirName = "dotfiles";

  # stateVersion を一元管理する
  stateVersions = {
    home = "24.11"; # Home Manager
    nixos = "25.05"; # NixOS
    darwin = 6; # nix-darwin
  };
}
