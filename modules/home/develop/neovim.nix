{
  config,
  lib,
  globalVars,
  ...
}: let
  cfg = config.saqula.home.develop.neovim;
  repoRoot = "${config.home.homeDirectory}/${globalVars.checkoutDirName}";
  neovimConfigPath = config.lib.file.mkOutOfStoreSymlink "${repoRoot}/dotfiles/config/nvim-lazy";
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
    home.file.".config/nvim-lazy".source = neovimConfigPath;
  };
}
