{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.modern;
in {
  options.saqula.home.modern.enable = lib.mkEnableOption "modern CLI tools" // {default = true;};

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      eza # ls
      lsd # ls
      bat # cat
      fd # find
      ripgrep # grep
      sd # sed
      dust # du
      duf # df
      broot # tree
      uutils-coreutils # coreutils
      zoxide # cd
      fzf # fuzzy finder
      skim # fuzzy finder
      hexyl # hex editor
      jless # json viewer
      delta # git diff
      tokei # code statistics
      hyperfine # benchmarking
      bottom # system monitor
      procs # process viewer
      bandwhich # network monitor
      choose # interactive selector
      grex # regex generator
      tealdeer # cheat sheet
      navi # interactive cheatsheet
    ];
  };
}
