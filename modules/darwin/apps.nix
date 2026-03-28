{
  config,
  globalVars,
  hostVars,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.darwin.apps;
  inherit (lib) mkEnableOption mkIf;
  homeUser = hostVars.username or globalVars.defaultUser;
  darwinFontCasks = lib.attrByPath ["home-manager" "users" homeUser "saqula" "home" "fonts" "darwinBrewCasks"] [] config;
in {
  options.saqula.darwin.apps.enable = mkEnableOption "Darwin GUI applications";

  config = mkIf cfg.enable {
    services.tailscale.enable = true;

    environment.systemPackages = with pkgs; [
      # mas は Homebrew 側で不安定だったため Nix で入れる
      mas
      lima
      colima
      # mole # 対応してないっぽい！有志がflake.nix作ってはいたのでそっち対応するのか
      ni # node templateかmodulesに移す
      spicetify-cli
    ];

    homebrew = {
      enable = true;
      onActivation = {
        cleanup = "zap";
        autoUpdate = true;
        upgrade = false;
      };

      casks = darwinFontCasks ++ [
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

        "antigravity"
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

        # TODO: java runtimes convert to nixpkgs
        "zulu"
        "zulu@17"
        "zulu@21"
        # "temurin"
        #"temurin@17"
        # "temurin@21"
        # "temurin@8"
      ];

      masApps = {
        # "GarageBand" = 682658836;
        # "RunCat" = 1429033973;
      };
    };
  };
}
