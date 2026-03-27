{...}: {
  imports = [
    ../../modules/home/develop/alacritty
    ../../modules/home/develop/vscode
    ../../modules/home/darwin/spicetify
  ];

  saqula.home.develop = {
    alacritty.enable = true;
    vscode.enable = true;
  };

  saqula.home.darwin.spicetify.enable = true;
}
