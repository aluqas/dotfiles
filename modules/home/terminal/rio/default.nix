{
  config,
  lib,
  pkgs,
  repoRoot,
  ...
}: let
  cfg = config.saqula.home.terminal.rio;
  rioConfigPath = config.lib.file.mkOutOfStoreSymlink "${repoRoot}/modules/home/terminal/rio/config";
in {
  options.saqula.home.terminal.rio.enable = lib.mkEnableOption "rio terminal configuration";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.rio];

    home.file.".config/rio".source = rioConfigPath;
  };
}
