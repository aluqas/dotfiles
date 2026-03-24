{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.saqula.system.services.k3s;
in {
  imports = [
    ./k3s.nix
    ./runtimes.nix
    ./cilium.nix
    ./argocd.nix
    ./vcluster.nix
    ./kubevirt.nix
    ./longhorn.nix
    ./tailscale-operator.nix
    ./rancher.nix
  ];

  options.saqula.system.services.k3s = {
    enable = mkEnableOption "Kubernetes cluster stack（K3s + runtimes + tools）";
  };

  config = mkIf cfg.enable {
    # Portainer を有効化する（Server は Podman、Agent は K3s）
    saqula.system.services.cluster.portainer = {
      enable = mkDefault true;
      k3sAgent.enable = mkDefault true; # Agent を K3s に配置する
    };

    saqula.system.services.k3s = {
      k3s.enable = mkDefault true;
      cilium.enable = mkDefault true;
      argocd.enable = mkDefault true;
      vcluster.enable = mkDefault true;
      rancher.enable = mkDefault true; # Rancher を有効化する

      # 任意の addon（既定: 無効）
      kubevirt.enable = mkDefault false;
      longhorn.enable = mkDefault false;
    };
  };
}
