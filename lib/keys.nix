# 鍵管理の一元化
#
# システム全体で使う公開鍵をまとめる。
# 参照先: hosts/*/vars.nix, secrets/secrets.nix
#
# 使い方: import ./lib/keys.nix { root = inputs.self; }
#
{root ? ../.}: {
  # SSH 公開鍵（authorized_keys 用）
  # - git: GitHub / GitLab 認証用
  # - emergency: パスフレーズ保護の fallback（Tailscale が落ちているとき）
  ssh = {
    git = builtins.readFile "${root}/secrets/public-keys/ssh-public-key-git.pub";
    emergency = builtins.readFile "${root}/secrets/public-keys/id_ed25519_emergency.pub";

    # 旧来の鍵（deprecated、削除予定）
    general = builtins.readFile "${root}/secrets/public-keys/id_ed25519_general_ssh.pub";
  };

  # Age 公開鍵（secret 暗号化用）
  age = {
    # ユーザー鍵（個人マシン用）
    saqula = "age12mpljzktkj8yf5jzt2fk5e0jykna7z0998tlkrr9yaxqhlwmxyaqzkqwwv";

    # host 鍵（host ごとに生成し、作成次第追加する）
    # oci-nixcloud = "age1...";
  };

  # GPG 公開鍵
  gpg = builtins.readFile "${root}/secrets/public-keys/gpg-public-key.asc";
}
