{
  config,
  lib,
  pkgs,
  inputs,
  hostVars,
  globalVars,
  ...
}: let
  cfg = config.saqula.darwin.base;
  inherit (lib) escapeShellArg mkEnableOption mkIf;
  primaryUser = escapeShellArg hostVars.username;
  secrets = import "${inputs.self}/lib/secrets.nix" {
    root = inputs.self;
    isDarwin = true;
    inherit (hostVars) username;
  };
  sshDir = secrets.sshDir;
  knownHosts = "${sshDir}/known_hosts";
in {
  options.saqula.darwin.base.enable = mkEnableOption "Darwin base configuration";

  config = mkIf cfg.enable {
    nixpkgs = {
      overlays = import "${inputs.self}/lib/overlays.nix" {inherit inputs;};
      config.allowUnfree = true;
    };

    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        max-jobs = "auto";
        cores = 0;
        substituters = [
          "https://cache.nixos.org"
          "https://devenv.cachix.org"
          "https://nix-community.cachix.org"
          "https://saqula.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "saqula.cachix.org-1:T7cC4Onq+zysXxk63/TeWtFVyIXaOn1U15OFInppG7w="
        ];
        keep-outputs = true;
        keep-derivations = true;
        sandbox = true;
        builders-use-substitutes = true;
      };

      gc = {
        automatic = true;
        options = "--delete-older-than 7d";
        interval = {
          Weekday = 0;
          Hour = 2;
          Minute = 0;
        };
      };

      optimise = {
        automatic = true;
        inherit (config.nix.gc) interval;
      };
    };

    environment.variables = {
      RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
      SCCACHE_DIR = "$HOME/.cache/sccache";
      LIBRARY_PATH = "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib";
      NH_FLAKE = "/Users/${hostVars.username}/${globalVars.checkoutDirName}";
    };

    environment.systemPackages = with pkgs; [
      cachix
      sccache
    ];

    environment.shells = [pkgs.fish];
    users.users.${hostVars.username}.shell = pkgs.fish;

    programs.fish.enable = true;
    programs.nix-index-database.comma.enable = true;

    security.pam.services.sudo_local = {
      # sudo の認証で Touch ID を使えるようにする
      touchIdAuth = true;
      # tmux 内でも sudo が正しく動くように bootstrap session へ再接続する
      reattach = true;
    };

    system = {
      configurationRevision = null;
      startup.chime = false;
      stateVersion = globalVars.stateVersions.darwin;
      primaryUser = hostVars.username;

      activationScripts.postActivation.text = ''
        run_as_primary_user() {
          /bin/launchctl asuser "$(/usr/bin/id -u -- ${primaryUser})" \
            /usr/bin/sudo --user=${primaryUser} -- "$@"
        }

        # Spotlight のインデックス作成自体を止める
        # /usr/bin/mdutil -a -i off || true
        # 既存の Spotlight インデックスも削除して痕跡を残さない
        # /usr/bin/mdutil -a -E || true

        # currentHost にぶら下がるプライバシー関連設定を固定する
        run_as_primary_user /usr/bin/defaults -currentHost write com.apple.AdLib forceLimitAdTracking -int 1
        run_as_primary_user /usr/bin/defaults -currentHost write com.apple.AdLib allowApplePersonalizedAdvertising -int 0
        run_as_primary_user /usr/bin/defaults -currentHost write com.apple.AdLib allowIdentifierForAdvertising -int 0

        # Apple Intelligence の opt-in 状態を ByHost 側でも無効化する
        run_as_primary_user /usr/bin/defaults -currentHost write com.apple.CloudSubscriptionFeatures.optIn "545129924" -bool false
        run_as_primary_user /usr/bin/defaults -currentHost write com.apple.CloudSubscriptionFeatures.optIn "1341174415" -bool false
        run_as_primary_user /usr/bin/defaults -currentHost write com.apple.CloudSubscriptionFeatures.optIn "device" -bool false
        run_as_primary_user /usr/bin/defaults -currentHost write com.apple.CloudSubscriptionFeatures.optIn "auto_opt_in" -bool false
        run_as_primary_user /usr/bin/defaults -currentHost write com.apple.AppleIntelligenceReport reportDuration -int 0

        # Siri と Spotlight の情報共有も ByHost 側で明示的に止める
        run_as_primary_user /usr/bin/defaults -currentHost write com.apple.assistant.support "Assistant Enabled" -bool false
        run_as_primary_user /usr/bin/defaults -currentHost write com.apple.assistant.support "Search Queries Data Sharing Status" -int 2
        run_as_primary_user /usr/bin/defaults -currentHost write com.apple.Siri StatusMenuVisible -bool false

        # Safari のユニバーサル検索経由で検索内容を送らない
        run_as_primary_user /usr/bin/defaults write com.apple.Safari UniversalSearchEnabled -bool false || true

        # クラッシュダイアログと自動更新系の ByHost 設定も固定する
        run_as_primary_user /usr/bin/defaults -currentHost write com.apple.CrashReporter DialogType -string none
        run_as_primary_user /usr/bin/defaults -currentHost write com.apple.SoftwareUpdate AutomaticCheckEnabled -int 1
        run_as_primary_user /usr/bin/defaults -currentHost write com.apple.SoftwareUpdate AutomaticallyInstallAppUpdates -int 1
        run_as_primary_user /usr/bin/defaults -currentHost write com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -int 1
        run_as_primary_user /usr/bin/defaults -currentHost write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1
      '';
    };

    system.defaults = {
      NSGlobalDomain = {
        # キー入力まわり
        "com.apple.trackpad.scaling" = 3.0; # トラッキング速度を速める
        InitialKeyRepeat = 15; # キー長押しからリピート開始までを短くする
        KeyRepeat = 2; # キーリピート速度を速める
        ApplePressAndHoldEnabled = false; # キー長押しでアクセントメニューを出すのをやめる
        "com.apple.keyboard.fnState" = true; # F1, F2 などを標準のファンクションキーとして使う
        "com.apple.swipescrolldirection" = true; # ナチュラルスクロールを使う
        "com.apple.trackpad.forceClick" = true; # Force Click を有効にしておく

        "com.apple.springing.enabled" = true;
        # "com.apple.springing.delay" = 0.0; # ホバーした瞬間にフォルダが開く

        # ウィンドウと見た目
        NSWindowResizeTime = 0.001; # ウィンドウのリサイズ速度を高速化
        NSScrollAnimationEnabled = true; # スクロールアニメーションは有効のまま使う
        AppleInterfaceStyleSwitchesAutomatically = true; # ライト/ダークを自動で切り替える

        # Finder と保存ダイアログ
        AppleShowAllExtensions = true; # すべての拡張子を表示する
        AppleShowAllFiles = true; # 隠しファイルも含めて表示する
        NSDocumentSaveNewDocumentsToCloud = false; # 新規保存先は iCloud ではなくローカルを優先する

        # 入力まわり
        NSAutomaticPeriodSubstitutionEnabled = false; # スペース2回でピリオドを入力する機能を無効化
        NSAutomaticCapitalizationEnabled = false; # 文頭を勝手に大文字にする機能をオフ
        NSAutomaticSpellingCorrectionEnabled = false; # 勝手にスペル修正する機能をオフ

        # デスクトップ操作
        AppleSpacesSwitchOnActivate = false; # アプリ切り替え時に Space を勝手に移動しない

        # サウンド
        "com.apple.sound.beep.volume" = 0.40; # 警告音量は控えめに保つ
      };

      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true; # macOS の自動更新を有効にする

      dock = {
        autohide = true; # Auto-hide the Dock to free up screen space.
        autohide-delay = 0.0; # Remove the pause before the Dock starts to appear.
        autohide-time-modifier = 0.6; # Use a slightly faster Dock show and hide animation.

        magnification = true; # 拡大有効
        tilesize = 20; # ドックアイコンのサイズ
        largesize = 72; # 拡大時のドックアイコンのサイズ

        show-process-indicators = true; # 起動中アプリをインジケーターに表示
        show-recents = false; # 最近使ったアプリを非表示
        launchanim = false; # アプリ起動時のアニメーションを無効化
        mineffect = "scale"; # ウィンドウを閉じるときのエフェクトをスケールに設定
        orientation = "right"; # ドックの位置 left, bottom, right

        mru-spaces = false; # アプリ切り替えでスペースを移動させない
        expose-animation-duration = 0.1; # Mission Controlのアニメーションを高速化
        # wvous-tl-corner = 1; # 左上：無効
        # wvous-tr-corner = 1; # 右上：無効
        # wvous-bl-corner = 1; # 左下：無効
        # wvous-br-corner = 1; # 右下：無効
      };

      finder = {
        # Finder ウィンドウにパスバーを表示する
        ShowPathbar = true;
        # Finder ウィンドウにステータスバーを表示する
        ShowStatusBar = true;
        # Finder ウィンドウの既定表示をリスト表示にする
        FXPreferredViewStyle = "Nlsv";
        FXEnableExtensionChangeWarning = false;

        # 既定の「最近の項目」は表示が遅く、ノイズも多いので使わない
        NewWindowTarget = "Home";

        _FXShowPosixPathInTitle = true; # Finder のタイトルにフルパスを表示する
        _FXSortFoldersFirst = true; # フォルダを常にファイルより先に表示する
        FXDefaultSearchScope = "SCcf"; # Cmd + F の既定検索範囲を Mac 全体ではなく現在のフォルダにする
        QuitMenuItem = true; # Quit メニューを有効にする
        # CreateDesktop = false;
      };

      CustomUserPreferences = {
        # .DS_Store を極力まき散らさない
        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true; # ネットワーク共有（SMBなど）に作らない
          DSDontWriteUSBStores = true; # USBメモリや外部ドライブに作らない
        };

        # Apple Intelligence / Siri / Spotlight まわり
        "com.apple.AppleIntelligenceReport" = {
          reportDuration = 0; # Apple Intelligence の利用レポートを無効化する
        };
        "com.apple.assistant.support" = {
          "Assistant Enabled" = false; # Siriをオフにする
          "Search Queries Data Sharing Status" = 2; # SiriとSpotlightの検索内容をAppleへ送らない
        };
        "com.apple.Siri" = {
          StatusMenuVisible = false; # メニューバーからSiriアイコンを消す
          UserHasDeclinedEnable = true; # 初回起動時のSiriセットアップをスキップ
        };
        # Siri や音声入力のオーディオ録音データを Apple と共有しない（2 = オプトアウト）
        "com.apple.SetupAssistant" = {
          SiriDataSharingOptInStatus = 2;
        };
        # "com.apple.Safari" = {
        #  UniversalSearchEnabled = false; # Safari のユニバーサル検索を無効化する
        # };

        # Spotlight はショートカットも検索カテゴリも無効化する
        "com.apple.symbolichotkeys" = {
          AppleSymbolicHotKeys = {
            "64" = {
              enabled = false;
            }; # Cmd + Space (Spotlight 検索を表示)
            "65" = {
              enabled = false;
            }; # Cmd + Option + Space (Finder の検索ウィンドウを表示)
          };
        };
        "com.apple.Spotlight" = {
          EnabledPreferenceRules = []; # Spotlightの検索カテゴリを空にする
        };

        # 解析送信・広告・クラッシュ表示を抑止する
        "com.apple.SubmitDiagInfo" = {
          AutoSubmit = false;
        };
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false; # パーソナライズ広告を無効化する
          allowIdentifierForAdvertising = false; # 広告識別子の利用を無効化する
        };
        "com.apple.applicationaccess" = {
          allowDiagnosticSubmission = false; # 診断データの送信を無効化する
        };
        "com.apple.CrashReporter" = {
          DialogType = "none"; # クラッシュレポータのダイアログを出さない
        };
      };
    };

    # 電源設定
    power = {
      sleep = {
        allowSleepByPowerButton = false; # 電源ボタンでスリープしない
        computer = 60; # 自動スリープまでの時間（分）
        display = 60; # ディスプレイの自動スリープまでの時間（分）
      };
    };

    age.identityPaths = ["/Users/${hostVars.username}/.config/age/keys.txt"];
    age.secrets.id_ed25519_git = secrets.mkSshKey "id_ed25519_git";
    age.secrets.id_ed25519_emergency = secrets.mkSshKey "id_ed25519_emergency";
    age.secrets.ssh-config = secrets.mkSshConfig "config.age";
    age.secrets.gpg-secret-subkeys = secrets.mkGpgSecret "gpg-secret-subkeys";
    age.secrets.gpg-ownertrust = secrets.mkGpgSecret "gpg-ownertrust";

    system.activationScripts.ssh-known-hosts.text = ''
      if [ ! -d "${sshDir}" ]; then
        mkdir -p "${sshDir}"
      fi

      chown "${secrets.username}" "${sshDir}"
      chmod 700 "${sshDir}"

      if [ ! -e "${knownHosts}" ]; then
        touch "${knownHosts}"
      fi

      chown "${secrets.username}" "${knownHosts}"
      chmod 600 "${knownHosts}"
    '';

    saqula.secrets.enable = true;

    nixpkgs.hostPlatform = "aarch64-darwin";
    home-manager.backupFileExtension = "backup";
  };
}
