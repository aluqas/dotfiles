{
  config,
  lib,
  globalVars,
  ...
}: let
  cfg = config.saqula.home.editor.neovim;
  repoRoot = "${config.home.homeDirectory}/${globalVars.checkoutDirName}";
  neovimConfigPath = config.lib.file.mkOutOfStoreSymlink "${repoRoot}/modules/home/editor/neovim/nvim-lazy";
in {
  options.saqula.home.editor.neovim.enable = lib.mkEnableOption "neovim configuration";

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
