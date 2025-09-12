local ok, conform = pcall(require, "conform")
if not ok then
    return
end

conform.setup({
    formatters_by_ft = {
        javascript = { "prettierd", "prettier" },
        javascriptreact = { "prettierd", "prettier" },
        typescript = { "prettierd", "prettier" },
        typescriptreact = { "prettierd", "prettier" },
        json = { "prettierd", "prettier" },
        jsonc = { "prettierd", "prettier" },
        css = { "prettierd", "prettier" },
        html = { "prettierd", "prettier" },
        markdown = { "prettierd", "prettier" },
        yaml = { "prettierd", "prettier" },
        lua = { "stylua" },
        c = { "clang_format" },
        cpp = { "clang_format" },
    },
})

local remaps = require("util.remaps")

remaps.nomap("<leader>f", conform.format, { silent = true, desc = "Format file" })
