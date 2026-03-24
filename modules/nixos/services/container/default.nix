# Container Services モジュール
#
# 各種 container runtime と tool をまとめる
#
{...}: {
  imports = [
    ./containerd.nix
    ./podman.nix
    ./runtimes.nix
    ./tailscale-sidecar.nix
    ./compose-service.nix
  ];

  # 必要ならトップレベルの container 設定をここに定義する
}
