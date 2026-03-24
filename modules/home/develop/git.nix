{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.saqula.home.develop.git;
in {
  options.saqula.home.develop.git.enable = lib.mkEnableOption "git configuration";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      git
      gh
      ghq
      onefetch
      lazygit
    ];

    home.file = {
      ".config/git".source = "${inputs.self}/dotfiles/config/git";
      ".config/gh".source = "${inputs.self}/dotfiles/config/gh";
    };
  };
}
