{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.git;
in {
  options.saqula.home.git.enable = lib.mkEnableOption "git configuration" // {default = true;};

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      userName = "saqula";
      userEmail = "ping@saqu.la";
      signing = {
        key = "01F88430C644881C";
        signByDefault = false;
      };
      ignores = [
        # 個人ディレクトリ
        "**/.agents"
        "**/.saqula"

        # macOS
        ".DS_Store"
        ".AppleDouble"
        ".LSOverride"
        "Icon"
        "._*"
        ".DocumentRevisions-V100"
        ".fseventsd"
        ".Spotlight-V100"
        ".TemporaryItems"
        ".Trashes"
        ".VolumeIcon.icns"
        ".com.apple.timemachine.donotpresent"
        ".AppleDB"
        ".AppleDesktop"
        "Network Trash Folder"
        "Temporary Items"
        ".apdisk"
        "**/.cursor/.agent-tools"
        "**/.claude/settings.local.json"
      ];
      extraConfig = {
        color = {
          diff = "auto";
          status = "auto";
          branch = "auto";
          interactive = "auto";
          grep = "auto";
          ui = "auto";
        };
        commit = {
          gpgSign = false;
          template = "~/.config/git/message";
        };
        tag.gpgSign = false;
        gpg = {
          format = "openpgp";
          program = "gpg";
        };
        url."git@github.com:".insteadOf = "https://github.com/";
        ghq.root = "~/Documents/02_codes";
      };
    };

    home.packages = with pkgs; [
      gh
      ghq
      onefetch
      lazygit
    ];

    xdg.configFile."gh/config.yml".text = ''
      version: 1
      git_protocol: ssh
      editor:
      prompt: enabled
      prefer_editor_prompt: disabled
      pager:
      aliases:
        co: pr checkout
      http_unix_socket:
      browser:
      color_labels: disabled
      accessible_colors: disabled
      accessible_prompter: disabled
      spinner: enabled
    '';

    xdg.configFile."git/message".text = builtins.readFile ./git/.gitmessage;
  };
}
