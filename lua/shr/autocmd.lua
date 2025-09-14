local evendead_group_autocmd = vim.api.nvim_create_augroup("envedeadGroup", { clear = true })
local _M = {
    newLineOnSave = {
        yaml = false,
        yml = false,
        lua = true
    }
}
-- disable line numbering in terminal mode
vim.api.nvim_create_autocmd("TermOpen", {
    callback = function()
        vim.opt_local.relativenumber = false
        vim.opt_local.number = false
        vim.cmd("startinsert!")
    end,
    group = evendead_group_autocmd,
})

-- start insert mode when moving to a terminal window
vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
    callback = function()
        if vim.bo.buftype == "terminal" then
            vim.opt_local.relativenumber = false
            vim.opt_local.number = false
        end
    end,
    group = evendead_group_autocmd,
})

-- open new terminal in split window rather than refering to same buffer
vim.api.nvim_create_autocmd("WinNew", {
    nested = true,
    callback = function()
        local prev_buf = vim.fn.winbufnr(vim.fn.winnr("#"))
        if vim.api.nvim_get_option_value("buftype", { buf = prev_buf }) == "terminal" then
            vim.cmd("terminal")
        end
    end,
})

-- When file is saved should always add new line to end of the file
vim.api.nvim_create_autocmd("BufWritePre", {
    group = evendead_group_autocmd,
    pattern = { "*" },
    callback = function()
        local filetype = vim.bo.filetype
        if _M.newLineOnSave[filetype] == false then
            return
        end
        local n_lines = vim.api.nvim_buf_line_count(0)
        local last_nonblank = vim.fn.prevnonblank(n_lines)
        if last_nonblank <= n_lines then
            vim.api.nvim_buf_set_lines(0, last_nonblank, n_lines, true, { '' })
        end
    end,
})

-- setup foling using treesitter
vim.api.nvim_create_autocmd("FileType", {
    pattern = "json",
    group = evendead_group_autocmd,
    callback = function()
        vim.opt_local.foldmethod = "expr"
        vim.opt_local.foldexpr = "nvim_treesitter#foldexpr()"
        vim.opt_local.foldlevel = 99
    end,
})

