{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.saqula.home.agent;
in
{
  options.saqula.home.agent.enable = lib.mkEnableOption "AI agent tools" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      codex
      claude-code
      gemini-cli

      ollama
      llama-cpp
    ];
  };
}
