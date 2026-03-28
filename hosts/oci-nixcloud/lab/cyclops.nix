# Cyclops Kubernetes UI
#
# 開発者向けの Kubernetes deployment interface
# https://cyclops-ui.com
#
{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [
    kubernetes-helm
    kubectl
  ];

  # firewall port を開く
  networking.firewall.allowedTCPPorts = [3000];

  # Helm で Cyclops を install する oneshot service
  systemd.services.cyclops-install = {
    description = "Install Cyclops on K3s";
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
      # K3s が ready になるのを待つ
      echo "Waiting for K3s to be ready..."
      for i in $(seq 1 60); do
        if kubectl get nodes 2>/dev/null | grep -q "Ready"; then
          break
        fi
        sleep 5
      done

      # Cyclops がすでに入っているか確認する
      if kubectl get namespace cyclops 2>/dev/null; then
        echo "Cyclops namespace already exists."
        exit 0
      fi

      echo "Installing Cyclops..."

      # Cyclops の Helm repo を追加する
      helm repo add cyclops https://cyclops-ui.com/charts
      helm repo update

      # namespace を作って install する
      kubectl create namespace cyclops
      helm install cyclops cyclops/cyclops \
        --namespace cyclops \
        --set cyclops-ctrl.service.type=NodePort \
        --set cyclops-ctrl.service.nodePort=3000 \
        --wait --timeout 10m

      echo "Cyclops installed! Access at: http://localhost:3000"
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  # Cyclops 用の Tailscale サイドカー
  services.tailscale-sidecar.instances.cyclops = {
    enable = true;
    backend = "podman";
    authKeyFile = config.age.secrets.tailscale-auth-key.path;
    serve = {
      enable = true;
      port = 443;
      targetUrl = "http://localhost:3000";
    };
    waitFor = ["cyclops-install.service"];
  };
}
