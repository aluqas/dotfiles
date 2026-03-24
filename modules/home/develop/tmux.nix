{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.develop.tmux;
in {
  options.saqula.home.develop.tmux.enable = lib.mkEnableOption "tmux configuration";

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      clock24 = true;
      escapeTime = 0;
      keyMode = "vi";
      mouse = true;
      shell = "${pkgs.fish}/bin/fish";
      terminal = "screen-256color";
    };
  };
}
