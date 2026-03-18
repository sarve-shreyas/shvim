-- Automatically generated packer.nvim plugin loader code

if vim.api.nvim_call_function('has', {'nvim-0.5'}) ~= 1 then
  vim.api.nvim_command('echohl WarningMsg | echom "Invalid Neovim version for packer.nvim! | echohl None"')
  return
end

vim.api.nvim_command('packadd packer.nvim')

local no_errors, error_msg = pcall(function()

_G._packer = _G._packer or {}
_G._packer.inside_compile = true

local time
local profile_info
local should_profile = false
if should_profile then
  local hrtime = vim.loop.hrtime
  profile_info = {}
  time = function(chunk, start)
    if start then
      profile_info[chunk] = hrtime()
    else
      profile_info[chunk] = (hrtime() - profile_info[chunk]) / 1e6
    end
  end
else
  time = function(chunk, start) end
end

local function save_profiles(threshold)
  local sorted_times = {}
  for chunk_name, time_taken in pairs(profile_info) do
    sorted_times[#sorted_times + 1] = {chunk_name, time_taken}
  end
  table.sort(sorted_times, function(a, b) return a[2] > b[2] end)
  local results = {}
  for i, elem in ipairs(sorted_times) do
    if not threshold or threshold and elem[2] > threshold then
      results[i] = elem[1] .. ' took ' .. elem[2] .. 'ms'
    end
  end
  if threshold then
    table.insert(results, '(Only showing plugins that took longer than ' .. threshold .. ' ms ' .. 'to load)')
  end

  _G._packer.profile_output = results
end

time([[Luarocks path setup]], true)
local package_path_str = "/Users/evendead/.cache/nvim/packer_hererocks/2.1.1765228720/share/lua/5.1/?.lua;/Users/evendead/.cache/nvim/packer_hererocks/2.1.1765228720/share/lua/5.1/?/init.lua;/Users/evendead/.cache/nvim/packer_hererocks/2.1.1765228720/lib/luarocks/rocks-5.1/?.lua;/Users/evendead/.cache/nvim/packer_hererocks/2.1.1765228720/lib/luarocks/rocks-5.1/?/init.lua"
local install_cpath_pattern = "/Users/evendead/.cache/nvim/packer_hererocks/2.1.1765228720/lib/lua/5.1/?.so"
if not string.find(package.path, package_path_str, 1, true) then
  package.path = package.path .. ';' .. package_path_str
end

if not string.find(package.cpath, install_cpath_pattern, 1, true) then
  package.cpath = package.cpath .. ';' .. install_cpath_pattern
end

time([[Luarocks path setup]], false)
time([[try_loadstring definition]], true)
local function try_loadstring(s, component, name)
  local success, result = pcall(loadstring(s), name, _G.packer_plugins[name])
  if not success then
    vim.schedule(function()
      vim.api.nvim_notify('packer.nvim: Error running ' .. component .. ' for ' .. name .. ': ' .. result, vim.log.levels.ERROR, {})
    end)
  end
  return result
end

time([[try_loadstring definition]], false)
time([[Defining packer_plugins]], true)
_G.packer_plugins = {
  LuaSnip = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/LuaSnip",
    url = "https://github.com/L3MON4D3/LuaSnip"
  },
  ["cmp-buffer"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/cmp-buffer",
    url = "https://github.com/hrsh7th/cmp-buffer"
  },
  ["cmp-nvim-lsp"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/cmp-nvim-lsp",
    url = "https://github.com/hrsh7th/cmp-nvim-lsp"
  },
  ["cmp-path"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/cmp-path",
    url = "https://github.com/hrsh7th/cmp-path"
  },
  ["conform.nvim"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/conform.nvim",
    url = "https://github.com/stevearc/conform.nvim"
  },
  ["diffview.nvim"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/diffview.nvim",
    url = "https://github.com/sindrets/diffview.nvim"
  },
  ["friendly-snippets"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/friendly-snippets",
    url = "https://github.com/rafamadriz/friendly-snippets"
  },
  ["gitgraph.nvim"] = {
    config = { "\27LJ\2\n7\0\1\5\0\3\0\0056\1\0\0'\3\1\0009\4\2\0B\1\3\1K\0\1\0\thash\21selected commit:\nprint:\0\2\a\0\3\0\0066\2\0\0'\4\1\0009\5\2\0009\6\2\1B\2\4\1K\0\1\0\thash\20selected range:\nprintð\2\1\0\5\0\16\0\0196\0\0\0'\2\1\0B\0\2\0029\0\2\0005\2\3\0005\3\4\0=\3\5\0025\3\6\0005\4\a\0=\4\b\3=\3\t\0025\3\v\0003\4\n\0=\4\f\0033\4\r\0=\4\14\3=\3\15\2B\0\2\1K\0\1\0\nhooks\27on_select_range_commit\0\21on_select_commit\1\0\2\21on_select_commit\0\27on_select_range_commit\0\0\vformat\vfields\1\6\0\0\thash\14timestamp\vauthor\16branch_name\btag\1\0\2\vfields\0\14timestamp\22%H:%M:%S %d-%m-%Y\fsymbols\1\0\2\17merge_commit\6M\vcommit\6*\1\0\4\fgit_cmd\bgit\nhooks\0\vformat\0\fsymbols\0\nsetup\rgitgraph\frequire\0" },
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/gitgraph.nvim",
    url = "https://github.com/isakbm/gitgraph.nvim"
  },
  ["gitsigns.nvim"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/gitsigns.nvim",
    url = "https://github.com/lewis6991/gitsigns.nvim"
  },
  golf = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/golf",
    url = "https://github.com/vuciv/golf"
  },
  ["indent-blankline.nvim"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/indent-blankline.nvim",
    url = "https://github.com/lukas-reineke/indent-blankline.nvim"
  },
  mNetrw = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/mNetrw",
    url = "/Users/evendead/.config/mNetrw"
  },
  ["mason-lspconfig.nvim"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/mason-lspconfig.nvim",
    url = "https://github.com/mason-org/mason-lspconfig.nvim"
  },
  ["mason.nvim"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/mason.nvim",
    url = "https://github.com/mason-org/mason.nvim"
  },
  ["neo-tree.nvim"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/neo-tree.nvim",
    url = "https://github.com/nvim-neo-tree/neo-tree.nvim"
  },
  ["nightfox.nvim"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/nightfox.nvim",
    url = "https://github.com/EdenEast/nightfox.nvim"
  },
  ["nui.nvim"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/nui.nvim",
    url = "https://github.com/MunifTanjim/nui.nvim"
  },
  ["nvim-cmp"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/nvim-cmp",
    url = "https://github.com/hrsh7th/nvim-cmp"
  },
  ["nvim-lint"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/nvim-lint",
    url = "https://github.com/mfussenegger/nvim-lint"
  },
  ["nvim-lspconfig"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/nvim-lspconfig",
    url = "https://github.com/neovim/nvim-lspconfig"
  },
  ["nvim-treesitter"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/nvim-treesitter",
    url = "https://github.com/nvim-treesitter/nvim-treesitter"
  },
  ["nvim-web-devicons"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/nvim-web-devicons",
    url = "https://github.com/nvim-tree/nvim-web-devicons"
  },
  ["oxocarbon.nvim"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/oxocarbon.nvim",
    url = "https://github.com/nyoom-engineering/oxocarbon.nvim"
  },
  ["packer.nvim"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/packer.nvim",
    url = "https://github.com/wbthomason/packer.nvim"
  },
  ["plenary.nvim"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/plenary.nvim",
    url = "https://github.com/nvim-lua/plenary.nvim"
  },
  ["telescope.nvim"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/telescope.nvim",
    url = "https://github.com/nvim-telescope/telescope.nvim"
  },
  undotree = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/undotree",
    url = "https://github.com/mbbill/undotree"
  },
  ["vim-be-good"] = {
    loaded = true,
    path = "/Users/evendead/.local/share/nvim/site/pack/packer/start/vim-be-good",
    url = "https://github.com/ThePrimeagen/vim-be-good"
  }
}

