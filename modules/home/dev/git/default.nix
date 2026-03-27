{
  config,
  lib,
  pkgs,
  repoRoot,
  ...
}: let
  cfg = config.saqula.home.dev.git;
  gitConfigPath = config.lib.file.mkOutOfStoreSymlink "${repoRoot}/modules/home/dev/git/config";
  ghConfigPath = config.lib.file.mkOutOfStoreSymlink "${repoRoot}/modules/home/dev/git/gh/config.yml";
in {
  options.saqula.home.dev.git.enable = lib.mkEnableOption "git configuration";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      git
      gh
      ghq
      onefetch
      lazygit
    ];

    home.file = {
      ".config/git".source = gitConfigPath;
      ".config/gh/config.yml".source = ghConfigPath;
    };

    home.activation.ghConfigMigration = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
      gh_dir="$HOME/.config/gh"

      if [ -L "$gh_dir" ]; then
        rm -f "$gh_dir"
      fi

      if [ ! -d "$gh_dir" ]; then
        mkdir -p "$gh_dir"
      fi
    '';
  };
}
