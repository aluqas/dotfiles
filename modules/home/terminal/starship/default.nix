{
  config,
  lib,
  ...
}:
let
  cfg = config.saqula.home.terminal.starship;
in
{
  options.saqula.home.terminal.starship.enable = lib.mkEnableOption "starship prompt configuration";

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      settings = builtins.fromTOML (builtins.readFile ./starship.toml);
    };
  };
}
