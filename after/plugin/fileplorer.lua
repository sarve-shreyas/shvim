function _G.ReloadFilexplorer()
    for name, _ in pairs(package.loaded) do
        if name:match("^filexplorer") then
            print(name)
            package.loaded[name] = nil
        end
    end
    require("filexplorer").setup()
    print("Filexplorer reloaded")
end

vim.keymap.set("n", "<leader>rp", ReloadFilexplorer)

local fileplorer = require("filexplorer")


fileplorer.setup()
vim.keymap.set("n", "<leader>fe", "<CMD>FileExplorer<CR>", {})
vim.keymap.set("n", "<leader>ft", "<CMD>FileExplorerToggle<CR>", {})

