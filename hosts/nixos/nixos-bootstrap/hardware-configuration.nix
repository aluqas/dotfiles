# ============================================================================
# Hardware Configuration
# ============================================================================
# Generic QEMU/KVM guest configuration compatible with:
#   - aarch64-linux (ARM64): OCI Ampere, AWS Graviton, Hetzner CAX
#   - x86_64-linux (AMD64): Most cloud providers, local VMs
#
# The platform is determined by the `system` attribute in flake.nix,
# not by this file. This file provides kernel modules for various
# storage controllers.
# ============================================================================
{
  lib,
  inputs,
  ...
}: {
  imports = [
    (inputs.nixpkgs + "/nixos/modules/profiles/qemu-guest.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        # USB
        "xhci_pci"
        "usbhid"
        # VirtIO (QEMU/KVM)
        "virtio_pci"
        "virtio_scsi"
        "virtio_blk"
        # SATA/AHCI
        "ahci"
        # NVMe (AWS, modern cloud)
        "nvme"
      ];
      kernelModules = [];
    };
    kernelModules = [];
    extraModulePackages = [];
  };

  # Enable DHCP on all interfaces (cloud-init compatible)
  networking.useDHCP = lib.mkDefault true;

  # Default platform - overridden by flake.nix system attribute
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
