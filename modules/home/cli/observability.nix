{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.cli.observability;
in {
  options.saqula.home.cli.observability.enable = lib.mkEnableOption "observability tools";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      btop
      htop
    ];
  };
}
