{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.tmux;
in {
  options.saqula.home.tmux.enable = lib.mkEnableOption "tmux configuration" // { default = true; };

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
