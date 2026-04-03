{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.saqula.home.security;
in
{
  options.saqula.home.security.enable = lib.mkEnableOption "security tools" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      proton-pass
      proton-pass-cli
      proton-vpn
      # proton-vpn-cli

      btop
      htop
      ghidra
    ];
  };
}
