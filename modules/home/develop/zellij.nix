{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.develop.zellij;
in {
  options.saqula.home.develop.zellij.enable = lib.mkEnableOption "zellij configuration";

  config = lib.mkIf cfg.enable {
    programs.zellij = {
      enable = true;
      enableFishIntegration = false;
      settings = {
        default_shell = "${pkgs.fish}/bin/fish";
        default_mode = "normal";
        copy_command = "pbcopy";
        pane_frames = false;
        session_serialization = false;
        show_startup_tips = false;
      };
    };
  };
}
