{...}: {
  imports = [
    ../../modules/home/agent/agent.nix
    ../../modules/home/agent/mcp
    ../../modules/home/dev/env
    ../../modules/home/tools/build.nix
    ../../modules/home/dev/git
    ../../modules/home/tools/media.nix
    ../../modules/home/tools/modern.nix
    ../../modules/home/tools/observability.nix
    ../../modules/home/tools/system.nix
    ../../modules/home/editor/helix
    ../../modules/home/editor/neovim
    ../../modules/home/terminal/zellij
    ../../modules/home/terminal/tmux.nix
    ../../modules/home/security/gpg.nix
    ../../modules/home/terminal/fish
    ../../modules/home/terminal/starship
  ];

  # Enable all imported modules
  saqula.home = {
    terminal = {
      fish.enable = true;
      tmux.enable = true;
      zellij.enable = true;
      starship.enable = true;
    };
    editor = {
      neovim.enable = true;
      helix.enable = true;
    };
    dev = {
      git.enable = true;
      env.enable = true;
    };
    tools = {
      build.enable = true;
      modern.enable = true;
      observability.enable = true;
      system.enable = true;
      media.enable = true;
    };
    agent = {
      agent.enable = true;
      mcp.enable = true;
    };
    security.gpg.enable = true;
  };
}
