require("nvim-treesitter.configs").setup({
    ignore_install = {},
    parser_install_dir = nil,
    modules = {},
    ensure_installed = {
        "c",
        "lua",
        "vim",
        "vimdoc",
        "query",
        "markdown",
        "markdown_inline",
        "javascript",
    },
    sync_install = false,
    auto_install = true,
    indent = { enable = true },
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
    },
})

