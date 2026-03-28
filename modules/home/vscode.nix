{
  config,
  lib,
  pkgs,
  repoRoot,
  ...
}: let
  cfg = config.saqula.home.vscode;

  vscodeSettingsPath = config.lib.file.mkOutOfStoreSymlink "${repoRoot}/modules/home/vscode/settings.json";
  vscodeKeybindingsPath = config.lib.file.mkOutOfStoreSymlink "${repoRoot}/modules/home/vscode/keybindings.json";

  vscodeEditors = {
    cursor = {
      linux = "Cursor";
      darwin = "Cursor";
    };
    windsurf = {
      linux = "Windsurf";
      darwin = "Windsurf";
    };
    windsurf-next = {
      linux = "Windsurf - Next";
      darwin = "Windsurf - Next";
    };
    antigravity = {
      linux = "Antigravity";
      darwin = "Antigravity";
    };
  };

  linuxConfigs = builtins.listToAttrs (
    lib.concatMap (
      name: let
        dir = vscodeEditors.${name}.linux;
      in [
        {
          name = "${dir}/User/settings.json";
          value.source = vscodeSettingsPath;
        }
        {
          name = "${dir}/User/keybindings.json";
          value.source = vscodeKeybindingsPath;
        }
      ]
    ) (lib.attrNames vscodeEditors)
  );

  darwinConfigs = builtins.listToAttrs (
    lib.concatMap (
      name: let
        dir = vscodeEditors.${name}.darwin;
      in [
        {
          name = "Library/Application Support/${dir}/User/settings.json";
          value.source = vscodeSettingsPath;
        }
        {
          name = "Library/Application Support/${dir}/User/keybindings.json";
          value.source = vscodeKeybindingsPath;
        }
      ]
    ) (lib.attrNames vscodeEditors)
  );
in {
  options.saqula.home.vscode.enable = lib.mkEnableOption "VSCode/Cursor configuration";

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscodium;
    };

    xdg.configFile = lib.mkIf (!pkgs.stdenv.isDarwin) linuxConfigs;
    home.file = lib.mkIf pkgs.stdenv.isDarwin darwinConfigs;
  };
}
