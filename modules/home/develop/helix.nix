{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.saqula.home.develop.helix;
in {
  options.saqula.home.develop.helix.enable = lib.mkEnableOption "helix editor configuration";

  config = lib.mkIf cfg.enable {
    programs.helix.enable = true;

    home.file.".config/helix" = {
      source = "${inputs.self}/dotfiles/config/helix";
      recursive = true;
    };
  };
}
