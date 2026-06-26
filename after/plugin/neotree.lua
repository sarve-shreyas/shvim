-- neotree config files

local nomap = require("util.remaps").nomap
local neotree = require("neo-tree")
neotree.setup({
    filesystem = {
        -- Don't let neo-tree take over `nvim .`/`nvim <dir>`; that broke session
        -- restore. Open the tree on demand with <leader>e / <leader>pv instead.
        hijack_netrw_behavior = "disabled",
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

