{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.saqula.home.dev.env;
in
{
  options.saqula.home.dev.env.enable = lib.mkEnableOption "development environment tools";

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.mise = {
      enable = true;
      enableFishIntegration = true;
    };

    home.packages = with pkgs; [
      devenv
      cachix
      nh
      mise
      uv
    ];

    xdg.configFile."mise/config.toml".text = builtins.readFile ./mise/config.toml;
  };
}
