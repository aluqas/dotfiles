{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.build;
in {
  options.saqula.home.build.enable = lib.mkEnableOption "build tools" // { default = true; };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      cmake
      ninja
      gnumake
      gcc
      openssl
      pkg-config
    ];
  };
}
