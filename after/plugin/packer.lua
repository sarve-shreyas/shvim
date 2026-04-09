vim.api.nvim_create_user_command("PackerSetup", function()
    vim.cmd("source " .. vim.fn.stdpath("config") .. "/lua/shr/packer.lua")
    vim.cmd("PackerSync")
end, { desc = "Source packer.lua and install/sync all plugins" })
