{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.saqula.home.reversing;
in
{
  options.saqula.home.reversing.enable = lib.mkEnableOption "reversing tools" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      ghidra

      # 
      # wireshark
      # tshark
    ];
  };
}
