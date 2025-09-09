vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", "<Cmd>25Lexplore<CR>", { silent = true, desc = "Toogle File Explore" })

--- coying to system clipboard------
vim.keymap.set("n", "<leader>y", '"+y')
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("n", "<leader>Y", '"+Y')

-- Buffers
vim.keymap.set("n", "<leader>bd", ":bd<CR>", { silent = true, desc = "Close buffer" })
vim.keymap.set("n", "<leader>x", ":bd!<CR>", { silent = true, desc = "Force Close buffer" })

--- Switching buffers
vim.keymap.set("n", "<Tab>", ":bnext<CR>", { silent = true, desc = "Next buffer" })
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>", { silent = true, desc = "Prev buffer" })
vim.keymap.set("n", "<leader>`", ":b#<CR>", { silent = true, desc = "Switch to last buffer" })

-- Spit panes
vim.keymap.set("n", "<leader>wq", "<C-w>q", { silent = true, desc = "Close current window" })
vim.keymap.set("n", "<leader>sv", ":vsplit<CR>", { silent = true, desc = "Open vertical split window" })
vim.keymap.set("n", "<leader>sh", ":split<CR>", { silent = true, desc = "Open horizontal split window" })
vim.keymap.set("n", "<leader>wh", "<C-w><C-h>", { silent = true, desc = "Switch to window left" })
vim.keymap.set("n", "<leader>wk", "<C-w><C-k>", { silent = true, desc = "Switch to window up" })
vim.keymap.set("n", "<leader>wj", "<C-w><C-j>", { silent = true, desc = "Switch to window down" })
vim.keymap.set("n", "<leader>wl", "<C-w><C-l>", { silent = true, desc = "Switch to left right" })

--- Reloading Nvim
function ReloadConfig()
	for name, _ in pairs(package.loaded) do
		if name:match("^shr") then -- change `user` to your top-level config namespace
			package.loaded[name] = nil
			print(name)
		end
	end
	dofile(vim.env.MYVIMRC)
	print("Config reloaded!")
end

vim.keymap.set("n", "<leader>r", ReloadConfig, { desc = "Reload config" })

vim.keymap.set("n", "@", function()
	require("telescope.builtin").lsp_document_symbols({ symbols = { "function" } })
end, { desc = "Search functions in current file", silent = true })

--- Forcing to use hjkl
vim.keymap.set({ "n", "v" }, "<Up>", '<cmd>echo "Use k"<CR>', { noremap = true })
vim.keymap.set({ "n", "v" }, "<Down>", '<cmd>echo "Use j"<CR>', { noremap = true })
vim.keymap.set({ "n", "v" }, "<Left>", '<cmd>echo "Use h"<CR>', { noremap = true })
vim.keymap.set({ "n", "v" }, "<Right>", '<cmd>echo "Use l"<CR>', { noremap = true })

-- Terminal Remapping
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { noremap = true }) -- switch to normal when hit esc
vim.keymap.set("n", "<leader>t", function()
	vim.cmd("tabnew") -- create a new tab
	vim.cmd("terminal") -- open terminal inside it
end, { desc = "Open terminal in new tab" })
