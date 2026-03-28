{
  pkgs,
  lib,
  config,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.system.services.k3s.vcluster;
  inherit (saqulaLib) mkPlatformAssert;
in {
  options.saqula.system.services.k3s.vcluster = {enable = lib.mkEnableOption "vCluster（Virtual Kubernetes Clusters）";};

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "vcluster";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        vcluster
        kubectl
      ];

      # 既定 vcluster を初期化する optional service も追加できるが、vcluster は通常対話的に使う。
      # ここでは binary が使えることだけを確認する。
    })
  ];
}
