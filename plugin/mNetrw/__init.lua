local LsUtils = require("utils.LsUtils")
local pathTypes = LsUtils.enums.pathTypes


---@class DirUI
---@field pathDetails pathDetails
---@field traversed boolean
---@field open boolean
---@field pathString string
---@field childUINodes table <DirUI>
---@field dirUISize integer
local DirUI = {}
DirUI.__index = DirUI



---@param pd pathDetails
---@return DirUI
function DirUI.new(pd)
    assert(pd and pd.pathType, "pathDetails required")
    return setmetatable({
        pathDetails = pd,
        pathString = pd.path,
        traversed = false,
        open = false,
        childUINodes = {},
        dirUISize = 1
    }, DirUI)
end

function DirUI:toggle() self:setOpen(not self.open) end

function DirUI:childDirUISize()
    local size = 0
    for _, value in ipairs(self.childUINodes) do
        size = size + value.dirUISize
    end
    return size
end

function DirUI:setOpen(v)
    self.open = not not v
    if self.open then
        self.dirUISize = self:childDirUISize() + self.dirUISize
    else
        self.dirUISize = 1
    end
end

function DirUI:markTraversed() self.traversed = true end

function DirUI:updateDirUISize(size) self.dirUISize = size end

function DirUI:childrenCount(flag)
    flag = flag or false
    if flag then
        print("Child count", self.pathString)
    end
    local len = #self.childUINodes
    return len
end

function DirUI:setOpenUIOfIndex(index, flag)
    assert(type(index) == "number", "index must be an integer")
    assert(index > 0, "index is 1 based indexing")
    if self.dirUISize < index then
        print("index > dirUISize")
        return nil
    end
    if index == 1 then
        local initialSize = self.dirUISize
        self:setOpen(flag)
        local uiSizeDiff = self.dirUISize - initialSize
        return uiSizeDiff
    end
    index = index - 1
    for _, value in ipairs(self.childUINodes) do
        local nodeSize = value:childDirUISize() + 1
        if index <= nodeSize then
            local modSize = value:returnUIWithIndex(index)
            self.dirUISize = self.dirUISize + modSize
            return modSize
        end
        index = index - nodeSize
    end
    return nil
end

function DirUI:toggleUIWithIndex(index)

end

function DirUI:openUIWithIndex(index)
    assert(type(index) == "number", "index must be an integer")
    assert(index > 0, "index is 1 based indexing")
    if self.dirUISize < index then
        print("index > dirUISize")
        return nil
    end
    if index == 1 then
        self:setOpen(true)
        return self.dirUISize
    end
    index = index - 1
    for _, value in ipairs(self.childUINodes) do
        local nodeSize = value:childDirUISize() + 1
        if index <= nodeSize then
            local addedUISize = value:returnUIWithIndex(index)
            self.dirUISize = self.dirUISize + addedUISize
            return addedUISize
        end
        index = index - nodeSize
    end
    return nil
end

function DirUI:closeUIWithIndex(index)
    assert(type(index) == "number", "index must be an integer")
    assert(index > 0, "index is 1 based indexing")
    if self.dirUISize < index then
        print("index > dirUISize")
        return nil
    end
    if index == 1 then
        self:setOpen(false)
        return self.dirUISize
    end
    index = index - 1
    for _, value in ipairs(self.childUINodes) do
        local nodeSize = value:childDirUISize() + 1
        if index <= nodeSize then
            local removedSize = value:returnUIWithIndex(index)
            self.dirUISize = self.dirUISize + removedSize
            return removedSize
        end
        index = index - nodeSize
    end
    return nil
end

function DirUI:returnUIWithIndex(index)
    assert(type(index) == "number", "index must be an integer")
    assert(index > 0, "index is 1 based indexing")
    print("Running for", self.pathString, index)
    if self.dirUISize < index then
        print("index > dirUISize")
        return nil
    end
    if index == 1 then return self end

    index = index - 1
    for _, value in ipairs(self.childUINodes) do
        local nodeSize = value:childDirUISize() + 1
        if index <= nodeSize then
            return value:returnUIWithIndex(index)
        end
        index = index - nodeSize
    end
    return nil
end

