{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.agent.agent;
in {
  options.saqula.home.agent.agent.enable = lib.mkEnableOption "AI agent tools";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      codex
      claude-code
      gemini-cli
    ];
  };
}
