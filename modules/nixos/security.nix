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
  inherit (saqulaLib) mkPlatformAssert;
  secrets = saqulaLib.secrets;
  sshDir = secrets.sshDir;
  knownHosts = "${sshDir}/known_hosts";
in {
  options.saqula.core.security = {enable = lib.mkEnableOption "NixOS security integrations";};

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "security (NixOS)";
      platforms = ["nixos"];
      inherit pkgs;
    })

    {
      # age identity を永続ストレージに置き、ロールバックや
      # 一時的な root 再構築をまたいでも復号が動くようにする。
      age.identityPaths = ["/persist/var/lib/age/keys.txt"];
    }

    (lib.mkIf config.saqula.secrets.enable {
      age.secrets.id_ed25519_git = secrets.mkSshKey "id_ed25519_git";
      age.secrets.id_ed25519_emergency = secrets.mkSshKey "id_ed25519_emergency";
      age.secrets.ssh-config = secrets.mkSshConfig "config.age";
      age.secrets.gpg-secret-subkeys = secrets.mkGpgSecret "gpg-secret-subkeys";
      age.secrets.gpg-ownertrust = secrets.mkGpgSecret "gpg-ownertrust";

      system.activationScripts.ssh-known-hosts.text = ''
        if [ ! -d "${sshDir}" ]; then
          mkdir -p "${sshDir}"
        fi

        chown "${secrets.username}" "${sshDir}"
        chmod 700 "${sshDir}"

        if [ ! -e "${knownHosts}" ]; then
          touch "${knownHosts}"
        fi

        chown "${secrets.username}" "${knownHosts}"
        chmod 600 "${knownHosts}"
      '';
    })

    (lib.mkIf cfg.enable {
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
