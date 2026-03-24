{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.saqula.system.services.cluster;
in {
  imports = [
    # Container Environment（standalone containerd + nerdctl）
    ../container

    # K3s Stack（Kubernetes）
    ../k3s

    # その他の cluster / container tool
    ./nomad.nix
    ./incus.nix
    ./portainer.nix
  ];

  options.saqula.system.services.cluster = {
    enable = mkEnableOption "Cluster services group を有効化する";
  };

  config = mkIf cfg.enable {
    # 既定ではここですべてを有効化しない。
    # `cluster` module はコンテナのような入れ物として振る舞う。
    # host 設定側で必要な sub-module や set だけを有効化する。

    # ただし、以前の挙動を残したいなら K3s を true 既定にする余地はある。
    # とはいえ分割後は host 側に決めさせる方がきれい。
    # ひとまずは `cluster.k3s.enable` を明示的に有効化した場合に k3s module の既定へ委ねる。

    # K3s の有効化は今は `kubernetes` role / archetype 側で扱う。
    # saqula.system.services.k3s.enable = mkDefault true;

    # Nomad と Incus は既定で無効
    saqula.system.services.cluster.nomad.enable = mkDefault false;
    saqula.system.services.cluster.incus.enable = mkDefault false;
  };
}
