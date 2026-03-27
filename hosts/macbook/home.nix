{ ... }:
{
  imports = [
    ../../modules/home/alacritty.nix
    ../../modules/home/vscode.nix
    ../../modules/home/spicetify.nix
  ];

  saqula.home.terminal.alacritty.enable = true;
  saqula.home.editor.vscode.enable = true;
  saqula.home.darwin.spicetify.enable = true;
}
