{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.cli.system;
in {
  options.saqula.home.cli.system.enable = lib.mkEnableOption "system utilities";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      fastfetch
      jq
      unzip
      lsof
      tree
      dnsutils
      wget
    ];
  };
}
