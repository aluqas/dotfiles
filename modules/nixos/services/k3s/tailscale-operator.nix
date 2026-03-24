# Tailscale Kubernetes Operator
#
# `tailscale.com/expose: "true"` のような annotation で、
# K8s Service を Tailnet へ自動公開する。
#
{
  pkgs,
  lib,
  config,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.system.services.k3s.tailscale;
  k3sCfg = config.saqula.system.services.k3s;
  inherit (saqulaLib) mkFeatureOptionsExt mkPlatformAssert wrapConfig;
  inherit (lib) mkOption types concatStringsSep optionalString;
in {
  # mkFeatureOptionsExt をすっきり使う
  options.saqula.system.services.k3s.tailscale = mkFeatureOptionsExt "Tailscale Kubernetes Operator" {
    oauth = {
      clientId = mkOption {
        type = types.str;
        default = "";
        description = "Tailscale 管理コンソールの OAuth Client ID";
      };
      clientSecretFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "OAuth Client Secret を含む file の path";
      };
    };

    tags = mkOption {
      type = types.listOf types.str;
      default = ["tag:k8s-operator"];
      description = "operator が作成した device に付ける tag";
    };
  };

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "tailscale-operator";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (wrapConfig cfg (lib.mkIf k3sCfg.enable {
      systemd.services.tailscale-operator-deploy = {
        description = "Tailscale Kubernetes Operator をデプロイする";
        after = ["k3s.service" "network-online.target"];
        requires = ["k3s.service"];
        wants = ["network-online.target"];
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

          # namespace を作る
          kubectl create namespace tailscale --dry-run=client -o yaml | kubectl apply -f -

          # Secret 作成は Helm の `--set oauth.clientSecret` に任せる

          # Tailscale の Helm repo を追加する
          helm repo add tailscale https://pkgs.tailscale.com/helmcharts
          helm repo update tailscale

          # Operator を install / upgrade する
          helm upgrade --install tailscale-operator tailscale/tailscale-operator \
            --namespace tailscale \
            --set oauth.clientId="${cfg.oauth.clientId}" \
            ${optionalString (cfg.oauth.clientSecretFile != null) ''--set-string oauth.clientSecret="$(cat ${cfg.oauth.clientSecretFile})"''} \
            --set operatorConfig.hostname="k8s-operator" \
            --set-string operatorConfig.defaultTags="${concatStringsSep "," cfg.tags}" \
            --wait

          # Operator が ready になるのを待つ
          kubectl wait --for=condition=available deployment/operator -n tailscale --timeout=120s || true

          echo "Tailscale Operator deployed"
        '';

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };

      environment.systemPackages = with pkgs; [
        (writeScriptBin "tailscale-operator-status" ''
          #!/usr/bin/env bash
          export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
          echo "=== Tailscale Operator Pod ==="
          kubectl get pods -n tailscale
          echo ""
          echo "=== Tailscale-Exposed Services ==="
          kubectl get services --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,EXPOSE:.metadata.annotations.tailscale\.com/expose,HOSTNAME:.metadata.annotations.tailscale\.com/hostname' | grep -v '<none>'
        '')
      ];
    }))
  ];
}
