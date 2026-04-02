# このファイルは、どの鍵で各 secret を復号できるかを定義する
# agenix / ragenix の secret 管理に使う
let
  keys = (import ../lib/secrets.nix {}).keys;

  # secret を復号できるようにする鍵の一覧
  allKeys = [keys.age.saqula];
in {
  "gpg-secret-subkeys.age".publicKeys = allKeys;
  "gpg-ownertrust.age".publicKeys = allKeys;

  # SSH Keys（Tailscale-first 戦略）
  # - git: GitHub / GitLab 認証用
  # - emergency: パスフレーズ保護の fallback
  "id_ed25519_git.age".publicKeys = allKeys;
  "id_ed25519_general_ssh.age".publicKeys = allKeys;
  "id_ed25519_emergency.age".publicKeys = allKeys;

  # 旧来のもの（移行後に削除予定）
  "id_ed25519.age".publicKeys = allKeys;

  # SSH config
  "config.age".publicKeys = allKeys;

  # Cachix
  "cachix-token.age".publicKeys = allKeys;

  # Tailscale（自動ログイン用の再利用可能な auth key）
  # 生成先: https://login.tailscale.com/admin/settings/keys
  "tailscale-auth-key.age".publicKeys = allKeys;
  "tailscale-oauth-client-secret.age".publicKeys = allKeys;

  # Komodo Container Management
  "komodo-env.age".publicKeys = allKeys;
}