function DirUI:returnUIWithPath(path)
    assert(type(path) == "string", "path must be a string")
    if self.pathString == path then
        return self
    end
    if not self.childUINodes then
        return nil
    end
    for _, child in ipairs(self.childUINodes) do
        local found = child:returnUIWithPath(path)
        if found ~= nil then
            return found
        end
    end
    return nil
end

local function dump(o, indent)
    indent = indent or 0
    if type(o) == "table" then
        local s = "{\n"
        for k, v in pairs(o) do
            s = s .. string.rep("  ", indent + 1) .. tostring(k) .. " = " .. dump(v, indent + 1) .. ",\n"
        end
        return s .. string.rep("  ", indent) .. "}"
    else
        return tostring(o)
    end
end

---@param node pathDetails
---@return DirUI
local function buildDirUIMap(node)
    local map = {}
    map = DirUI.new(node)
    local dirUISize = map.dirUISize
    if node.childPath then
        for _, child in ipairs(node.childPath) do
            local childDirUi = buildDirUIMap(child)
            table.insert(map.childUINodes, childDirUi)
            if childDirUi.open then
                dirUISize = dirUISize + childDirUi.dirUISize
            end
        end
    end
    map.dirUISize = dirUISize
    return map
end

---@class TreeSeparator
---@field tee string
---@field elbow string
---@field pipe string
---@field space string
---@field root string

---@class TreeIcons
---@field dir_open string
---@field dir_closed string
---@field file string

---@class TreeUIConfig
---@field separators TreeSeparator
---@field icons TreeIcons

local DEFAULT_TREE_UI = {
    separators = {
        tee   = "├─ ",
        elbow = "└─ ",
        pipe  = "│  ",
        space = "   ",
        root  = "",
    },
    icons = {
        dir_open   = "📂 ",
        dir_closed = "📁 ",
        file       = "📄 ",
    }
}

---@param uiCfg TreeUIConfig
---@param dirUI DirUI
---@param prefix string|nil
---@param isLast boolean|nil
local function printTree(uiCfg, dirUI, prefix, isLast)
    assert(type(uiCfg) == "table" and type(uiCfg.separators) == "table" and type(uiCfg.icons) == "table",
        "ui config with separators and icons is required")
    local sep = uiCfg.separators
    local icons = uiCfg.icons

    prefix = prefix or ""
    local namePart = dirUI.pathString:match("([^/]+)$") or dirUI.pathString

    local icon = ""
    if dirUI.pathDetails.pathType == pathTypes.directory then
        local ui = dirUI
        local isOpen = ui and ui.open
        icon = (isOpen and icons.dir_open or icons.dir_closed)
    else
        icon = icons.file
    end

    local connector = (prefix == "" and (sep.root or "")) or (isLast and sep.elbow or sep.tee)
    print(prefix .. connector .. icon .. namePart)

    local canRecurse = dirUI.pathDetails.childPath ~= nil and dirUI.pathDetails.pathType == pathTypes.directory
    if canRecurse then
        local ui = dirUI
        if ui then ui:markTraversed() end
        canRecurse = ui and ui.open
    end

    if not canRecurse then return end

    local newPrefix = prefix .. (isLast and sep.space or sep.pipe)
    local childSize = dirUI:childrenCount()
    for i, child in ipairs(dirUI.childUINodes) do
        local last = (i == childSize)
        printTree(uiCfg, child, newPrefix, last)
    end
end

-- Example:
local root = LsUtils.fn.transversePath("/Users/evendead/.config/nvim", 1)
local rootUI = buildDirUIMap(root)
-- rootUI:setOpen(true)
-- printTree(DEFAULT_TREE_UI, rootUI, "", true)
-- local line4 = rootUI:returnUIWithIndex(4)
-- if line4 ~= nil then
--     line4:setOpen(true)
-- end
-- printTree(DEFAULT_TREE_UI, rootUI, "", true)

-- local init = 1
-- local UI = rootUI
-- while UI ~= nil do
--     print("Toogling", UI.pathString)
--     UI:toggle()
--     printTree(DEFAULT_TREE_UI, rootUI, "", true)
--     print("Enter the dirIndex")
--     local index = io.read("*n")
--     UI = rootUI:returnUIWithIndex(index)
-- end
--

