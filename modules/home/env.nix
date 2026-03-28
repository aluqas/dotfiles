{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.env;
in {
  options.saqula.home.env.enable = lib.mkEnableOption "development environment tools" // {default = true;};

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
