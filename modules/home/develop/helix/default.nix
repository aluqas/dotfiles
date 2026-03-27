{
  config,
  lib,
  globalVars,
  ...
}: let
  cfg = config.saqula.home.develop.helix;
  repoRoot = "${config.home.homeDirectory}/${globalVars.checkoutDirName}";
  helixConfigPath = config.lib.file.mkOutOfStoreSymlink "${repoRoot}/modules/home/develop/helix/config";
in {
  options.saqula.home.develop.helix.enable = lib.mkEnableOption "helix editor configuration";

  config = lib.mkIf cfg.enable {
    programs.helix.enable = true;

    home.file.".config/helix" = {
      source = helixConfigPath;
    };
  };
}
