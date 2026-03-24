return {
    "folke/snacks.nvim",
    lazy = false,
    priority = 9800,

    opts = {
        picker = {
            enabled = true,
            sort = { fields = { "sort" } },
            sources = {
                explorer = {
                    finder = "explorer",
                    hidden = false,
                    layout = {
                        preset = "sidebar",
                        preview = true,
                        width = 80,
                        min_width = 70,
                        position = "left",
                    },
                }
            }
        },

        -- ファイルエクスプローラー
        explorer = {
            enabled = true,
            replace_netrw = true,
        },

        -- 禅
        zen = {
            enabled = true,
            width = 140,
        },

        scroll = { enabled = true, },
        indent = { enabled = true, },
        layout = { enabled = true, },

        bigfile = { enabled = true },
        quickfile = { enabled = true },
        terminal = { enabled = true, },
    },
}
