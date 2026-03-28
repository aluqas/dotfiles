{
  config,
  pkgs,
  lib,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.system.services.k3s.k3s;
  inherit (saqulaLib) mkPlatformAssert;
  inherit (lib) mkDefault mkOption types;
in {
  options.saqula.system.services.k3s.k3s = {
    enable = lib.mkEnableOption "k3s（Kubernetes）server";
    package = mkOption {
      type = types.package;
      default = pkgs.k3s;
      description = "使用する K3s package";
    };
    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [
        "--write-kubeconfig-mode 644"
        "--disable traefik"
      ];
      description = "k3s server に渡す追加フラグ";
    };
  };

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "k3s";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (lib.mkIf cfg.enable {
      # K3s package
      environment.systemPackages = [
        cfg.package
        pkgs.k9s

        # nerdctl
      ];

      services.k3s = {
        enable = true;
        inherit (cfg) package;
        role = "server";
        extraFlags = toString cfg.extraFlags;
      };

      # k3s 用の firewall ルール
      networking.firewall.allowedTCPPorts = [
        6443 # k3s API
      ];

      # K3s / Rancher persistence（impermanence 有効時）
      environment.persistence."/persist".directories = [
        "/var/lib/rancher"
        "/etc/rancher"
      ];

      # k3s と強く結びついているため、k3s 有効時は runtimes も既定で有効化する
      saqula.system.services.k3s.runtimes.enable = mkDefault true;
    })
  ];
}
