# Minimal server profile
#
# lean な server deployment 向けに不要機能を無効化する。
# NixOS 専用 module。
#
{
  config,
  lib,
  pkgs,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.core.minimal;
  inherit (saqulaLib) mkPlatformAssert;
in {
  options.saqula.core.minimal = {
    enable = lib.mkEnableOption "minimal server profile";
    disableDocumentation = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "documentation 生成を無効化する";
    };

    disableXdg = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "XDG portal と desktop service を無効化する";
    };
  };

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "minimal";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (lib.mkIf cfg.enable (lib.mkMerge [
      (lib.mkIf cfg.disableDocumentation {
        documentation.enable = false;
      })
      (lib.mkIf cfg.disableXdg {
        xdg.portal.enable = lib.mkDefault false;
      })
      {
        # autologin を無効化する
        services.getty.autologinUser = null;
      }
    ]))
  ];
}
