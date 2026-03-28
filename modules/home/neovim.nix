{
  config,
  lib,
  ...
}: let
  cfg = config.saqula.home.neovim;
in {
  options.saqula.home.neovim.enable = lib.mkEnableOption "neovim configuration" // { default = true; };

  config = lib.mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      opts = {
        number = true;
        relativenumber = true;
        shiftwidth = 2;
        tabstop = 2;
        smartindent = true;
        ignorecase = true;
        smartcase = true;
        swapfile = false;
        undofile = true;
        updatetime = 50;
      };

      plugins = {
        lualine.enable = true;
        treesitter = {
          enable = true;
          nixGrammars = true;
        };
        telescope.enable = true;
        web-devicons.enable = true;
        cmp.enable = true;
        lsp = {
          enable = true;
          servers = {
            nixd.enable = true;
            marksman.enable = true;
          };
        };
      };

      keymaps = [
        {
          key = "<leader>ff";
          action = "<cmd>Telescope find_files<CR>";
          options.desc = "Find files";
        }
        {
          key = "<leader>fg";
          action = "<cmd>Telescope live_grep<CR>";
          options.desc = "Live grep";
        }
      ];

      globals.mapleader = " ";
    };
  };
}
