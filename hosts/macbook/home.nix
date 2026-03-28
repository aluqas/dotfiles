{ ... }:
{
  imports = [
    ../../modules/home/alacritty.nix
    ../../modules/home/fonts.nix
    ../../modules/home/vscode.nix
    ../../modules/home/spicetify.nix
  ];

  saqula.home.alacritty.enable = true;
  saqula.home.fonts.enable = true;
  saqula.home.vscode.enable = true;
  saqula.home.spicetify.enable = true;
}
