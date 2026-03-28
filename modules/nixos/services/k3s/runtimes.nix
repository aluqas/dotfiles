# K3s の embedded containerd runtimes
#
# K3s の embedded containerd 用 runtime を設定する。
# standalone containerd なら `modules/services/container` を使う。
#
{
  pkgs,
  lib,
  config,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.system.services.k3s.runtimes;
  inherit (saqulaLib) mkPlatformAssert;
  inherit
    (lib)
    mkOption
    types
    optional
    optionalString
    ;
in {
  options.saqula.system.services.k3s.runtimes = {
    enable = lib.mkEnableOption "K3s containerd runtimes（Youki, Crun, Kata, gVisor）";
    youki.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Youki runtime を有効化する";
    };

    crun.enable = mkOption {
      type = types.bool;
      default = true;
      description = "crun runtime を有効化する";
    };

    kata.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Kata Containers を有効化する";
    };

    gvisor.enable = mkOption {
      type = types.bool;
      default = false;
      description = "gVisor / runsc を有効化する";
    };
  };

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "k3s.runtimes";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (lib.mkIf cfg.enable {
      # runtime パッケージ
      environment.systemPackages = with pkgs;
        [
          containerd
          runc
          nerdctl
        ]
        ++ optional cfg.youki.enable youki
        ++ optional cfg.crun.enable crun
        ++ optional cfg.kata.enable kata-runtime
        ++ optional cfg.gvisor.enable gvisor;

      # K3s embedded containerd の設定
      systemd.tmpfiles.rules = let
        k3sContainerdConfig = pkgs.writeText "config.toml.tmpl" ''
          version = 2

          [plugins."io.containerd.internal.v1.opt"]
            path = "/var/lib/rancher/k3s/agent/containerd"

          [plugins."io.containerd.grpc.v1.cri"]
            stream_server_address = "127.0.0.1"
            stream_server_port = "10010"
            enable_selinux = false
            enable_unprivileged_ports = true
            enable_unprivileged_icmp = true

          [plugins."io.containerd.grpc.v1.cri".containerd]
            snapshotter = "overlayfs"
            disable_snapshot_annotations = true

          [plugins."io.containerd.grpc.v1.cri".cni]
            bin_dirs = ["/var/lib/rancher/k3s/data/current/bin"]
            conf_dir = "/var/lib/rancher/k3s/agent/etc/cni/net.d"

          # 既定の runc
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
            runtime_type = "io.containerd.runc.v2"
            [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
              SystemdCgroup = true

          ${optionalString cfg.youki.enable ''
            # Youki runtime（Rust）
            [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.youki]
              runtime_type = "io.containerd.runc.v2"
              [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.youki.options]
                BinaryName = "${pkgs.youki}/bin/youki"
                SystemdCgroup = true
          ''}

          ${optionalString cfg.crun.enable ''
            # Crun runtime（C, 軽量）
            [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.crun]
              runtime_type = "io.containerd.runc.v2"
              [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.crun.options]
                BinaryName = "${pkgs.crun}/bin/crun"
                SystemdCgroup = true

            # crun 経由の WASM
            [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.wasm]
              runtime_type = "io.containerd.runc.v2"
              [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.wasm.options]
                BinaryName = "${pkgs.crun}/bin/crun"
          ''}

          ${optionalString cfg.kata.enable ''
            # Kata Containers（VM 分離）
            [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata]
              runtime_type = "io.containerd.kata.v2"
              [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata.options]
                ConfigPath = "${pkgs.kata-runtime}/share/defaults/kata-containers/configuration.toml"
          ''}

          ${optionalString cfg.gvisor.enable ''
            # gVisor（sandbox 化された kernel）
            [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
              runtime_type = "io.containerd.runsc.v1"
              [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc.options]
                TypeUrl = "io.containerd.runsc.v1.options"
          ''}
        '';
      in [
        "d /var/lib/rancher/k3s/agent/etc/containerd 0755 root root -"
        "L+ /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl - - - - ${k3sContainerdConfig}"
      ];
    })
  ];
}
