# ============================================================================
# Disko Disk Configuration
# ============================================================================
# Btrfs layout with subvolumes for root, nix, and persist.
# The /persist subvolume is pre-created for future impermanence migration.
#
# Common device names by provider:
#   - OCI (Oracle Cloud): /dev/sda
#   - GCP (Google Cloud): /dev/sda
#   - AWS EC2:            /dev/nvme0n1
#   - Hetzner:            /dev/sda or /dev/nvme0n1
#   - Local VM:           /dev/vda or /dev/sda
# ============================================================================
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # TODO: Verify this matches your target disk
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
                  # Pre-create /persist for future impermanence migration
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
    };
  };
}
