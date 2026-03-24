{
  config,
  lib,
  ...
}:
let
  cfg = config.saqula.darwin.apps;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.saqula.darwin.apps.enable = mkEnableOption "Darwin GUI applications and fonts";

  config = mkIf cfg.enable {
    services.tailscale.enable = true;

    homebrew = {
      enable = true;
      onActivation = {
        cleanup = "zap";
        autoUpdate = false;
        upgrade = false;
      };

      brews = [
        "mas"

        "docker"
        "lima"
        "mole"
        "ni"
        "oci-cli"
        "podman"
        "podman-compose"
        "spicetify-cli"
      ];

      casks = [
        # ブラウザ
        "arc"
        "zen"
        "vivaldi"
        "chatgpt-atlas"

        "discord"
        "signal"
        "slack"
        "zoom"

        "anki"
        "anytype"
        "chatgpt"
        "claude"
        "codex-app"

        "notion"
        "notion-calendar"
        "notion-mail"
        "obsidian"

        "ogdesign-eagle"
        "raycast"

        # "daisydisk"
        # "altserver"
        # "appcleaner"

        "google-drive"
        "google-japanese-ime"
        "proton-drive"
        "proton-pass"
        "proton-mail"

        "jordanbaird-ice"
        "loopback"
        "middle"
        "qbittorrent"
        "spotify"

        "adobe-creative-cloud"
        "affinity"
        "arturia-software-center"
        "splice"
        "blender"
        "figma"
        # "clip-studio-paint"
        # "krita"
        "reaper"
        "virtualdj"

        "lets"
        "morisawa-desktop-manager"

        "xnconvert"
        "shutter-encoder"

        # "crossover"
        # "curseforge"
        "osu"
        "playcover-community"
        "whisky"
        "prismlauncher"
        "steam"

        "alacritty"
        "ghostty"
        "cursor"
        "jetbrains-toolbox"
        "visual-studio-code"
        "warp"
        # "wezterm"
        # "antigravity"
        # "zed"
        # "apidog"

        "charles"
        "orbstack"
        "github"
        "postman"
        "proxyman"
        "lens"
        # "rio"
        "termius"
        "tradingview"
        "wireshark-app"

        "zulu"
        "zulu@17"
        "zulu@21"
        # "temurin"
        #"temurin@17"
        # "temurin@21"
        # "temurin@8"

        "font-hackgen-nerd"
        "font-hubot-sans"
        "font-mona-sans"
        "font-plemol-jp-nf"
        "font-source-code-pro"
        "font-biz-udpgothic"
        "font-biz-udpmincho"
        "font-cica"
        "font-computer-modern"
        "font-firgenerd"
        "font-genjyuugothic"
        "font-genryumin"
        "font-genshingothic"
        "font-genyogothic"
        "font-genyomin"
        "font-hack"
        "font-m-plus-1"
        "font-m-plus-1-code"
        "font-m-plus-2"
        "font-maple-mono-nf-cn"
        "font-monaspace-nerd-font"
        "font-monaspice-nerd-font"
        "font-new-computer-modern"
        "font-noto-color-emoji"
        "font-noto-emoji"
        # "font-noto-mono"
        "font-noto-music"
        "font-noto-sans"
        "font-noto-sans-cjk-jp"
        "font-noto-sans-math"
        "font-noto-sans-mono-cjk-jp"
        "font-noto-sans-symbols"
        "font-noto-sans-symbols-2"
        "font-noto-serif"
        "font-noto-serif-cjk-jp"
        "font-times-new-roman"
        "font-times-newer-roman"
        "font-udev-gothic-nf"
      ];

      masApps = {
        # "GarageBand" = 682658836;
        # "RunCat" = 1429033973;
      };
    };
  };
}
