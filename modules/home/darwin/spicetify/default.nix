{
  config,
  lib,
  globalVars,
  ...
}: let
  cfg = config.saqula.home.darwin.spicetify;
  repoRoot = "${config.home.homeDirectory}/${globalVars.checkoutDirName}";
in {
  options.saqula.home.darwin.spicetify.enable = lib.mkEnableOption "spicetify configuration";

  config = lib.mkIf cfg.enable {
    home.file.".config/spicetify".source =
      config.lib.file.mkOutOfStoreSymlink "${repoRoot}/modules/home/darwin/spicetify/config";
  };
}