time([[Defining packer_plugins]], false)
-- Config for: gitgraph.nvim
time([[Config for gitgraph.nvim]], true)
try_loadstring("\27LJ\2\n7\0\1\5\0\3\0\0056\1\0\0'\3\1\0009\4\2\0B\1\3\1K\0\1\0\thash\21selected commit:\nprint:\0\2\a\0\3\0\0066\2\0\0'\4\1\0009\5\2\0009\6\2\1B\2\4\1K\0\1\0\thash\20selected range:\nprintð\2\1\0\5\0\16\0\0196\0\0\0'\2\1\0B\0\2\0029\0\2\0005\2\3\0005\3\4\0=\3\5\0025\3\6\0005\4\a\0=\4\b\3=\3\t\0025\3\v\0003\4\n\0=\4\f\0033\4\r\0=\4\14\3=\3\15\2B\0\2\1K\0\1\0\nhooks\27on_select_range_commit\0\21on_select_commit\1\0\2\21on_select_commit\0\27on_select_range_commit\0\0\vformat\vfields\1\6\0\0\thash\14timestamp\vauthor\16branch_name\btag\1\0\2\vfields\0\14timestamp\22%H:%M:%S %d-%m-%Y\fsymbols\1\0\2\17merge_commit\6M\vcommit\6*\1\0\4\fgit_cmd\bgit\nhooks\0\vformat\0\fsymbols\0\nsetup\rgitgraph\frequire\0", "config", "gitgraph.nvim")
time([[Config for gitgraph.nvim]], false)

_G._packer.inside_compile = false
if _G._packer.needs_bufread == true then
  vim.cmd("doautocmd BufRead")
end
_G._packer.needs_bufread = false

if should_profile then save_profiles() end

end)

if not no_errors then
  error_msg = error_msg:gsub('"', '\\"')
  vim.api.nvim_command('echohl ErrorMsg | echom "Error in packer_compiled: '..error_msg..'" | echom "Please check your config for correctness" | echohl None')
end
