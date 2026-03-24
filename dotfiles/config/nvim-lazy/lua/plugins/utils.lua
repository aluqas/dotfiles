return {
    {
        "stevearc/oil.nvim",
        lazy = true,
        opts = {}
    },
    {
        "folke/flash.nvim",
        lazy = true,
    },
    {
        "uga-rosa/ccc.nvim",
        lazy = true,
    },
    {
        'stevearc/aerial.nvim',
        lazy = true,
        opts = {},
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons"
        },
    },
    -- { "folke/edgy.nvim", event = "VeryLazy", },
    { -- ブロックのハイライト
        "shellRaining/hlchunk.nvim",
        lazy = true,
        event = { "BufReadPre", "BufNewFile" },
    },
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            preset = "helix", -- classic, modern, helix
        },
        keys = {
            {
                "<leader>?",
                function()
                    require("which-key").show({ global = false })
                end,
                desc = "Buffer Local Keymaps (which-key)",
            },
        },
    }
    -- "Bekaboo/dropbar.nvim"
    --   "wfxr/minimap.vim",

}
