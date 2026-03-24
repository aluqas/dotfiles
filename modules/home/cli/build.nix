{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.cli.build;
in {
  options.saqula.home.cli.build.enable = lib.mkEnableOption "build tools";

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
