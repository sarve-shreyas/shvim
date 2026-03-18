vim.api.nvim_create_user_command("Dvo", "DiffviewOpen", {})
vim.api.nvim_create_user_command("Dvc", "DiffviewClose", {})
vim.api.nvim_create_user_command("Dvh", "DiffviewFileHistory %", {})
vim.api.nvim_create_user_command("Dvr", "DiffviewRefresh", {})

local remap = require("util.remaps")
remap.nomap("<leader>do", "<cmd>DiffviewOpen<cr>", { desc = "Diffview open" })
remap.nomap("<leader>dc", "<cmd>DiffviewClose<cr>", { desc = "Diffview close" })
remap.nomap("<leader>dh", "<cmd>DiffviewFileHistory %<cr>", { desc = "Diffview file history" })
remap.nomap("<leader>dr", "<cmd>DiffviewRefresh<cr>", { desc = "Diffview refresh" })

