local remaps = require("util.remaps")

local map = remaps.map
local nomap = remaps.nomap
local vimap = remaps.vimap
local inmap = remaps.inmap
local temap = remaps.temap

--- Open File Explorer
nomap("<leader>pv", "<CMD>ToggleNetrwExplorer<CR>", { silent = true, desc = "Open File explorer" })

--- coying to system clipboard------
nomap("<leader>y", '"+y', { silent = true, desc = "Copy to selection clipboard" })
vimap("<leader>y", '"+y', { silent = true, desc = "Copy to selection clipboard" })
nomap("<leader>Y", '"+Y', { silent = true, desc = "Copy line to clipboard" })

--- pasting from system clipboard
nomap("<leader>p", '"+p', { silent = true, desc = "Paste from clipboard" })
nomap("<leader>P", '"+P', { silent = true, desc = "Paste from clipboard" })

-- Buffers
nomap("<leader>bd", ":bd<CR>", { silent = true, desc = "Close buffer" })
nomap("<leader>x", ":bd!<CR>", { silent = true, desc = "Force Close buffer" })

--- Switching buffers
nomap("<Tab>", ":bnext<CR>", { silent = true, desc = "Next buffer" })
nomap("<S-Tab>", ":bprevious<CR>", { silent = true, desc = "Prev buffer" })
nomap("<leader>`", ":b#<CR>", { silent = true, desc = "Switch to last buffer" })

-- Spit panes
nomap("<leader>wq", "<C-w>q", { silent = true, desc = "Close current window" })
nomap("<leader>sv", ":vsplit<CR>", { silent = true, desc = "Open vertical split window" })
nomap("<leader>sh", ":split<CR>", { silent = true, desc = "Open horizontal split window" })
nomap("<C-w><C-h>", "<C-w><C-h>", { silent = true, desc = "Switch to window left" })
nomap("<C-w><C-k>", "<C-w><C-k>", { silent = true, desc = "Switch to window up" })
nomap("<C-w><C-j>", "<C-w><C-j>", { silent = true, desc = "Switch to window down" })
nomap("<C-w><C-l>", "<C-w><C-l>", { silent = true, desc = "Switch to left right" })

-- Resizing Panes
nomap("<C-w>.", "<CMD>vertical resize +5<CR>", { silent = true, desc = "Increate window width by +2" })
nomap("<C-w>,", "<CMD>vertical resize -5<CR>", { silent = true, desc = "Increate window width by +2" })
nomap("C-w>-", "<CMD>horizontal resize -5<CR>", { silent = true, desc = "Descrease window height by -2" })
nomap("C-w>+", "<CMD>horizontal resize +5<CR>", { silent = true, desc = "Increase window height by -2" })

-- File editing
nomap("<leader>s", "<CMD>w<CR>", { silent = true, desc = "Save file changes" })
map({ "n", "v" }, "<leader>aa", "<esc>ggVG", { silent = true, desc = "Select all" })

--- Reloading Nvim Configs
function ReloadConfig()
    for name, _ in pairs(package.loaded) do
        if name:match("^shr") then
            package.loaded[name] = nil
            print(name)
        end
    end
    dofile(vim.env.MYVIMRC)
    print("Config reloaded!")
end

nomap("<leader>r", ReloadConfig, { desc = "Reload config" })

--- Forcing to use hjkl
map({ "n", "v" }, "<Up>", '<cmd>echo "Use k"<CR>', { noremap = true, desc = "Disabled Arrow UP" })
map({ "n", "v" }, "<Down>", '<cmd>echo "Use j"<CR>', { noremap = true, desc = "Disabled Arrow Down" })
map({ "n", "v" }, "<Left>", '<cmd>echo "Use h"<CR>', { noremap = true, desc = "Disabled Arrow Left" })
map({ "n", "v" }, "<Right>", '<cmd>echo "Use l"<CR>', { noremap = true, desc = "Disabled Arrow Right" })

-- Terminal Remapping
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { noremap = true, desc = "Escape terminal mode to normal mode" })
local openTerminalNewTab = function()
    vim.cmd("tabnew")
    vim.cmd("terminal")
end
nomap("<C-t>", openTerminalNewTab, { desc = "Open terminal in new tab" })

--- Tab mappings
map({ "n", "v" }, "gt", "<CMD>tabnext<CR>", { silent = true, desc = "Switch to next tab", noremap = true })
map({ "n", "v" }, "gT", "<CMD>tabprevious<CR>", { silent = true, desc = "Switch to previous tab", noremap = true })
map({ "n", "v" }, "<leader>t", "<CMD>tabnew<CR>", { silent = true, desc = "Open New tab" })
map({ "n", "v", "t" }, "<C-0>", "<CMD>tabclose<CR>", { silent = true, desc = "Close current tab" })

--- Quickfix navigation
nomap("'", "<CMD>cnext<CR>", { silent = true, desc = "Next line in quickfix" })
nomap('"', "<CMD>cprevious<CR>", { silent = true, desc = "Previous line in quickfix" })

--- Location list navigations
nomap(")", "<CMD>lnext<CR>", { silent = true, desc = "Next line in location list" })
nomap("(", "<CMD>lprevious<CR>", { silent = true, desc = "Previous line in location list" })

