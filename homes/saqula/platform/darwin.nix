{inputs, ...}: {
  imports = [
    ../../../modules/home/develop/alacritty.nix
    ../../../modules/home/develop/vscode.nix
  ];

  saqula.home.develop = {
    alacritty.enable = true;
    vscode.enable = true;
  };

  home = {
    file.".config/spicetify".source = "${inputs.self}/dotfiles/config/spicetify";
  };
}
