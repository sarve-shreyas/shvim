-- after/ftplugin/netrw.lua
--
local rempas = require("util.remaps")

local opts = { buffer = 0,  silent = true , remap = true}

-- Tab -> go inside directory
-- Shift -> go up the directory
rempas.nomap("<Tab>", "<CR>", opts)
rempas.nomap("<S-Tab>", "-", opts)

local function setup_netrw_lock(bufnr)
  local root = vim.fn.getcwd()

  vim.keymap.set("n", "-", function()
    local current_dir = vim.fn.expand("%:p") -- netrw buffer path
    -- normalize both paths
    current_dir = vim.fn.fnamemodify(current_dir, ":p")
    local root_norm = vim.fn.fnamemodify(root, ":p")

    if current_dir == root_norm then
      vim.notify("Already at root: " .. root, vim.log.levels.WARN)
      return
    end

    -- otherwise, fallback to normal behavior
    vim.cmd("normal! -")
  end, { buffer = bufnr, noremap = true, silent = true })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function(ev)
    setup_netrw_lock(ev.buf)
  end,
})

