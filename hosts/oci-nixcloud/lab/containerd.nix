# Containerd 環境モジュール
#
# standalone containerd + nerdctl 環境
# host 専用のため option/switch は持たず固定宣言にする。
{
  pkgs,
  ...
}: {
  # containerd を有効化する
  virtualisation.containerd = {
    enable = true;
    settings = {
      version = 2;
      plugins."io.containerd.grpc.v1.cri" = {
        sandbox_image = "registry.k8s.io/pause:3.9";
      };
    };
  };

  # container tool と helper script
  environment.systemPackages = with pkgs; [
    nerdctl # containerd 向けの Docker 互換 CLI
    containerd # container runtime
    runc # 既定の OCI runtime
    cni-plugins # CNI networking
    buildkit # container image builder
    skopeo # container image utility
    dive # image layer explorer

    # helper script
    (writeScriptBin "container-status" ''
      #!/usr/bin/env bash
      echo "=== Containerd Status ==="
      systemctl status containerd --no-pager
      echo ""
      echo "=== BuildKit Status ==="
      systemctl status buildkitd --no-pager
      echo ""
      echo "=== Running Containers ==="
      sudo nerdctl ps -a
    '')
  ];

  # nerdctl 用 CNI 設定（Cilium / Flannel の衝突を避けるため K8s CNI とは分離する）
  environment.etc."nerdctl-cni/net.d/10-nerdctl-bridge.conflist".text = builtins.toJSON {
    cniVersion = "1.0.0";
    name = "nerdctl-bridge";
    plugins = [
      {
        type = "bridge";
        bridge = "nerdctl0";
        isGateway = true;
        ipMasq = true;
        hairpinMode = true;
        ipam = {
          type = "host-local";
          routes = [{dst = "0.0.0.0/0";}];
          subnet = "10.88.0.0/24";
          gateway = "10.88.0.1";
        };
      }
      {
        type = "portmap";
        capabilities = {
          portMappings = true;
        };
      }
      {
        type = "firewall";
      }
      {
        type = "tuning";
      }
    ];
  };

  # BuildKit は system-wide で固定起動する
  systemd.services.buildkitd = {
    description = "BuildKit Daemon";
    after = [
      "containerd.service"
      "network-online.target"
    ];
    requires = ["containerd.service"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];

    path = [
      pkgs.buildkit
      pkgs.runc
    ];

    serviceConfig = {
      ExecStart = "${pkgs.buildkit}/bin/buildkitd --addr unix:///run/buildkit/buildkitd.sock --containerd-worker=true --oci-worker=false";
      Restart = "always";
      RestartSec = "5s";
      RuntimeDirectory = "buildkit";
    };
  };

  # container networking 用に firewall を開く
  networking.firewall.allowedTCPPorts = [];
  networking.firewall.trustedInterfaces = ["nerdctl0"];
}
