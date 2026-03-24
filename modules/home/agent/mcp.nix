{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.saqula.home.agent.mcp;

  mcpServersPath = "${inputs.self}/dotfiles/mcpservers.json";
  mcpServers =
    if builtins.pathExists mcpServersPath
    then builtins.fromJSON (builtins.readFile mcpServersPath)
    else {mcpServers = {};};

  geminiSettings = {
    context.fileName = [
      "GEMINI.md"
      "AGENTS.md"
    ];
    ide = {
      hasSeenNudge = true;
      enabled = true;
    };
    inherit (mcpServers) mcpServers;
    general.preferredEditor = "cursor";
  };

  cursorMcpConfig = {inherit (mcpServers) mcpServers;};
in {
  options.saqula.home.agent.mcp.enable = lib.mkEnableOption "MCP server configurations";

  config = lib.mkIf cfg.enable {
    home.file =
      {
        ".gemini/settings.json".text = builtins.toJSON geminiSettings;
        ".cursor/mcp.json".text = builtins.toJSON cursorMcpConfig;
      }
      // lib.optionalAttrs pkgs.stdenv.isDarwin {
        "Library/Application Support/Claude/claude_desktop_config.json".text =
          builtins.toJSON cursorMcpConfig;
      };
  };
}
