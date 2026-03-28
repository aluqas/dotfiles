{
  config,
  lib,
  pkgs,
  repoRoot,
  ...
}: let
  cfg = config.saqula.home.env;
  miseConfigPath = config.lib.file.mkOutOfStoreSymlink "${repoRoot}/modules/home/mise";
in {
  options.saqula.home.env.enable = lib.mkEnableOption "development environment tools" // {default = true;};

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.mise = {
      enable = true;
      enableFishIntegration = true;
    };

    home.packages = with pkgs; [
      devenv
      cachix
      nh
      mise
      uv
    ];

    home.file.".config/mise".source = miseConfigPath;
  };
}
