{
  config,
  lib,
  ...
}: let
  cfg = config.saqula.home.starship;
in {
  options.saqula.home.starship.enable = lib.mkEnableOption "starship prompt configuration" // { default = true; };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      settings = builtins.fromTOML (builtins.readFile ./starship/starship.toml);
    };
  };
}
