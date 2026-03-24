{
  pkgs,
  lib,
  config,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.system.services.k3s.cilium;
  inherit (saqulaLib) mkFeatureOptions mkPlatformAssert wrapConfig;
in {
  options.saqula.system.services.k3s.cilium = mkFeatureOptions "Cilium eBPF Networking";

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "cilium";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (wrapConfig cfg {
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

          # Cilium がすでに入っているか確認する（running pod を見る）
          if cilium status --wait=false 2>/dev/null | grep -q "Cilium:"; then
            echo "Cilium already running. Skipping install."
            cilium status
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
          cilium status --wait

          echo "Cilium configured (Gateway API enabled)!"
          echo "Run 'cilium hubble ui' to access the Hubble UI"
        '';

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
    })
  ];
}
