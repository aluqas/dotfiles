# Secrets 管理ライブラリ
#
# age secret 定義用の helper 関数を提供する。
# 使い方: import "${inputs.self}/lib/secrets.nix" { root = inputs.self; isDarwin = ...; }
#
{
  root,
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
