--- Remap utils

local M = {}

-- Generic keymap wrapper
--- @param modes string|string[]  Mode(s) like "n", "i", "v", or {"n", "v"}
--- @param lhs string             Left-hand side (keys to map)
--- @param rhs string|function    Right-hand side (command or Lua function)
--- @param opts table|nil         Options table (e.g. { desc = "help", silent = true })
local map = function(modes, lhs, rhs, opts)
	opts = opts or {}
	vim.keymap.set(modes, lhs, rhs, opts)
end
M.map = map

-- Set Keymapping in Normal Mode
--- @param lhs string             Left-hand side (keys to map)
--- @param rhs string|function    Right-hand side (command or Lua function)
--- @param opts table|nil         Options table (e.g. { desc = "help", silent = true })
local nomap = function(lhs, rhs, opts)
	map("n", lhs, rhs, opts)
end
M.nomap = nomap

-- Set Keymapping in Visual Mode
--- @param lhs string             Left-hand side (keys to map)
--- @param rhs string|function    Right-hand side (command or Lua function)
--- @param opts table|nil         Options table (e.g. { desc = "help", silent = true })
local vimap = function(lhs, rhs, opts)
	map("v", lhs, rhs, opts)
end
M.vimap = vimap

-- Set Keymapping in Insert Mode
--- @param lhs string             Left-hand side (keys to map)
--- @param rhs string|function    Right-hand side (command or Lua function)
--- @param opts table|nil         Options table (e.g. { desc = "help", silent = true })
local inmap = function(lhs, rhs, opts)
	map("i", lhs, rhs, opts)
end
M.inmap = inmap

-- Set Keymapping in Terminal Mode
--- @param lhs string             Left-hand side (keys to map)
--- @param rhs string|function    Right-hand side (command or Lua function)
--- @param opts table|nil         Options table (e.g. { desc = "help", silent = true })
local temap = function(lhs, rhs, opts)
	map("i", lhs, rhs, opts)
end
M.temap = temap
return M
