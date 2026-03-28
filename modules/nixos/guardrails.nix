# Guardrails (NixOS only)
#
# ポリシー遵守を強制するための assertion と warning。
# この module は宣言的な設定運用を守るためのもの。
#
{
  config,
  pkgs,
  lib,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.core.guardrails;
  inherit (saqulaLib) mkPlatformAssert;
  inherit (pkgs.stdenv) isLinux;
in {
  options.saqula.core.guardrails = {
    enable = lib.mkEnableOption "guardrails (assertions and warnings)";
    requireImpermanence = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Warn if impermanence is disabled.";
    };
  };

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "guardrails";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (lib.mkIf (cfg.enable && isLinux) {
      # =========================================================================
      # 宣言的なユーザー管理
      # =========================================================================
      users.mutableUsers = false;

      # =========================================================================
      # Assertions
      # =========================================================================
      assertions = [
        {
          assertion = !config.users.mutableUsers;
          message = "GUARDRAIL: users.mutableUsers must be false for declarative user management.";
        }
        {
          assertion = config.system.stateVersion != "";
          message = "GUARDRAIL: system.stateVersion must be explicitly set.";
        }
      ];

      # =========================================================================
      # Warnings
      # =========================================================================
      warnings =
        lib.optional (cfg.requireImpermanence && !(config.saqula.core.impermanence.enable or false))
        "GUARDRAIL: Impermanence (saqula.core.impermanence) が無効です。OS の純度を高めるため有効化を検討してください。";
    })
  ];
}
