{...}: {
  imports = [
    ../../modules/home/agent/agent.nix
    ../../modules/home/agent/mcp
    ../../modules/home/develop/env
    ../../modules/home/cli/build.nix
    ../../modules/home/develop/git
    ../../modules/home/cli/media.nix
    ../../modules/home/cli/modern.nix
    ../../modules/home/cli/observability.nix
    ../../modules/home/cli/system.nix
    ../../modules/home/develop/helix
    ../../modules/home/develop/neovim
    ../../modules/home/develop/zellij
    ../../modules/home/develop/tmux.nix
    ../../modules/home/security/gpg.nix
    ../../modules/home/develop/fish.nix
    ../../modules/home/develop/starship
  ];

  # Enable all imported modules
  saqula.home = {
    develop = {
      fish.enable = true;
      git.enable = true;
      neovim.enable = true;
      helix.enable = true;
      tmux.enable = true;
      zellij.enable = true;
      starship.enable = true;
      env.enable = true;
    };
    cli = {
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
