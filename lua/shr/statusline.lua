-- vim.o.laststatus = 3

local C = {
	fg = "#e0e0e0",
	modebg = "#0f3d0f", -- darkest green for mode
	gitbg = "#234f23", -- dark forest green
	filebg = "#2e7d32", -- medium-dark green
}

-- Setup highlights
local function set_hl()
	local set = vim.api.nvim_set_hl
	set(0, "StMode", { fg = C.fg, bg = C.modebg })
	set(0, "StGit", { fg = C.fg, bg = C.gitbg })
	set(0, "StFile", { fg = C.fg, bg = C.filebg })

	-- Separators
	set(0, "StSepModeNorm", { fg = C.modebg, bg = C.gitbg })
	set(0, "StSepGitFile", { fg = C.gitbg, bg = C.filebg })
	set(0, "StSepFileEnd", { fg = C.filebg, bg = "NONE" })
end

set_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = set_hl,
	group = vim.api.nvim_create_augroup("StatuslineHL", { clear = true }),
})

local SEP_RIGHT = " "
local SEP_LEFT = " "

-- Mode labels
local mode_map = {
	n = "NORMAL",
	i = "INSERT",
	v = "VISUAL",
	V = "V-LINE",
	[""] = "V-BLOCK", -- Ctrl+v
	R = "REPLACE",
	c = "COMMAND",
	s = "SELECT",
	t = "TERMINAL",
}

local function mode_label()
	local m = vim.fn.mode()
	return mode_map[m] or m
end

-- Git branch (same as before)
local function git_branch()
	local head = vim.b.gitsigns_head
	if head and #head > 0 then
		return head
	end
	if vim.fn.exists("*FugitiveHead") == 1 then
		local h = vim.fn.FugitiveHead()
		if h and #h > 0 then
			return h
		end
	end
	local dir = vim.fn.expand("%:p:h")
	local out = vim.fn.system({ "git", "-C", dir, "rev-parse", "--abbrev-ref", "HEAD" })
	if vim.v.shell_error == 0 then
		return (out:gsub("%s+$", ""))
	end
	return ""
end

-- Build statusline
function _G.MyStatusline()
	local branch = git_branch()
	if branch == "" then
		branch = "no-git"
	end
	local filename = "%f"

	return table.concat({
		"%#StMode#",
		" ",
		mode_label(),
		" ",
		"%#StSepModeNorm#",
		SEP_RIGHT,
		"%#StGit#",
		"  ",
		branch,
		" ",
		"%#StSepGitFile#",
		SEP_RIGHT,
		"%#StFile#",
		" ",
		filename,
		" ",
		"%#StSepFileEnd#",
		SEP_RIGHT,
		"%=",
		SEP_LEFT,
		"%#StFile#",
		" %l:%c ",
		"%#Normal#",
	})
end

vim.o.statusline = "%!v:lua.MyStatusline()"

-- Refresh when mode changes
local grp = vim.api.nvim_create_augroup("StatuslineRefresh", { clear = true })
vim.api.nvim_create_autocmd({ "ModeChanged", "BufEnter", "BufWritePost", "DirChanged", "User" }, {
	group = grp,
	pattern = "*",
	callback = function()
		vim.cmd("redrawstatus")
	end,
})

