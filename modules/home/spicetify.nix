{
  config,
  lib,
  repoRoot,
  ...
}: let
  cfg = config.saqula.home.spicetify;
in {
  options.saqula.home.spicetify.enable = lib.mkEnableOption "spicetify configuration" // {default = true;};

  config = lib.mkIf cfg.enable {
    home.file.".config/spicetify".source =
      config.lib.file.mkOutOfStoreSymlink "${repoRoot}/modules/home/spicetify";
  };
}
