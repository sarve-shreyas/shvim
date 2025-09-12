local builtin = require("telescope.builtin")
local telescope = require("telescope")
local remap = require("util.remaps")

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

remap.nomap("<leader>pf", function()
    builtin.find_files({ hidden = true })
end, { desc = "Telescope find files" })

remap.nomap("<leader>ps", function()
    builtin.grep_string({ search = vim.fn.input(" Grep > ") })
end, { desc = "Telescope project search" })

remap.nomap("<leader>gf", builtin.git_files, { desc = "Telescope git files" })
remap.nomap("<leader>gs", builtin.git_status, { desc = "Telescope git files in status" })
remap.nomap("<leader>gb", builtin.git_branches, { desc = "Telescope git branches" })

remap.nomap("<leader>bo", "<cmd>Telescope buffers<CR>", { desc = "Find Buffers" })

remap.nomap("<leader>sf", function()
    require("telescope.builtin").lsp_document_symbols({ symbols = { "function" } })
end, { desc = "Search functions in current file", silent = true })
