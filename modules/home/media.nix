{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.media;
in {
  options.saqula.home.media.enable = lib.mkEnableOption "media tools";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      pandoc
      ffmpeg
      yt-dlp
    ];
  };
}
