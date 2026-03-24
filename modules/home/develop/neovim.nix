{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.saqula.home.develop.neovim;
in {
  options.saqula.home.develop.neovim.enable = lib.mkEnableOption "neovim configuration";

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    home.sessionVariables.NVIM_APPNAME = "nvim-lazy";
    home.file.".config/nvim-lazy".source = "${inputs.self}/dotfiles/config/nvim-lazy";
  };
}
