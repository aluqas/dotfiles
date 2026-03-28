# Secrets / Keys 管理ライブラリ
#
# age secret 定義用の helper 関数と公開鍵データを提供する。
# root ? ./.. のデフォルトにより、引数なし ({}) で keys のみ参照可能。
#
# 使い方:
#   # モジュール内 (inputs.self を root に)
#   secrets = saqulaLib.secrets;
#   # hosts/*/vars.nix や secrets/secrets.nix から直接インポート
#   keys = (import ../lib/secrets.nix {}).keys;
#
{
  root ? ./..,
  isDarwin ? false,
  username ? "saqula",
}: let
  secretsDir = "${root}/secrets";
  homeDir =
    if isDarwin
    then "/Users/${username}"
    else "/home/${username}";
  sshDir = "${homeDir}/.ssh";
in {
  # =========================================================================
  # keys - 公開鍵データ (旧 lib/keys.nix)
  # =========================================================================
  keys = {
    # SSH 公開鍵（authorized_keys 用）
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
  };

  # =========================================================================
  # mkSecret - 汎用 secret helper
  # =========================================================================
  # 使い方:
  #   age.secrets.my-secret = secrets.mkSecret {
  #     name = "my-secret";        # Required: filename without .age
  #     path = "/dest/path";       # Optional: destination path
  #     owner = "user";            # Optional: default = username
  #     mode = "600";              # Optional: default = "600"
  #   };
  mkSecret = {
    name,
    path ? null,
    owner ? username,
    mode ? "600",
  }:
    {
      file = "${secretsDir}/${name}.age";
      inherit owner mode;
    }
    // (
      if path != null
      then {inherit path;}
      else {}
    );

  # =========================================================================
  # 専用 helper（mkSecret をベースにする）
  # =========================================================================

  # SSH key: ~/.ssh/<name>
  mkSshKey = name: {
    file = "${secretsDir}/${name}.age";
    owner = username;
    mode = "600";
    path = "${sshDir}/${name}";
  };

  # SSH config: ~/.ssh/config
  mkSshConfig = configFile: {
    file = "${secretsDir}/${configFile}";
    owner = username;
    mode = "644";
    path = "${sshDir}/config";
  };

  # GPG secret（path なし、activation 時に復号）
  mkGpgSecret = name: {
    file = "${secretsDir}/${name}.age";
    owner = username;
    mode = "600";
  };

  # =========================================================================
  # Export
  # =========================================================================
  inherit secretsDir homeDir sshDir username;
}
