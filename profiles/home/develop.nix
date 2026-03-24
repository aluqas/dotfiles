{...}: {
  imports = [
    ../../modules/home/agent/agent.nix
    ../../modules/home/agent/mcp.nix
    ../../modules/home/develop/env.nix
    ../../modules/home/cli/build.nix
    ../../modules/home/develop/git.nix
    ../../modules/home/cli/media.nix
    ../../modules/home/cli/modern.nix
    ../../modules/home/cli/observability.nix
    ../../modules/home/cli/system.nix
    ../../modules/home/develop/helix.nix
    ../../modules/home/develop/neovim.nix
    ../../modules/home/develop/zellij.nix
    ../../modules/home/develop/tmux.nix
    ../../modules/home/security/gpg.nix
    ../../modules/home/develop/fish.nix
    ../../modules/home/develop/starship.nix
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
