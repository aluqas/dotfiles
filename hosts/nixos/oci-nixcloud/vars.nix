{
  hostname = "oci-nixcloud"; # 希望の hostname に置き換える。
  deployHost = "oci-nixcloud.fairy-sargas.ts.net";
  username = "saqula"; # 希望の username に置き換える。
  # authorized_keys 用のブートストラップ / 緊急用鍵。
  # ホスト起動後の通常のリモート管理は Tailscale を想定する。
  sshKey = (import ../../../lib/keys.nix {}).ssh.emergency;
  locale = "en_US.UTF-8";
  timezone = "Asia/Tokyo";

  # Disk 設定
  disks = {
    # block storage を有効にする (/dev/sdb -> /data)
    # まだ block storage が接続されていない場合は false にする
    blockStorage = {
      enable = true; # OCI で block storage が接続されたら true にする
      device = "/dev/sdb";
      mountpoint = "/data";
      # block volume 上の保存先
      paths = {
        docker = "/data/docker";
        podman = "/data/podman";
        k3s = "/data/k3s";
        apps = "/data/apps";
        backups = "/data/backups";
      };
    };
  };

  # Tailscale ネットワーク設定
  networking = {
    subnets = [
      "10.0.0.0/24"
      "169.254.169.254/32"
    ];
    acceptRoutes = true;
    advertiseExitNode = false;
    hostname = "oci-nixcloud";
  };
}
