# Boot 設定 (NixOS only)
#
# host 設定から切り出した共通 boot ロジック。
# EFI パスなどの host 固有 loader 設定は hosts 側に残す。
#
{
  config,
  lib,
  pkgs,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.core.boot;
  inherit (saqulaLib) mkFeatureOptionsExt mkPlatformAssert wrapConfig;
in {
  options.saqula.core.boot = mkFeatureOptionsExt "common boot configuration" {
    enableSystemdInitrd = lib.mkOption {
      type = lib.types.bool;
      default = false;
        description = "initrd で systemd を有効にして起動を速くする";
    };

    kernelSysctl = {
      ipForward = lib.mkOption {
        type = lib.types.bool;
        default = false;
          description = "IPv4 / IPv6 forwarding を有効にする（subnet router / exit node 用）";
      };
    };
  };

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "boot";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (wrapConfig cfg (lib.mkMerge [
      {
        boot.initrd.systemd.enable = cfg.enableSystemdInitrd;
        systemd.targets.multi-user.enable = true;
      }
      (lib.mkIf cfg.kernelSysctl.ipForward {
        boot.kernel.sysctl = {
          "net.ipv4.ip_forward" = 1;
          "net.ipv6.conf.all.forwarding" = 1;
        };
      })
    ]))
  ];
}
