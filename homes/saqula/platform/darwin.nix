{
  config,
  globalVars,
  ...
}: {
  home.file.".config/spicetify".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${globalVars.checkoutDirName}/dotfiles/config/spicetify";

  imports = [
    ../../../modules/home/develop/alacritty.nix
    ../../../modules/home/develop/vscode.nix
  ];

  saqula.home.develop = {
    alacritty.enable = true;
    vscode.enable = true;
  };
}
