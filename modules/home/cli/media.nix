{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.cli.media;
in {
  options.saqula.home.cli.media.enable = lib.mkEnableOption "media tools";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      pandoc
      ffmpeg
      yt-dlp
    ];
  };
}
