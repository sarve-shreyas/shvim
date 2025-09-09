-- disable line numbering in terminal mode
local vim_term = vim.api.nvim_create_augroup("vim_term", { clear = true })
vim.api.nvim_create_autocmd("TermOpen", {
	callback = function()
		vim.opt_local.relativenumber = false
		vim.opt_local.number = false
		vim.cmd("startinsert!")
	end,
	group = vim_term,
})
-- start insert mode when moving to a terminal window
vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
	callback = function()
		if vim.bo.buftype == "terminal" then
			vim.opt_local.relativenumber = false
			vim.opt_local.number = false
		end
	end,
	group = vim_term,
})
-- open new terminal in split window rather than refering to same buffer
vim.api.nvim_create_autocmd("WinNew", {
	nested = true,
	callback = function()
		-- Check if the *previous window* (the one we split from) was a terminal
		local prev_buf = vim.fn.winbufnr(vim.fn.winnr("#"))
		if vim.api.nvim_buf_get_option(prev_buf, "buftype") == "terminal" then
			-- Replace current empty buffer with a new terminal
			vim.cmd("terminal")
		end
	end,
})
