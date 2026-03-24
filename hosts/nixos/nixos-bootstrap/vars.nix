# ============================================================================
# ホスト変数 - このファイルを編集する
# ============================================================================
# このテンプレートをコピーして、新しい host 用に調整する。
#
# クイックスタート:
#   1. hostname を希望の値に変える
#   2. `saqula` 以外を使うなら username を変える
#   3. sshKey の path を SSH 公開鍵に更新する
# ============================================================================
{
  # TODO: hostname を変更する
  hostname = "nixos-bootstrap";

  # TODO: username を変更する（home-*.nix のファイル名と一致させる）
  username = "saqula";

  # authorized_keys 用のブートストラップ / 緊急用鍵。
  # ホスト起動後の通常のリモート管理は Tailscale を想定する。
  # 利用可能な鍵: ssh.git, ssh.emergency, ssh.general (legacy)
  # 定義元: lib/keys.nix
  sshKey = (import ../../../lib/keys.nix {}).ssh.emergency;

  # 任意: locale / timezone を調整する
  locale = "en_US.UTF-8";
  timezone = "Asia/Tokyo";
  # platform = "aarch64-linux";

  /*
     version = {
    home = "25.05";
    nixos = "25.05";
  }
  */
}
