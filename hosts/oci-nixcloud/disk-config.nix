# ============================================================================
# Disko Disk Configuration for OCI NixCloud
# ============================================================================
# Btrfs layout with subvolumes for root, nix, and persist.
# Optional block storage support with nofail for graceful degradation.
#
# Configuration is controlled via hostVars.disks:
#   - blockStorage.enable: Whether to include /dev/sdb configuration
#   - blockStorage.device: Device path (default: /dev/sdb)
#   - blockStorage.mountpoint: Mount point (default: /data)
# ============================================================================
{
  lib,
  hostVars,
  ...
}: let
  # Block storage configuration with safe defaults
  blockStorageCfg =
    hostVars.disks.blockStorage or {
      enable = false;
      device = "/dev/sdb";
      mountpoint = "/data";
    };
in {
  disko.devices = {
    disk = lib.mkMerge [
      # =======================================================================
      # Primary Boot Disk (Always present)
      # =======================================================================
      {
        main = {
          type = "disk";
          device = "/dev/sda";
          content = {
            type = "gpt";
            partitions = {
              boot = {
                size = "512M";
                type = "EF00"; # EFI System Partition
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              };
              root = {
                size = "100%";
                # Explicit name for partlabel - used by impermanence rollback script
                name = "disk-main-root";
                content = {
                  type = "btrfs";
                  extraArgs = ["-f"]; # Force overwrite
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                  };
                };
              };
            };
          };
        };
      }

      # =======================================================================
      # Block Storage (Optional - controlled by hostVars.disks.blockStorage)
      # =======================================================================
      # Uses nofail to allow boot even if device is missing or not ready.
      # x-systemd.device-timeout prevents long waits at boot.
      (lib.mkIf blockStorageCfg.enable {
        storage = {
          type = "disk";
          inherit (blockStorageCfg) device;
          content = {
            type = "gpt";
            partitions = {
              data = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  inherit (blockStorageCfg) mountpoint;
                  # nofail: Don't fail boot if device is missing
                  # x-systemd.device-timeout: Don't wait long for device
                  mountOptions = [
                    "defaults"
                    "nofail"
                    "x-systemd.device-timeout=10s"
                  ];
                };
              };
            };
          };
        };
      })
    ];
  };
}
