{
  hostname = "macbook";
  username = "saqula";
  # ブートストラップ用 / 緊急用の鍵だけを置く。
  # 日常のリモートアクセスは従来の SSH key login ではなく Tailscale を想定する。
  sshKey = (import ../../../lib/secrets.nix {}).keys.ssh.general;
  timezone = "Asia/Tokyo";
}
