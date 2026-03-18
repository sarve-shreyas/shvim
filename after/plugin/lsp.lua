-- after/plugin/lsp.lua
local lspconfig = require("lspconfig")

local remaps = require("util.remaps")
local project_config = require("util.project_config")

local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if ok_cmp then
    capabilities = cmp_lsp.default_capabilities(capabilities)
end
local function apply_eslint_indent(client, bufnr)
    if client.name ~= "eslint" then
        return
    end

    client.request("eslint/configuration", {
        items = {
            {
                scopeUri = vim.uri_from_bufnr(bufnr),
            },
        },
    }, function(err, result)
        if err or not result or not result[1] then
            return
        end

        local rules = result[1].rules or {}
        local indent = rules.indent
        if not indent then
            return
        end

        local style = indent[2]

        -- default
        local width = 2
        local expand = true

        if style == "tab" then
            expand = false
            width = vim.o.tabstop
        elseif type(style) == "number" then
            width = style
        end

        vim.bo[bufnr].expandtab = expand
        vim.bo[bufnr].tabstop = width
        vim.bo[bufnr].shiftwidth = width
        vim.bo[bufnr].softtabstop = width
    end)
end

local on_attach = function(client, bufnr)
    local nmap = function(keys, func, desc)
        if desc then
            desc = "LSP: " .. desc
        end
        remaps.nomap(keys, func, { buffer = bufnr, desc = desc })
    end
    nmap("K", vim.lsp.buf.hover, "Hover docs")
    nmap("gd", vim.lsp.buf.definition, "Goto definition")
    nmap("gD", vim.lsp.buf.declaration, "Goto declaration")
    nmap("gr", vim.lsp.buf.references, "Goto references")
    nmap("gi", vim.lsp.buf.implementation, "Goto implementation")
    nmap("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    nmap("<leader>ca", vim.lsp.buf.code_action, "Code action")
    nmap("gf", vim.diagnostic.setloclist, "Open current buffer diagnostic in location list")

    nmap("[d", function()
        vim.diagnostic.jump({ count = -1, float = true })
    end, "Prev diagnostic")

    nmap("]d", function()
        vim.diagnostic.jump({ count = 1, float = true })
    end, "Next diagnostic")

    nmap("<leader>f", function()
        vim.lsp.buf.format({ async = true })
    end, "Format buffer")

    nmap("<leader>@", function()
        require("telescope.builtin").lsp_document_symbols({ symbols = { "function" } })
    end, "List all function in file")

    if client.name == "tsserver" then
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
    end

    if client.name == "eslint" then
        apply_eslint_indent(client, bufnr)
    end

    if client.name == "ts_ls" then
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
    end
end

-- ========================
-- LSP SERVER CONFIGS
-- ========================

-- C / C++ via clangd
lspconfig.clangd.setup({
    on_attach = on_attach,
    capabilities = capabilities,
})

-- Lua (Neovim config / plugins)
lspconfig.lua_ls.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
        Lua = {
            runtime = {
                version = "LuaJIT",
            },
            diagnostics = {
                globals = { "vim" },
            },
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
            },
            telemetry = { enable = false },
        },
    },
})

-- Typescript / Javascript
-- Detect Deno vs Node to avoid double servers
local util = require("lspconfig.util")
local is_deno = function(root)
    return util.path.exists(util.path.join(root, "deno.json")) or util.path.exists(util.path.join(root, "deno.jsonc"))
end

lspconfig.ts_ls.setup({
    capabilities = capabilities,
    on_attach = on_attach,
    root_dir = function(fname)
        local root = util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git")(fname)
        if root and not is_deno(root) then
            return root
        end
    end,
    single_file_support = false,
})

local eslint_root = util.root_pattern(
    "eslint.config.js",
    "eslint.config.mjs",
    "eslint.config.cjs",
    ".eslintrc",
    ".eslintrc.js",
    ".eslintrc.cjs",
    ".eslintrc.json",
    "package.json"
)

local function has_eslint_config(root)
    if not root then return false end

    local config_files = {
        "eslint.config.js",
        "eslint.config.mjs",
        "eslint.config.cjs",
        ".eslintrc",
        ".eslintrc.js",
        ".eslintrc.cjs",
        ".eslintrc.json",
        ".eslintrc.yaml",
        ".eslintrc.yml",
    }

    for _, f in ipairs(config_files) do
        if util.path.exists(util.path.join(root, f)) then
            return true
        end
    end

    local pkg = util.path.join(root, "package.json")
    if util.path.exists(pkg) then
        local ok, lines = pcall(vim.fn.readfile, pkg)
        if ok then
            local ok_json, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
            if ok_json and type(decoded) == "table" and decoded.eslintConfig ~= nil then
                return true
            end
        end
    end
    return false
end

lspconfig.eslint.setup({
    capabilities = capabilities,
    on_attach = on_attach,
    cmd_env = {
        ESLINT_USE_FLAT_CONFIG = "false",
    },
    root_dir = function(fname)
        local root = eslint_root(fname)
        if root and has_eslint_config(root) then
            return root
        end
        return nil
    end,

    settings = {
        nodePath = "/opt/homebrew/lib/node_modules",
        workingDirectory = { mode = "auto" },
    },
    handlers = {
        ["workspace/diagnostic/refresh"] = function() end,
        ["eslint/noConfig"] = function() end,
    },
})

lspconfig.jsonls.setup({
    capabilities = capabilities,
    on_attach = on_attach,
})

lspconfig.pyright.setup({
    capabilities = capabilities,
    on_attach = on_attach,
})

