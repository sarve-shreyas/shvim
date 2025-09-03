-- after/plugin/lsp.lua
local ok, lspconfig = pcall(require, "lspconfig")
if not ok then return end


local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if ok_cmp then
    capabilities = cmp_lsp.default_capabilities(capabilities)
end


local on_attach = function(client, bufnr)
    local nmap = function(keys, func, desc)
        if desc then desc = "LSP: " .. desc end
        vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
    end

    nmap("K", vim.lsp.buf.hover, "Hover docs")
    nmap("gd", vim.lsp.buf.definition, "Goto definition")
    nmap("gD", vim.lsp.buf.declaration, "Goto declaration")
    nmap("gr", vim.lsp.buf.references, "Goto references")
    nmap("gi", vim.lsp.buf.implementation, "Goto implementation")
    nmap("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    nmap("<leader>ca", vim.lsp.buf.code_action, "Code action")
    nmap("[d", vim.diagnostic.goto_prev, "Prev diagnostic")
    nmap("]d", vim.diagnostic.goto_next, "Next diagnostic")
    nmap("<leader>f", function() vim.lsp.buf.format({ async = true }) end, "Format buffer")
    if client.name == "tsserver" then
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
    return util.path.exists(util.path.join(root, "deno.json"))
        or util.path.exists(util.path.join(root, "deno.jsonc"))
end

lspconfig.ts_ls.setup({
    capabilities = capabilities,
    on_attach = on_attach,
    root_dir = function(fname)
        local root = util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git")(fname)
        if root and not is_deno(root) then return root end
    end,
    single_file_support = false,
})

lspconfig.eslint.setup({
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    on_attach(client, bufnr)
    -- Auto-fix on save (optional)
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      command = "EslintFixAll",
    })
  end,
})

