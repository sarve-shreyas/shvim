-- neotree config files

local nomap = require("util.remaps").nomap
local neotree = require("neo-tree")
neotree.setup({
    filesystem = {
        file = {
            enabled = true,
            leave_dirs_open = true
        },
        enable_git_status = true,
        filtered_items = {
            hide_gitignored = false
        },
    },
})

nomap("<leader>pv", "<CMD>Neotree toggle<CR>", { silent = true, desc = "Open File explorer" })
nomap("<leader>e", "<CMD>Neotree toggle<CR>", { silent = true, desc = "Open File explorer" })

