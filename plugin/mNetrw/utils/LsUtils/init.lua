-- utils/LsUtils/init.lua
local pathTypes = require("utils.LsUtils.pathTypes")
local fns = require("utils.LsUtils.filelisting")
---@class enums
---@field pathTypes pathType

---@class LsUtils
---@field enums enums
---@field fn  UtilityFn

---@type LsUtils
local M = {
    enums = {
        pathTypes = pathTypes
    },
    fn = fns
}

return M

