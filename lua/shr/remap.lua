vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

--- coying to system clipboard------
vim.keymap.set("n", "<leader>y", '"+y')
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("n", "<leader>Y", '"+Y')

--- Switching buffers
vim.keymap.set("n", "<Tab>", ":bnext<CR>", { silent = true, desc = "Next buffer" })
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>", { silent = true, desc = "Prev buffer" })
vim.keymap.set("n", "<leader>bb", ":ls<CR>:b", { desc = "List & switch buffer" })
vim.keymap.set("n", "<leader>`", ":b#<CR>", { silent = true, desc = "Switch to last buffer" })

-- Spit panes
vim.keymap.set("n", "<leader>wq", "<C-w>q", { silent = true, desc = "Close current window" })
vim.keymap.set("n", "<leader>sv", ":vsplit<CR>", { silent = true, desc = "Open vertical split window" })
vim.keymap.set("n", "<leader>sh", ":split<CR>", { silent = true, desc = "Open horizontal split window" })
vim.keymap.set("n", "<leader>wh", "<C-w><C-h>", { silent = true, desc = "Switch to window left" })
vim.keymap.set("n", "<leader>wk", "<C-w><C-k>", { silent = true, desc = "Switch to window up" })
vim.keymap.set("n", "<leader>wj", "<C-w><C-j>", { silent = true, desc = "Switch to window down" })
vim.keymap.set("n", "<leader>wl", "<C-w><C-l>", { silent = true, desc = "Switch to left right" })
