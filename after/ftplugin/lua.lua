local remap = require("util.remaps")

remap.nomap("<leader>%", "<CMD>so %<CR>", {silent = true, desc = "Sourcing lua file"})

