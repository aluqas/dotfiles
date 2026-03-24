# ユーザー管理 (NixOS only)
#
# ユーザー作成と sudo 設定。
# Darwin はユーザーの扱いが異なるため、これは NixOS 専用。
#
{
  config,
  lib,
  pkgs,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.core.users;
  inherit (saqulaLib) mkFeatureOptionsExt mkPlatformAssert wrapConfig;
in {
  options.saqula.core.users = mkFeatureOptionsExt "user management (NixOS)" {
    username = lib.mkOption {
      type = lib.types.str;
      description = "主要ユーザー名";
    };

    shell = lib.mkOption {
      type = lib.types.package;
      default = pkgs.fish;
      description = "ユーザーの shell";
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "networkmanager"
        "wheel"
      ];
      description = "ユーザーに追加する group";
    };

    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "SSH authorized keys";
    };

    passwordlessSudo = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "パスワードなし sudo を有効化する";
    };
  };

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "users";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (wrapConfig cfg {
      users = {
        mutableUsers = false;
        groups.${cfg.username} = {};
        users.${cfg.username} = {
          isNormalUser = true;
          group = cfg.username;
          inherit (cfg) extraGroups shell;
          openssh.authorizedKeys.keys = cfg.authorizedKeys;
        };
      };

      security.sudo.extraRules = lib.mkIf cfg.passwordlessSudo [
        {
          users = [cfg.username];
          commands = [
            {
              command = "ALL";
              options = ["NOPASSWD"];
            }
          ];
        }
      ];
    })
  ];
}
