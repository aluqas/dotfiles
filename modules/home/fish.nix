{
  config,
  lib,
  ...
}: let
  cfg = config.saqula.home.fish;
in {
  options.saqula.home.fish.enable = lib.mkEnableOption "fish shell configuration" // { default = true; };

  config = lib.mkIf cfg.enable {
    programs.fish = {
      enable = true;
      shellInit = ''
        if test -d /run/current-system/sw/bin
            fish_add_path -gP /run/current-system/sw/bin
        end
        if test -d /nix/var/nix/profiles/default/bin
            fish_add_path -gP /nix/var/nix/profiles/default/bin
        end
        if test -d ~/.nix-profile/bin
            fish_add_path -gP ~/.nix-profile/bin
        end
        if test -d /opt/homebrew/bin
            fish_add_path -gP /opt/homebrew/bin
        end
        if test -d /opt/homebrew/sbin
            fish_add_path -gP /opt/homebrew/sbin
        end
        if test -e /etc/fish/nixos-env-preinit.fish
            source /etc/fish/nixos-env-preinit.fish
        end
      '';
      shellAbbrs = {
        yd = "yt-dlp";
        ydd = "yt-dlp -P ~/Downloads/Clips --cookies-from-browser vivaldi -f \"bv[ext=mp4]+ba[ext=m4a]\" --download-section";
        ls = "eza";
        ll = "eza -la";
        la = "eza -a";
        lt = "eza --tree";
        cat = "bat";
        find = "fd";
        grep = "rg";
        sed = "sd";
        du = "dust";
        df = "duf";
        ps = "procs";
        top = "btm";
        diff = "delta";
        zj = "zellij attach -c main";
        zjr = "zellij attach -c";
      };
      interactiveShellInit = ''
        set -x GPG_TTY (tty)
      '';
    };
  };
}
