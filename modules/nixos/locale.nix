# Locale と timezone の設定 (NixOS only)
#
# 基本的なシステム locale 設定。
# Darwin は timezone の扱いが異なるため、明示的な locale 設定を要しない。
#
{
  config,
  lib,
  pkgs,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.core.locale;
  inherit (saqulaLib) mkFeatureOptionsExt mkPlatformAssert wrapConfig;
in {
  options.saqula.core.locale = mkFeatureOptionsExt "locale and timezone configuration" {
    timezone = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "Asia/Tokyo";
      description = "システム timezone。";
    };

    locale = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "en_US.UTF-8";
      description = "既定のシステム locale。";
    };

    keyMap = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "us";
      description = "コンソールの keymap。";
    };
  };

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "locale";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (wrapConfig cfg (lib.mkMerge [
      (lib.mkIf (cfg.timezone != null) {
        time.timeZone = cfg.timezone;
      })
      (lib.mkIf (cfg.locale != null) {
        i18n.defaultLocale = cfg.locale;
      })
      (lib.mkIf (cfg.keyMap != null) {
        console.keyMap = cfg.keyMap;
      })
    ]))
  ];
}
