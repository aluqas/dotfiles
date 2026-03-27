{
  config,
  lib,
  ...
}:
let
  cfg = config.saqula.home.editor.helix;
in
{
  options.saqula.home.editor.helix.enable = lib.mkEnableOption "helix editor configuration";

  config = lib.mkIf cfg.enable {
    programs.helix = {
      enable = true;
      settings = builtins.fromTOML (builtins.readFile ./config/config.toml);
    };

    xdg.configFile."helix/languages.toml".text = builtins.readFile ./config/languages.toml;
  };
}
