-- カラースキーム。
-- いずれ自分でもやりて〜ｗ
-- vim.g.colors_name = "sakura"

return {
    "folke/tokyonight.nvim",
    "rose-pine/neovim",
    "catppuccin/nvim",
    {
        "anAcc22/sakura.nvim",
        dependencies = "rktjmp/lush.nvim",
    },
    "cocopon/iceberg.vim",

    "xiyaowong/transparent.nvim",
    {
        "f-person/auto-dark-mode.nvim",
        lazy = false,
        opts = {
            set_dark_mode = function()
                vim.opt.background = "dark"
                vim.cmd.colorscheme("rose-pine-moon")
            end,
            set_light_mode = function()
                vim.opt.background = "light"
                vim.cmd.colorscheme("rose-pine-dawn")
            end,
            update_interval = 3000,
            fallback = "dark"
        }

    }
}
