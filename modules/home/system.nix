{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.system;
in {
  options.saqula.home.system.enable = lib.mkEnableOption "system utilities" // { default = true; };

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
