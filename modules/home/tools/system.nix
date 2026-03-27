{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.tools.system;
in {
  options.saqula.home.tools.system.enable = lib.mkEnableOption "system utilities";

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
