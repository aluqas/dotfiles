{
  config,
  lib,
  pkgs,
  globalVars,
  ...
}: let
  cfg = config.saqula.home.dev.env;
  repoRoot = "${config.home.homeDirectory}/${globalVars.checkoutDirName}";
  miseConfigPath = config.lib.file.mkOutOfStoreSymlink "${repoRoot}/modules/home/dev/env/mise";
in {
  options.saqula.home.dev.env.enable = lib.mkEnableOption "development environment tools";

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
