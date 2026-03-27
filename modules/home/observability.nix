{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.tools.observability;
in {
  options.saqula.home.tools.observability.enable = lib.mkEnableOption "observability tools";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      btop
      htop
    ];
  };
}
