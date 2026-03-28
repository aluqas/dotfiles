{
  pkgs,
  lib,
  config,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.system.services.k3s.kubevirt;
  inherit (saqulaLib) mkPlatformAssert;
in {
  options.saqula.system.services.k3s.kubevirt = {enable = lib.mkEnableOption "KubeVirt (Kubernetes Virtualization)";};

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "kubevirt";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        kubevirt # virtctl
      ];

      # KubeVirt requires KVM nesting if running inside VM (usually)
      # But here we just ensure KVM modules are loaded if bare metal
      boot.kernelModules = [
        "kvm-intel"
        "kvm-amd"
      ];

      systemd.services.kubevirt-install = {
        description = "Install KubeVirt on K3s";
        after = [
          "k3s.service"
          "network-online.target"
        ];
        requires = ["k3s.service"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];
        path = [
          pkgs.kubectl
          pkgs.kubevirt
        ];
        environment = {
          KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
        };
        script = ''
          echo "Waiting for K3s..."
          until kubectl get nodes; do sleep 5; done

          if kubectl get namespace kubevirt >/dev/null 2>&1; then
            echo "KubeVirt already installed."
            exit 0
          fi

          echo "Installing KubeVirt Operator..."
          RELEASE=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
          kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/''${RELEASE}/kubevirt-operator.yaml"

          echo "Installing KubeVirt CR..."
          kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/''${RELEASE}/kubevirt-cr.yaml"

          echo "Waiting for KubeVirt..."
          kubectl -n kubevirt wait kv kubevirt --for condition=Available --timeout=300s
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
    })
  ];
}
