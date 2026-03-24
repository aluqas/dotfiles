# NixOS 専用の security 設定
#
# NixOS の GPG agent 設定。
# このファイルは NixOS でのみ import する。
# guardrails は `guardrails.nix` に分離してある。
#
{
  config,
  lib,
  pkgs,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.core.security;
  inherit (saqulaLib) mkFeatureOptions mkPlatformAssert wrapConfig;
in {
  options.saqula.core.security = mkFeatureOptions "NixOS security integrations";

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "security (NixOS)";
      platforms = ["nixos"];
      inherit pkgs;
    })

    {
      # age identity を永続ストレージに置き、ロールバックや
      # 一時的な root 再構築をまたいでも復号が動くようにする。
      age.identityPaths = [ "/persist/var/lib/age/keys.txt" ];
    }

    (wrapConfig cfg {
      # =========================================================================
      # GPG 設定 (NixOS)
      # =========================================================================
      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
        pinentryPackage = pkgs.pinentry-curses;
      };
    })
  ];
}
