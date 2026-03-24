{
  config,
  lib,
  ...
}: let
  cfg = config.saqula.home.develop.zellij;
in {
  options.saqula.home.develop.zellij.enable = lib.mkEnableOption "zellij configuration";

  config = lib.mkIf cfg.enable {
    programs.zellij = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        default_mode = "normal";
        copy_command = "pbcopy";
        pane_frames = false;
      };
    };
  };
}
