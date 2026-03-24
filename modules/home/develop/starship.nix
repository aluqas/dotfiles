{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.saqula.home.develop.starship;
in {
  options.saqula.home.develop.starship.enable = lib.mkEnableOption "starship prompt configuration";

  config = lib.mkIf cfg.enable {
    programs.starship.enable = true;
    home.file.".config/starship.toml".source = "${inputs.self}/dotfiles/config/starship.toml";
  };
}
