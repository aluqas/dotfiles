# NixOS 専用の optimization 設定
#
# ccache、sccache 用の systemd tmpfiles、Cachix push service をまとめる。
# この file は NixOS でのみ import する。
#
{
  config,
  lib,
  pkgs,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.core.optimization;
  cachixCfg = config.saqula.devex.cachix;
  inherit (saqulaLib) secrets mkPlatformAssert;
  inherit (lib) mkEnableOption mkOption types;
in {
  options.saqula.core.optimization = {
    enable = lib.mkEnableOption "NixOS optimization settings";
    rust.enable = mkOption {
      type = types.bool;
      default = true;
      description = "sccache tmpfiles などの Rust 専用 optimization helper を有効化する。";
    };
  };

  # Cachix options（optimization と密結合のためここで定義）
  options.saqula.devex.cachix = {
    enable = mkEnableOption "Cachix binary cache";
    cacheName = mkOption {
      type = types.str;
      default = "saqula";
      description = "Name of the Cachix cache";
    };
    push = {
      enable = mkEnableOption "Push to Cachix";
      authTokenFile = mkOption {
        type = types.str;
        default = "";
        description = "Path to the Cachix auth token file";
      };
    };
  };

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "optimization (NixOS)";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (lib.mkIf cfg.enable {
      # =========================================================================
      # C/C++ optimization（ccache）- NixOS only
      # =========================================================================
      programs.ccache.enable = true;

      # ccache 用の extra sandbox path
      nix.settings.extra-sandbox-paths = [
        config.programs.ccache.cacheDir
      ];

      # Rust が有効なら sccache 用 tmpfiles を作る
      systemd.tmpfiles.rules = lib.mkIf config.saqula.core.optimization.rust.enable [
        "d /var/cache/sccache 0777 root root - -"
      ];
    })

    # =========================================================================
    # Cachix Push Service（NixOS only）
    # =========================================================================
    (lib.mkIf (cachixCfg.enable && cachixCfg.push.enable) {
      assertions = [
        {
          assertion = cfg.enable;
          message = "Cachix push service requires saqula.core.optimization.enable = true";
        }
      ];

      # cachix token 用の age secret を定義する
      age.secrets.cachix-token = secrets.mkSecret {
        name = "cachix-token";
        owner = "root";
        mode = "400";
      };

      # Cachix へ自動 push する
      systemd.services.cachix-watch-store = {
        description = "Cachix Store Watcher";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        environment.CACHIX_AUTH_TOKEN = "$(cat ${config.age.secrets.cachix-token.path})";
        serviceConfig = {
          ExecStart = "${pkgs.cachix}/bin/cachix watch-store ${cachixCfg.cacheName}";
          Restart = "always";
          RestartSec = "10s";
        };
        path = [pkgs.cachix];
      };
    })
  ];
}
