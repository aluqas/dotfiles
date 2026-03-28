{
  pkgs,
  lib,
  config,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.system.services.k3s.cilium;
  inherit (saqulaLib) mkPlatformAssert;
in {
  options.saqula.system.services.k3s.cilium = {enable = lib.mkEnableOption "Cilium eBPF Networking";};

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "cilium";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        kubernetes-helm
        kubectl
        cilium-cli
        hubble
      ];

      # Hubble UI 用の firewall port を開く
      networking.firewall.allowedTCPPorts = [
        4245
        12000
      ];

      # Helm で Cilium を install する oneshot service
      systemd.services.cilium-install = {
        description = "Install Cilium on K3s";
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
          pkgs.cilium-cli
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

          # Cilium DaemonSet の存在で install 済みを確認する（status grep より確実）
          if kubectl get daemonset cilium -n kube-system >/dev/null 2>&1; then
            echo "Cilium already installed."
            cilium status || true
            exit 0
          fi

          echo "Installing Cilium..."

          # Cilium を install する
          cilium install \
            --set kubeProxyReplacement=true \
            --set hubble.relay.enabled=true \
            --set hubble.ui.enabled=true \
            --set gatewayAPI.enabled=true

          # Cilium が ready になるのを待つ
          cilium status --wait --wait-duration 10m

          echo "Cilium configured (Gateway API enabled)!"
          echo "Run 'cilium hubble ui' to access the Hubble UI"
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
    })
  ];
}
