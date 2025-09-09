local builtin = require("telescope.builtin")
local telescope = require("telescope")

telescope.setup({
	defaults = {
		layout_config = {
			prompt_position = "top",
		},
		sorting_strategy = "ascending",
		file_ignore_patterns = { "%.git/" },
	},
	picker = {
		find_files = {
			hidden = true,
		},
	},
})

vim.keymap.set("n", "<leader>pf", function()
	builtin.find_files({ hidden = true })
end, { desc = "Telescope find files" })

vim.keymap.set("n", "<leader>ps", function()
	builtin.grep_string({ search = vim.fn.input(" Grep > ") })
end, { desc = "Telescope project search" })

vim.keymap.set("n", "<leader>gf", builtin.git_files, { desc = "Telescope git files" })
vim.keymap.set("n", "<leader>gs", builtin.git_status, { desc = "Telescope git files in status" })
vim.keymap.set("n", "<leader>gb", builtin.git_branches, { desc = "Telescope git branches" })

vim.keymap.set("n", "<leader>bo", "<cmd>Telescope buffers<CR>", { desc = "Find Buffers" })

vim.keymap.set("n", "<leader>sf", function()
	require("telescope.builtin").lsp_document_symbols({ symbols = { "function" } })
end, { desc = "Search functions in current file", silent = true })
