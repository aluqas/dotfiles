{ ... }:
{
  imports = [
    ../../modules/home/agent/agent.nix
    ../../modules/home/agent/mcp.nix
    ../../modules/home/env.nix
    ../../modules/home/build.nix
    ../../modules/home/git.nix
    ../../modules/home/media.nix
    ../../modules/home/modern.nix
    ../../modules/home/observability.nix
    ../../modules/home/system.nix
    ../../modules/home/helix.nix
    ../../modules/home/neovim.nix
    ../../modules/home/zellij.nix
    ../../modules/home/tmux.nix
    ../../modules/home/gpg.nix
    ../../modules/home/fish.nix
    ../../modules/home/starship.nix
  ];

  # Enable all imported modules
  saqula.home = {
    fish.enable = true;
    tmux.enable = true;
    zellij.enable = true;
    starship.enable = true;

    neovim.enable = true;
    helix.enable = true;

    git.enable = true;
    env.enable = true;

    build.enable = true;
    modern.enable = true;
    observability.enable = true;
    system.enable = true;
    media.enable = true;

    agent.enable = true;
    mcp.enable = true;
    gpg.enable = true;
  };
}
