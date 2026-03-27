{
  config,
  lib,
  repoRoot,
  ...
}:
let
  cfg = config.saqula.home.darwin.spicetify;
in
{
  options.saqula.home.darwin.spicetify.enable = lib.mkEnableOption "spicetify configuration";

  config = lib.mkIf cfg.enable {
    home.file.".config/spicetify".source =
      config.lib.file.mkOutOfStoreSymlink "${repoRoot}/modules/home/spicetify";
  };
}
