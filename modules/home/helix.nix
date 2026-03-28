{
  config,
  lib,
  repoRoot,
  ...
}: let
  cfg = config.saqula.home.helix;
  helixConfigPath = config.lib.file.mkOutOfStoreSymlink "${repoRoot}/modules/home/helix";
in {
  options.saqula.home.helix.enable = lib.mkEnableOption "helix editor configuration" // {default = true;};

  config = lib.mkIf cfg.enable {
    programs.helix = {
      enable = true;
    };

    home.file.".config/helix".source = helixConfigPath;
  };
}
