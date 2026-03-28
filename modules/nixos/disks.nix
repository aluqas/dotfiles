# ============================================================================
# Disko Disk 設定モジュール
# ============================================================================
# NixOS 向けに再利用可能な disk 設定パターンを提供する。
#
# この module では、次の共通レイアウトを option で有効化できる。
#   - saqula.core.disks.btrfsRoot: impermanence 対応の標準 Btrfs レイアウト
#   - saqula.core.disks.blockStorage: 任意の追加ストレージ
#
# host 設定での使い方:
#   saqula.core.disks.btrfsRoot = {
#     enable = true;
#     device = "/dev/sda";  # NVMe なら /dev/nvme0n1
#   };
#   saqula.core.disks.blockStorage = {
#     enable = true;
#     device = "/dev/sdb";
#     mountpoint = "/data";
#   };
# ============================================================================
{
  config,
  lib,
  pkgs,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.core.disks;
  inherit (saqulaLib) mkPlatformAssert;
  inherit (lib) mkOption types;
in {
  options.saqula.core.disks = {
    # =========================================================================
    # Btrfs ルートディスク (impermanence 対応の primary boot disk)
    # =========================================================================
    btrfsRoot = {
      enable = lib.mkEnableOption "Btrfs root disk configuration";
      device = mkOption {
        type = types.str;
        default = "/dev/sda";
        description = ''
          primary disk のデバイスパス。
          よくある値:
            - OCI/GCP/Hetzner: /dev/sda
            - AWS EC2: /dev/nvme0n1
            - ローカル VM: /dev/vda
        '';
      };

      bootSize = mkOption {
        type = types.str;
        default = "512M";
        description = "EFI boot partition のサイズ";
      };

      partlabel = mkOption {
        type = types.str;
        default = "disk-main-root";
        description = "root 用の GPT partition label（impermanence rollback で使用）";
      };

      mountOptions = mkOption {
        type = types.listOf types.str;
        default = [
          "compress=zstd"
          "noatime"
        ];
        description = "Btrfs subvolume の mount options";
      };
    };

    # =========================================================================
    # Block Storage (任意の secondary disk)
    # =========================================================================
    blockStorage = {
      enable = lib.mkEnableOption "Optional block storage (secondary disk)";
      device = mkOption {
        type = types.str;
        default = "/dev/sdb";
        description = "block storage のデバイスパス";
      };

      mountpoint = mkOption {
        type = types.str;
        default = "/data";
        description = "block storage の mount point";
      };

      format = mkOption {
        type = types.enum [
          "ext4"
          "xfs"
          "btrfs"
        ];
        default = "ext4";
        description = "block storage の filesystem format";
      };

      nofail = mkOption {
        type = types.bool;
        default = true;
        description = ''
          true の場合は nofail mount option を使い、device がなくても boot できるようにする。
          まだ接続されていない可能性がある cloud block storage で推奨。
        '';
      };

      timeout = mkOption {
        type = types.str;
        default = "10s";
        description = "systemd の device timeout（x-systemd.device-timeout）";
      };
    };
  };

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "disks";
      platforms = ["nixos"];
      inherit pkgs;
    })

    # =========================================================================
    # Btrfs ルート設定
    # =========================================================================
    (lib.mkIf cfg.btrfsRoot.enable {
      disko.devices.disk.main = {
        type = "disk";
        inherit (cfg.btrfsRoot) device;
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = cfg.btrfsRoot.bootSize;
              type = "EF00"; # EFI System Partition
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              name = cfg.btrfsRoot.partlabel;
              content = {
                type = "btrfs";
                extraArgs = ["-f"]; # 強制上書き
                subvolumes = {
                  "/root" = {
                    mountpoint = "/";
                    inherit (cfg.btrfsRoot) mountOptions;
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    inherit (cfg.btrfsRoot) mountOptions;
                  };
                  "/persist" = {
                    mountpoint = "/persist";
                    inherit (cfg.btrfsRoot) mountOptions;
                  };
                };
              };
            };
          };
        };
      };
    })

    # =========================================================================
    # Block Storage 設定
    # =========================================================================
    (lib.mkIf cfg.blockStorage.enable {
      disko.devices.disk.storage = {
        type = "disk";
        inherit (cfg.blockStorage) device;
        content = {
          type = "gpt";
          partitions = {
            data = {
              size = "100%";
              content = {
                type = "filesystem";
                inherit (cfg.blockStorage) format;
                inherit (cfg.blockStorage) mountpoint;
                mountOptions =
                  [
                    "defaults"
                  ]
                  ++ lib.optionals cfg.blockStorage.nofail [
                    "nofail"
                    "x-systemd.device-timeout=${cfg.blockStorage.timeout}"
                  ];
              };
            };
          };
        };
      };
    })
  ];
}
