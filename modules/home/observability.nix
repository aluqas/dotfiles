{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.observability;
in {
  options.saqula.home.observability.enable = lib.mkEnableOption "observability tools" // { default = true; };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      btop
      htop
    ];
  };
}
