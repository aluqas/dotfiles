# NixOS 専用の network 設定
#
# Tailscale の詳細設定と firewall 設定。
# このファイルは NixOS でのみ import する。
#
{
  config,
  lib,
  pkgs,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.core.network.tailscale;
  inherit (saqulaLib) mkPlatformAssert;

  # フラグを組み立てるロジック
  advertiseRouteFlags =
    lib.concatMap (route: [
      "--advertise-routes"
      route
    ])
    cfg.advertiseRoutes;
  hostnameFlag = lib.optional (cfg.hostname != null) "--hostname=${cfg.hostname}";
  tagsFlag = lib.optional (
    cfg.advertiseTags != []
  ) "--advertise-tags=${lib.concatStringsSep "," cfg.advertiseTags}";
  routingMode =
    if cfg.advertiseExitNode || cfg.advertiseRoutes != []
    then "server"
    else "client";
  acceptRoutesFlag =
    if cfg.acceptRoutes
    then ["--accept-routes"]
    else ["--accept-routes=false"];
in {
  options.saqula.core.network.tailscale = {
    enable = lib.mkEnableOption "Tailscale networking";
    authKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to a Tailscale auth key file.";
    };

    acceptRoutes = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Accept subnet routes advertised by other Tailscale nodes.";
    };

    advertiseExitNode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Advertise this host as a Tailscale exit node.";
    };

    advertiseRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "CIDR routes to advertise to the Tailscale network.";
    };

    advertiseTags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "ACL tags to advertise when bringing the node up.";
    };

    hostname = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Override the node hostname registered with Tailscale.";
    };

    ssh = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Tailscale SSH on this node.";
    };

    extraUpFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional flags passed to tailscale up.";
    };
  };

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "network.tailscale (NixOS)";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (lib.mkIf cfg.enable (
      lib.mkMerge [
        {
          services.tailscale = {
            useRoutingFeatures = routingMode;
            openFirewall = true;
            extraUpFlags =
              acceptRoutesFlag
              ++ (lib.optional cfg.advertiseExitNode "--advertise-exit-node")
              ++ (lib.optional cfg.ssh "--ssh")
              ++ advertiseRouteFlags
              ++ hostnameFlag
              ++ tagsFlag
              ++ cfg.extraUpFlags;
          };

          networking.firewall = {
            trustedInterfaces = ["tailscale0"];
            checkReversePath = "loose";
          };

          systemd.services.tailscaled.serviceConfig.Restart = lib.mkForce "always";

          # Tailscale persistence（impermanence 有効時）
          environment.persistence."/persist".directories = [
            "/var/lib/tailscale"
          ];
        }
        (lib.mkIf (cfg.authKeyFile != null) {
          services.tailscale.authKeyFile = cfg.authKeyFile;
        })
      ]
    ))
  ];
}
