local remaps = require("util.remaps")

local map = remaps.map
local nomap = remaps.nomap
local vimap = remaps.vimap
local inmap = remaps.inmap
local temap = remaps.temap


--- coying to system clipboard------
nomap("<leader>yy", '"+y', { silent = true, desc = "Copy to selection clipboard" })
vimap("<leader>yy", '"+y', { silent = true, desc = "Copy to selection clipboard" })
nomap("<leader>YY", '"+Y', { silent = true, desc = "Copy line to clipboard" })

--- pasting from system clipboard
nomap("<leader>pp", '"+p', { silent = true, desc = "Paste from clipboard" })

-- Buffers
nomap("<leader>bd", ":bd<CR>", { silent = true, desc = "Close buffer" })
nomap("<leader>x", ":bp | bd #<CR>", { silent = true, desc = "Close buffer, keep split" })

--- Switching buffers
nomap("<C-/>", ":bnext<CR>", { silent = true, desc = "Next buffer" })
nomap("<C-\\>", ":bprevious<CR>", { silent = true, desc = "Prev buffer" })
nomap("<leader>`", ":b#<CR>", { silent = true, desc = "Switch to last buffer" })

-- Spit panes
nomap("<leader>wq", "<C-w>q", { silent = true, desc = "Close current window" })
nomap("<leader>sv", ":vsplit<CR>", { silent = true, desc = "Open vertical split window" })
nomap("<leader>sh", ":split<CR>", { silent = true, desc = "Open horizontal split window" })
nomap("<C-w><C-h>", "<C-w><C-h>", { silent = true, desc = "Switch to window left" })
nomap("<C-w><C-k>", "<C-w><C-k>", { silent = true, desc = "Switch to window up" })
nomap("<C-w><C-j>", "<C-w><C-j>", { silent = true, desc = "Switch to window down" })
nomap("<C-w><C-l>", "<C-w><C-l>", { silent = true, desc = "Switch to window right" })
nomap("<leader>w", ":x<CR>", { silent = true, desc = "Close current window"})

-- Resizing Panes (one-shot taps)
nomap("<C-w>.", "<CMD>vertical resize +5<CR>", { silent = true, desc = "Window wider" })
nomap("<C-w>,", "<CMD>vertical resize -5<CR>", { silent = true, desc = "Window narrower" })
nomap("<C-w>+", "<CMD>resize +5<CR>", { silent = true, desc = "Window taller" })
nomap("<C-w>-", "<CMD>resize -5<CR>", { silent = true, desc = "Window shorter" })

-- tmux-style resize submode: <C-w>r, then tap h/j/k/l or arrows to resize
-- repeatedly; = equalizes; q/<Esc>/any other key exits. Robust inside tmux
-- (uses plain keys, not Ctrl/Alt+arrows which tmux tends to intercept).
local function resize_mode()
    local step = 3
    local t = function(s) return vim.api.nvim_replace_termcodes(s, true, false, true) end
    local LEFT, RIGHT, UP, DOWN = t("<Left>"), t("<Right>"), t("<Up>"), t("<Down>")
    local hint = "-- RESIZE --  h/<- narrower  l/-> wider  k/up taller  j/down shorter  = equalize  q/Esc exit"
    while true do
        vim.cmd("redraw")
        vim.api.nvim_echo({ { hint, "ModeMsg" } }, false, {})
        local ok, ch = pcall(vim.fn.getcharstr)
        if not ok then
            break
        end
        if ch == "h" or ch == LEFT then
            pcall(vim.cmd, "vertical resize -" .. step)
        elseif ch == "l" or ch == RIGHT then
            pcall(vim.cmd, "vertical resize +" .. step)
        elseif ch == "k" or ch == UP then
            pcall(vim.cmd, "resize +" .. step)
        elseif ch == "j" or ch == DOWN then
            pcall(vim.cmd, "resize -" .. step)
        elseif ch == "=" then
            pcall(vim.cmd, "wincmd =")
        else
            break -- q, <Esc>, or any other key exits
        end
    end
    vim.api.nvim_echo({ { "" } }, false, {})
    vim.cmd("redraw")
end

nomap("<C-w>r", resize_mode, { silent = true, desc = "Resize mode (tmux-like)" })

-- File editing
nomap("<leader>ss", "<CMD>w<CR>", { silent = true, desc = "Save file changes" })
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
nomap("`", "<CMD>cnext<CR>", { silent = true, desc = "Next line in quickfix" })
nomap('~', "<CMD>cprevious<CR>", { silent = true, desc = "Previous line in quickfix" })

--- Location list navigations
nomap(")", "<CMD>lnext<CR>", { silent = true, desc = "Next line in location list" })
nomap("(", "<CMD>lprevious<CR>", { silent = true, desc = "Previous line in location list" })

--- Folding 
vim.keymap.set("n", "zR", "zR", { desc = "Open all folds" })
vim.keymap.set("n", "zM", "zM", { desc = "Close all folds" })
vim.keymap.set("n", "zr", "zr", { desc = "Open folds one level" })
vim.keymap.set("n", "zm", "zm", { desc = "Close folds one level" })
vim.keymap.set("n", "za", "za", { desc = "Toggle fold" })
vim.keymap.set("n", "zo", "zo", { desc = "Open fold" })
vim.keymap.set("n", "zc", "zc", { desc = "Close fold" })

