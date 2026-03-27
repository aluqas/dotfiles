{
  config,
  lib,
  repoRoot,
  ...
}:
let
  cfg = config.saqula.home.editor.neovim;
  neovimConfigPath = config.lib.file.mkOutOfStoreSymlink "${repoRoot}/modules/home/neovim/nvim-lazy";
in
{
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
