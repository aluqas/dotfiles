{
  config,
  lib,
  ...
}: let
  cfg = config.saqula.home.helix;
in {
  options.saqula.home.helix.enable = lib.mkEnableOption "helix editor configuration";

  config = lib.mkIf cfg.enable {
    programs.helix = {
      enable = true;
      settings = builtins.fromTOML (builtins.readFile ./helix/config.toml);
    };

    xdg.configFile."helix/languages.toml".text = builtins.readFile ./helix/languages.toml;
  };
}
