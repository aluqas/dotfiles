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
  secrets = saqulaLib.secrets;
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

      # SSH keys（Darwin の base.nix と対称になるように定義）
      age.secrets.id_ed25519_git = secrets.mkSshKey "id_ed25519_git";
      age.secrets.id_ed25519_emergency = secrets.mkSshKey "id_ed25519_emergency";
      age.secrets.ssh-config = secrets.mkSshConfig "config.age";
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
