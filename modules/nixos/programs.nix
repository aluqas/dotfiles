# NixOS 専用の runtime 設定
#
# FUSE, nix-ld, などの NixOS 専用 runtime 設定。
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
    enable = lib.mkEnableOption "NixOS runtime integrations";
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
      };
    })
  ];
}
