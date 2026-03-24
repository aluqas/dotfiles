# 共有型定義
#
# モジュール全体で使う共通型。最小限に保つ。
#
{lib, ...}:
with lib; let
  # 統一された service 定義のための submodule 型
  serviceOpts = {name, ...}: {
    options = {
      name = mkOption {
        type = types.str;
        default = name;
        description = "service 名";
      };

      enable = mkEnableOption "service を有効化する";

      description = mkOption {
        type = types.str;
        description = "service の説明";
      };

      port = mkOption {
        type = types.int;
        description = "service が待ち受けるポート";
      };

      category = mkOption {
        type = types.str;
        default = "Applications";
        description = "ダッシュボードでの分類名";
      };

      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "service の外部 URL（既定の自動生成より優先）";
      };

      icon = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "ダッシュボード用の icon 名（例: `radarr.png`）";
      };

      expose = {
        tailscale = mkOption {
          type = types.bool;
          default = false;
          description = "Tailscale Serve で公開する";
        };
        firewall = mkOption {
          type = types.bool;
          default = true;
          description = "firewall ポートを開く（LAN 向け）";
        };
        ingress = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Ingress のホスト名（例: `foo.internal`）";
        };
      };

      dashboard = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "ダッシュボードに追加する";
        };
      };
    };
  };
in {
  # 他の module から使えるよう service 型を公開する
  options.saqula.services = mkOption {
    type = types.attrsOf (types.submodule serviceOpts);
    default = {};
    description = "統一された service 定義";
  };
}
