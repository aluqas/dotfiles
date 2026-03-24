{
  pkgs,
  lib,
  config,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.system.services.k3s.longhorn;
  inherit (saqulaLib) mkFeatureOptions mkPlatformAssert wrapConfig;
in {
  options.saqula.system.services.k3s.longhorn =
    mkFeatureOptions "Longhorn (Distributed Block Storage)";

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "longhorn";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (wrapConfig cfg {
      # Longhorn Requirements
      services.openiscsi = {
        enable = true;
        name = "iqn.2016-04.com.rancher:k3s";
      };

      environment.systemPackages = with pkgs; [
        openiscsi
        nfs-utils
        util-linux
        cryptsetup
      ];

      # Firewall for Longhorn (if needed, usually in-cluster)
      # Longhorn communicates between nodes.

      systemd.services.longhorn-install = {
        description = "Install Longhorn on K3s";
        after = [
          "k3s.service"
          "network-online.target"
        ];
        requires = ["k3s.service"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];
        path = [
          pkgs.kubectl
          pkgs.kubernetes-helm
        ];
        environment = {
          KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
        };
        script = ''
          echo "Waiting for K3s..."
          until kubectl get nodes; do sleep 5; done

          if kubectl get namespace longhorn-system >/dev/null 2>&1; then
            echo "Longhorn already installed."
            exit 0
          fi

          echo "Installing Longhorn..."
          helm repo add longhorn https://charts.longhorn.io
          helm repo update
          helm install longhorn longhorn/longhorn \
            --namespace longhorn-system \
            --create-namespace \
            --set defaultSettings.createDefaultDiskLabeledNodes=true \
            --wait

          echo "Longhorn installed."
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
    })
  ];
}
