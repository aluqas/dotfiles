{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.fonts;
  darwinOptionalTimesFonts =
    lib.optional (lib.hasAttr "times-new-roman" pkgs) (lib.getAttr "times-new-roman" pkgs)
    ++ lib.optional (lib.hasAttr "times-newer-roman" pkgs) (lib.getAttr "times-newer-roman" pkgs);
in {
  options.saqula.home.fonts = {
    enable = lib.mkEnableOption "font packages" // {default = true;};

    darwinBrewCasks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = lib.optionals pkgs.stdenv.isDarwin [
        "font-biz-udmincho"
        "font-cica"
        "font-computer-modern"
        "font-firgenerd"
        "font-genjyuugothic"
        "font-genryumin"
        "font-genshingothic"
        "font-genyogothic"
        "font-genyomin"
        "font-m-plus-1"
        "font-m-plus-1-code"
        "font-m-plus-2"
        "font-monaspice-nerd-font"
        "font-new-computer-modern"
        "font-noto-sans"
        "font-noto-sans-cjk-jp"
        "font-noto-sans-math"
        "font-noto-sans-mono-cjk-jp"
        "font-noto-serif"
        "font-noto-serif-cjk-jp"
        "font-noto-sans-symbols"
        "font-noto-sans-symbols-2"
        "font-noto-music"
        "font-noto-color-emoji"
        "font-noto-emoji"
      ];
      description = "Darwin 向けに Homebrew cask で補完するフォント一覧";
    };

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;


      default =
        (with pkgs; [
        hackgen-nf-font
        hubot-sans
        mona-sans
        plemoljp-nf
        source-code-pro
        biz-ud-gothic
        hack-font
        maple-mono.NF-CN
        mplus-outline-fonts.githubRelease

        monaspace
        nerd-fonts.monaspace
        udev-gothic-nf
      ])
        ++ darwinOptionalTimesFonts;
      description = "Font packages installed via Home Manager";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = cfg.packages;
  };
}
