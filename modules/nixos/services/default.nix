# NixOS Services モジュール
#
# NixOS 専用の service module をまとめ、共通の service 基盤
# （firewall、Tailscale Serve など）を提供する。
#
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.saqula.services;
in {
  imports = [
    ./k3s
    ./cluster
  ];

  # 実装は modules/shared/options.nix の中央オプションを使う

  config = {
    # 1. firewall を自動設定する
    networking.firewall.allowedTCPPorts = mapAttrsToList (_: svc: svc.port) (
      filterAttrs (_: svc: svc.enable && svc.expose.firewall) cfg
    );

    # 2. Tailscale Serve を自動設定する
    # 注意: upstream にはまだ services.tailscale.serve が存在しない。
    # 特定の `tailscale serve` コマンド用に独自 module を作るか、systemd を使う必要がある。
    # いったん build を通すため、ここでは無効化している。
    # services.tailscale.serve =
    #   mkMerge (
    #     mapAttrsToList (name: svc: {
    #        "${if svc.expose.ingress != null then svc.expose.ingress else name}" = {
    #          port = svc.port;
    #        };
    #     })
    #     (filterAttrs (_: svc: svc.enable && svc.expose.tailscale) cfg)
    #   );
  };
}
