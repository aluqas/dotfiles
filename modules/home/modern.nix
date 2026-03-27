{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.modern;
in {
  options.saqula.home.modern.enable = lib.mkEnableOption "modern CLI tools";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      eza
      lsd
      bat
      fd
      ripgrep
      sd
      dust
      duf
      broot
      uutils-coreutils
      zoxide
      fzf
      skim
      hexyl
      jless
      delta
      tokei
      hyperfine
      bottom
      procs
      bandwhich
      choose
      grex
      tealdeer
      navi
    ];
  };
}
