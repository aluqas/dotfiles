{
  config,
  lib,
}:
let
  cfg = config.saqula.home.proton-pass-cli;
in
{
  options.saqula.home.proton-pass-cli.enable = lib.mkEnableOption "Proton Pass CLI configuration";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs;
      [
        proton-pass-cli
      ]
  };
}
