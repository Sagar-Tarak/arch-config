-- ==============================================================================
-- Forge — lazy.nvim + LazyVim setup
-- ==============================================================================

require("lazy").setup({
    spec = {
        -- LazyVim base distribution
        {
            "LazyVim/LazyVim",
            import = "lazyvim.plugins",
        },
        -- User plugins (add your own in lua/plugins/)
        { import = "plugins" },
    },
    defaults = {
        lazy = false,
        version = false,
    },
    install = {
        colorscheme = { "catppuccin", "habamax" },
    },
    checker = {
        enabled = true,
        notify  = false,
    },
    performance = {
        rtp = {
            disabled_plugins = {
                "gzip",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
            },
        },
    },
    ui = {
        border = "rounded",
        backdrop = 60,
    },
})
