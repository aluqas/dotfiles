{
  config,
  globalVars,
  ...
}: {
  home.file.".config/spicetify".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${globalVars.checkoutDirName}/homes/saqula/platform/spicetify";

  imports = [
    ../../../modules/home/develop/alacritty
    ../../../modules/home/develop/vscode
  ];

  saqula.home.develop = {
    alacritty.enable = true;
    vscode.enable = true;
  };
}
