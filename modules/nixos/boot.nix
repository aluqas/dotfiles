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
  inherit (saqulaLib) mkPlatformAssert;
in {
  options.saqula.core.boot = {
    enable = lib.mkEnableOption "common boot configuration";
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

    (lib.mkIf cfg.enable {
      boot.initrd.systemd.enable = cfg.enableSystemdInitrd;
      systemd.targets.multi-user.enable = true;
      boot.kernel.sysctl = lib.mkIf cfg.kernelSysctl.ipForward {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
      };
    })
  ];
}
