# NixOS 専用 module - Darwin では import しない（`flake.nix` で処理）
{
  config,
  lib,
  pkgs,
  inputs,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.core.impermanence;
  usersCfg = config.saqula.core.users;
  btrbkCfg = config.saqula.system.btrbk;
  inherit (usersCfg) username;
  inherit (saqulaLib) mkFeatureOptions mkPlatformAssert wrapConfig;
  inherit (lib) mkEnableOption mkOption types;
in {
  options.saqula.core.impermanence = mkFeatureOptions "system impermanence (NixOS)";

  # btrbk options（impermanence と密結合のためここで定義）
  options.saqula.system.btrbk = {
    enable = mkEnableOption "automated btrfs snapshots";
    persistPath = mkOption {
      type = types.str;
      default = "/persist";
      description = "Path to the persistent storage (btrfs subvolume)";
    };
    retention = {
      hourly = mkOption {
        type = types.int;
        default = 48;
        description = "Number of hourly snapshots to keep";
      };
      daily = mkOption {
        type = types.int;
        default = 7;
        description = "Number of daily snapshots to keep";
      };
      weekly = mkOption {
        type = types.int;
        default = 4;
        description = "Number of weekly snapshots to keep";
      };
    };
  };

  # Home Manager impermanence option
  options.saqula.home.impermanence.enable = mkEnableOption "Home Manager impermanence";

  # NOTE: impermanence module は `flake.nix` レベルで NixOS のみに import している

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "impermanence";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (wrapConfig cfg (lib.mkMerge [
      {
        # =========================================================================
        # 1. System impermanence
        # =========================================================================

        # --- Boot 要件 ---
        fileSystems."/persist".neededForBoot = true;
        boot.initrd.supportedFilesystems = ["btrfs"];

        # --- rollback script（実績のある OCI 版） ---
        boot.initrd.systemd.services.rollback = {
          description = "Rollback BTRFS root subvolume to pristine state";
          wantedBy = ["initrd.target"];
          before = ["sysroot.mount"];
          after = ["local-fs-pre.target"];
          unitConfig.DefaultDependencies = "no";
          serviceConfig = {
            Type = "oneshot";
            SuccessExitStatus = "0 1";
          };
          script = ''
            set -euo pipefail

            # root device を探す
            ROOT_DEV=""
            if [ -e /dev/disk/by-partlabel/disk-main-disk-main-root ]; then
              ROOT_DEV="/dev/disk/by-partlabel/disk-main-disk-main-root"
            elif [ -e /dev/disk/by-partlabel/disk-main-root ]; then
              ROOT_DEV="/dev/disk/by-partlabel/disk-main-root"
            elif [ -e /dev/disk/by-label/nixos ]; then
              ROOT_DEV="/dev/disk/by-label/nixos"
            elif [ -e /dev/sda2 ]; then
              ROOT_DEV="/dev/sda2"
            else
              echo "ERROR: Could not find root device!"
              exit 0
            fi

            mkdir -p /btrfs_tmp
            mount -t btrfs -o subvol=/ "$ROOT_DEV" /btrfs_tmp || exit 0

            if [ ! -d /btrfs_tmp/root ]; then
              umount /btrfs_tmp || true
              exit 0
            fi

            # 古い root を archive する
            mkdir -p /btrfs_tmp/old_roots
            timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%d_%H:%M:%S")
            mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp" || true

            # 古い archive（30 日超）を掃除する
            delete_subvolume_recursively() {
              IFS=$'\n'
              for i in $(btrfs subvolume list -o "$1" 2>/dev/null | cut -f 9- -d ' '); do
                delete_subvolume_recursively "/btrfs_tmp/$i"
              done
              btrfs subvolume delete "$1" 2>/dev/null || true
            }
            for old_root in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30 2>/dev/null); do
              if [ "$old_root" != "/btrfs_tmp/old_roots/" ]; then
                delete_subvolume_recursively "$old_root"
              fi
            done

            # restore する
            if [ -d /btrfs_tmp/root-blank ]; then
              btrfs subvolume snapshot /btrfs_tmp/root-blank /btrfs_tmp/root
            else
              btrfs subvolume create /btrfs_tmp/root
            fi

            umount /btrfs_tmp
          '';
        };

        # --- System persistence ---
        # Core directories（サービス固有のものは各モジュールで追加）
        environment.persistence."/persist" = {
          hideMounts = true;
          directories = [
            "/var/lib/nixos"
            "/var/log"
            {
              directory = "/var/lib/systemd/coredump";
              mode = "0755";
            }
            {
              directory = "/var/lib/systemd/random-seed";
              mode = "0755";
            }
            {
              directory = "/var/lib/age";
              mode = "0700";
            }
            "/etc/NetworkManager/system-connections"
            "/var/lib/docker"
            "/var/lib/acme"
          ];
          files = ["/etc/machine-id"];
        };

        # SSH keys
        services.openssh.hostKeys = [
          {
            path = "/persist/etc/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
          {
            path = "/persist/etc/ssh/ssh_host_rsa_key";
            type = "rsa";
            bits = 4096;
          }
        ];

        # Tmpfiles
        systemd.tmpfiles.rules =
          [
            "d /persist/etc 0755 root root -"
            "d /persist/etc/ssh 0700 root root -"
            "d /persist/etc/NetworkManager 0755 root root -"
            "d /persist/etc/NetworkManager/system-connections 0700 root root -"
            "d /persist/etc/rancher 0755 root root -"
            "d /persist/var 0755 root root -"
            "d /persist/var/lib 0755 root root -"
            "d /persist/var/lib/nixos 0755 root root -"
            "d /persist/var/log 0755 root root -"
            "d /persist/home 0755 root root -"
            "d /persist/home/${username} 0755 ${username} ${username} -"
            "d /persist/home/${username}/.ssh 0700 ${username} ${username} -"
            "d /persist/home/${username}/.gnupg 0700 ${username} ${username} -"
            "d /persist/home/${username}/dotfiles 0755 ${username} ${username} -"
          ]
          ++ lib.optionals (btrbkCfg.enable) [
            "d /persist/.snapshots 0755 root root -"
          ];

        # --- Btrbk backups ---
        services.btrbk.instances.persist = lib.mkIf (btrbkCfg.enable) {
          onCalendar = "hourly";
          settings = {
            snapshot_preserve_min = "2d";
            volume."/persist" = {
              snapshot_dir = ".snapshots";
              subvolume = ".";
            };
          };
        };
      }

      # =========================================================================
      # 2. Home impermanence（Injection）
      # =========================================================================
      {
        home-manager.users.${username} = {
          # NOTE: NixOS impermanence module が Home Manager support を自前で接続する。

          home.persistence."/persist/home/${username}" = lib.mkIf config.saqula.home.impermanence.enable {
            allowOther = true;
            directories = [
              "Downloads"
              "Documents"
              "Pictures"
              "Videos"
              "Music"
              "projects"
              "dotfiles"
              ".ssh"
              ".gnupg"
              ".kube"
              ".docker"
              ".config/gh"
              ".local/share/fish"
              ".local/share/zoxide"
              ".local/share/direnv"
              ".cargo"
              ".rustup"
              ".local/share/mise"
              ".cache/mise"
              ".local/share/nvim"
              ".vscode-server"
            ];
            files = [
              ".bash_history"
              ".zsh_history"
            ];
          };
        };
      }
    ]))
  ];
}
