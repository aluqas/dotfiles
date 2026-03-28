{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.fonts;
in {
  options.saqula.home.fonts = {
    enable = lib.mkEnableOption "font packages" // {default = true;};

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        nerd-fonts.hack
        source-code-pro
        hack-font
      ];
      description = "Font packages installed via Home Manager";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = cfg.packages;
  };
}
