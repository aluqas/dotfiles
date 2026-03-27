{
  config,
  lib,
  repoRoot,
  ...
}: let
  cfg = config.saqula.home.terminal.starship;
  starshipConfigPath = config.lib.file.mkOutOfStoreSymlink "${repoRoot}/modules/home/terminal/starship/starship.toml";
in {
  options.saqula.home.terminal.starship.enable = lib.mkEnableOption "starship prompt configuration";

  config = lib.mkIf cfg.enable {
    programs.starship.enable = true;
    home.file.".config/starship.toml".source = starshipConfigPath;
  };
}
