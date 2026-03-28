# NixOS 専用の programs 設定
#
# FUSE, nix-ld, などの NixOS 専用 program 設定。
# この module は NixOS でのみ import する。
#
{
  config,
  lib,
  pkgs,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.core.programs;
  inherit (saqulaLib) mkPlatformAssert;
in {
  options.saqula.core.programs = {
    enable = lib.mkEnableOption "NixOS program integrations";
    shell = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["fish"]);
      default = null;
      description = "system レベルで有効にする宣言的な login shell サポート。";
    };
  };

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "programs (NixOS)";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (lib.mkIf cfg.enable {
      programs = {
        # ユーザー mount 用の FUSE (impermanence)
        fuse.userAllowOther = true;

        # 非 Nix バイナリ向けの dynamic linker
        nix-ld = {
          enable = true;
          libraries = [];
        };

        fish.enable = cfg.shell == "fish";
      };
    })
  ];
}
