{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.alacritty;
in {
  options.saqula.home.alacritty.enable = lib.mkEnableOption "alacritty terminal configuration" // {default = true;};

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        terminal.shell.program = "${pkgs.fish}/bin/fish";

        window = {
          decorations = "Transparent";
          padding = {
            x = 10;
            y = 25;
          };
          opacity = 0.6;
          blur = true;
          option_as_alt = "Both";
        };

        font = {
          normal = {
            family = "HackGen35 Console NF";
            style = "Regular";
          };
          size = 14;
        };
      };
    };
  };
}
