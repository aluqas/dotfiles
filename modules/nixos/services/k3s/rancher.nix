# K3s 上の Rancher
#
# Helm による宣言的な Rancher デプロイ
#
{
  pkgs,
  lib,
  config,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.system.services.k3s.rancher;
  k3sCfg = config.saqula.system.services.k3s;
  inherit (saqulaLib) mkFeatureOptionsExt mkPlatformAssert wrapConfig;
  inherit (lib) mkOption types mkEnableOption;
in {
  options.saqula.system.services.k3s.rancher = mkFeatureOptionsExt "Rancher Kubernetes Management" {
    hostname = mkOption {
      type = types.str;
      default = "rancher";
      description = "Rancher 用の hostname（Tailscale で使う）";
    };

    tailscale.enable = mkEnableOption "Rancher を Tailscale Operator で公開する";
  };

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "rancher";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (wrapConfig cfg (lib.mkIf k3sCfg.enable {
      # Helm で Rancher をデプロイする
      systemd.services.rancher-deploy = {
        description = "Deploy Rancher to K3s (Helm)";
        after = ["k3s.service" "tailscale-operator-deploy.service" "network-online.target"];
        requires = ["k3s.service"];
        wants = ["network-online.target" "tailscale-operator-deploy.service"];
        wantedBy = ["multi-user.target"];

        path = [pkgs.kubernetes-helm pkgs.kubectl pkgs.k3s];

        environment = {
          KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
        };

        script = ''
          # K3s を待つ
          until kubectl get nodes >/dev/null 2>&1; do
            echo "Waiting for K3s..."
            sleep 5
          done

          # cert-manager を待つ（Rancher に必要）
          echo "Ensuring cert-manager is installed..."
          if ! kubectl get namespace cert-manager 2>/dev/null; then
            kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.yaml
            kubectl wait --for=condition=available deployment/cert-manager -n cert-manager --timeout=300s || true
            kubectl wait --for=condition=available deployment/cert-manager-webhook -n cert-manager --timeout=300s || true
            sleep 30
          fi

          # Rancher の Helm repo を追加する
          helm repo add rancher-stable https://releases.rancher.com/server-charts/stable || true
          helm repo update rancher-stable

          # namespace を作る
          kubectl create namespace cattle-system --dry-run=client -o yaml | kubectl apply -f -

          # Rancher を install / upgrade する
          # SSL termination に Tailscale Ingress を使う
          helm upgrade --install rancher rancher-stable/rancher \
            --namespace cattle-system \
            --set hostname=${cfg.hostname}.fairy-sargas.ts.net \
            --set bootstrapPassword=admin \
            --set replicas=1 \
            --set ingress.enabled=true \
            --set ingress.ingressClassName=tailscale \
            --set ingress.tls.source=secret \
            --set ingress.tls.secretName=rancher-tls \
            --set tls=external \
            --wait --timeout=10m

          echo "Rancher deployed with Tailscale Ingress!"
          echo "Access at: https://${cfg.hostname}.fairy-sargas.ts.net"
        '';

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
    }))
  ];
}
