{
  pkgs,
  lib,
  config,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.system.services.k3s.argocd;
  inherit (saqulaLib) mkFeatureOptionsExt mkPlatformAssert wrapConfig;
  inherit (lib) mkOption types optionalString mkIf;
in {
  # hybrid merge を避けつつ mkFeatureOptionsExt をきれいに使う
  options.saqula.system.services.k3s.argocd = mkFeatureOptionsExt "Argo CD GitOps" {
    tailscale = {
      enable = lib.mkEnableOption "ArgoCD を Tailscale Serve で公開する";
      port = mkOption {
        type = types.port;
        default = 443;
        description = "Tailscale Serve で ArgoCD を公開する HTTPS port";
      };
    };
  };

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "argocd";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (wrapConfig cfg {
      environment.systemPackages = with pkgs; [
        kubernetes-helm
        kubectl
        argocd
      ];

      # firewall port を開く
      networking.firewall.allowedTCPPorts = [30080 30443];

      # Helm で Argo CD を install する oneshot service
      systemd.services.argocd-setup-v2 = {
        description = "Install Argo CD on K3s";
        after = ["k3s.service" "network-online.target"];
        requires = ["k3s.service"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];

        path = [pkgs.kubectl pkgs.kubernetes-helm];

        environment = {
          KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
        };

        script = ''
          # K3s ノードが Ready になるのを待つ（最大 5 分）
          echo "Waiting for K3s to be ready..."
          for i in $(seq 1 60); do
            if kubectl get nodes 2>/dev/null | grep -q " Ready "; then
              echo "K3s is ready."
              break
            fi
            if [ "$i" -eq 60 ]; then
              echo "Timeout: K3s node did not become Ready."
              exit 1
            fi
            sleep 5
          done

          # namespace がなければ作る
          if ! kubectl get namespace argocd 2>/dev/null; then
            echo "Creating Argo CD namespace..."
            kubectl create namespace argocd
          fi

          # まだなければ Argo CD を install する
          if ! kubectl get deployment argocd-server -n argocd 2>/dev/null; then
            echo "Installing Argo CD..."
            kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
          else
            echo "Argo CD already installed. Proceeding to configuration..."
          fi

          # deployment を待つ
          kubectl rollout status deployment argocd-server -n argocd --timeout=300s

          # NodePort にパッチする（Service から Tailscale annotation を除く）
          kubectl patch svc argocd-server -n argocd --type='json' -p='[
            {"op": "replace", "path": "/spec/type", "value": "NodePort"},
            {"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30080},
            {"op": "replace", "path": "/spec/ports/1/nodePort", "value": 30443}
          ]'

          # Tailscale が有効なら Ingress を適用する
          ${optionalString (cfg.tailscale.enable && config.saqula.system.services.k3s.tailscale.enable) ''
            cat <<EOF | kubectl apply -f -
            apiVersion: networking.k8s.io/v1
            kind: Ingress
            metadata:
              name: argocd-tailscale
              namespace: argocd
              annotations:
                tailscale.com/backend-protocol: "https"
            spec:
              ingressClassName: tailscale
              tls:
              - hosts:
                - argocd.fairy-sargas.ts.net
              rules:
              - host: argocd.fairy-sargas.ts.net
                http:
                  paths:
                  - path: /
                    pathType: Prefix
                    backend:
                      service:
                        name: argocd-server
                        port:
                          name: https
            EOF
          ''}

          # 初期 admin password を取得する
          echo "Argo CD installed!"
          echo "Access at: https://localhost:30443"
          echo "Username: admin"
          echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
        '';

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          TimeoutStartSec = "15min";
          Restart = "on-failure";
          RestartSec = "60s";
          StartLimitBurst = 3;
          StartLimitIntervalSec = "10min";
        };
      };

      # ArgoCD 用の Tailscale Serve（Operator を使わない場合の fallback）
      systemd.services.argocd-tailscale-serve = mkIf (cfg.tailscale.enable && !config.saqula.system.services.k3s.tailscale.enable) {
        description = "Expose ArgoCD via Tailscale Serve";
        after = ["tailscaled.service" "argocd-setup-v2.service" "network-online.target"];
        requires = ["tailscaled.service"];
        wants = ["network-online.target" "argocd-setup-v2.service"];
        wantedBy = ["multi-user.target"];

        path = [pkgs.tailscale pkgs.jq];

        script = ''
          # Tailscale が ready になるのを待つ（最大 5 分）
          for i in $(seq 1 150); do
            if tailscale status --json 2>/dev/null | jq -e '.BackendState == "Running"' > /dev/null; then
              echo "Tailscale is running."
              break
            fi
            if [ "$i" -eq 150 ]; then
              echo "Timeout: Tailscale did not become Running."
              exit 1
            fi
            sleep 2
          done

          echo "Exposing ArgoCD on HTTPS :${toString cfg.tailscale.port}"
          tailscale serve --bg --yes --https ${toString cfg.tailscale.port} https+insecure://127.0.0.1:30443
        '';

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          TimeoutStartSec = "10min";
          Restart = "on-failure";
          RestartSec = "30s";
          StartLimitBurst = 3;
          StartLimitIntervalSec = "5min";
        };
      };
    })
  ];
}
