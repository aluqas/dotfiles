{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.infra.tooling;
in {
  options.saqula.home.infra.tooling.enable = lib.mkEnableOption "infrastructure tooling";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs;
      [
        kubernetes-helm
        helmfile
        kustomize
        argocd
        skopeo
        crane
        kubectl
        kubectx
        k9s
        opentofu
        pulumi
        awscli2
        azure-cli
        google-cloud-sdk
        oci-cli
        rage
        docker-compose
        dive
        lazydocker
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        podman
        podman-compose
      ];
  };
}
