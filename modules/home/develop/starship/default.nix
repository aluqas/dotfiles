{
  config,
  lib,
  globalVars,
  ...
}: let
  cfg = config.saqula.home.develop.starship;
  repoRoot = "${config.home.homeDirectory}/${globalVars.checkoutDirName}";
  starshipConfigPath = config.lib.file.mkOutOfStoreSymlink "${repoRoot}/modules/home/develop/starship/starship.toml";
in {
  options.saqula.home.develop.starship.enable = lib.mkEnableOption "starship prompt configuration";

  config = lib.mkIf cfg.enable {
    programs.starship.enable = true;
    home.file.".config/starship.toml".source = starshipConfigPath;
  };
}
