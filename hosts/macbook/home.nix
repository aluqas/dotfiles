{...}: {
  imports = [
    ../../modules/home/terminal/alacritty
    ../../modules/home/editor/vscode
    ../../modules/home/darwin/spicetify
  ];

  saqula.home.terminal.alacritty.enable = true;
  saqula.home.editor.vscode.enable = true;
  saqula.home.darwin.spicetify.enable = true;
}
