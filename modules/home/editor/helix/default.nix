{
  config,
  lib,
  repoRoot,
  ...
}: let
  cfg = config.saqula.home.editor.helix;
  helixConfigPath = config.lib.file.mkOutOfStoreSymlink "${repoRoot}/modules/home/editor/helix/config";
in {
  options.saqula.home.editor.helix.enable = lib.mkEnableOption "helix editor configuration";

  config = lib.mkIf cfg.enable {
    programs.helix.enable = true;

    home.file.".config/helix" = {
      source = helixConfigPath;
    };
  };
}
