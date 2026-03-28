{
  config,
  lib,
  repoRoot,
  ...
}: let
  cfg = config.saqula.home.neovim;
  # neovimConfigPath = config.lib.file.mkOutOfStoreSymlink "${repoRoot}/modules/home/neovim/nvim-lazy";
in {
  options.saqula.home.neovim.enable = lib.mkEnableOption "neovim configuration" // { default = true; };

  config = lib.mkIf cfg.enable {
    imports = [
      inputs.kickstart-nixvim.darwinModules.default
    ];

    programs.nixvim.enable = true;
  }
}
