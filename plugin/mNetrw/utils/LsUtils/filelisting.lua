local pathTypes = require("utils.LsUtils.pathtypes")

---@param path string
local function pathExists(path)
    local ok = os.execute('[ -e "' .. path .. '" ]')
    return ok == true or ok == 0
end


---@param path string
local isDirectory = function(path)
    if path ~= nil then
        assert(pathExists(path), "Path does not exist")
        local ok = os.execute('[ -d "' .. path .. '" ]')
        return ok == true or ok == 0
    end
    assert(false, "path is required to check isDirectory")
end

---@param path string
---@return boolean|nil
local isFile = function(path)
    if path ~= nil then
        assert(pathExists(path), "Path does not exist")
        local ok = os.execute('[ -f "' .. path .. '" ]')
        return ok == true or ok == 0
    end
    assert(false, "path is required to check isFile")
end

---@param path string
local getPathType = function(path)
    if path ~= nil then
        if isDirectory(path) then
            return pathTypes.directory
        elseif isFile(path) then
            return pathTypes.file
        end
    end
end


local getChildPaths = function(path)
    assert(path ~= nil, "path is required")
    assert(pathExists(path), "path does not exist")
    if isDirectory(path) then
        local result = {}
        local p = io.popen('ls -a "' .. path .. '"')
        for file in p:lines() do
            if file ~= "." and file ~= ".." and file ~= ".git" then
                table.insert(result, path .. "/" .. file)
            end
        end
        p:close()
        return result
    end
    return nil
end


---@class pathDetails
---@field pathType integer 
---@field path string
---@field filetype string | nil
---@field depthFromRoot integer
---@field childPath table<pathDetails> | nil


---@param path string
---@param depthFromRoot integer
---@return pathDetails
local function transversePath(path, depthFromRoot)
    assert(path ~= nil, "path is required")
    assert(depthFromRoot ~= nil, "depthFromRoot is require")
    local pathType = getPathType(path)
    if pathType == pathTypes.file then
        return {
            pathType = pathType,
            path = path,
            depthFromRoot = depthFromRoot
        }
    end
    ---@type pathDetails
    local dirPathDetails = {
        pathType = pathType,
        path = path,
        depthFromRoot = depthFromRoot,
        childPath = {}
    }
    local childPath = getChildPaths(path)
    if childPath == nil then
        return dirPathDetails
    end
    for _, value in ipairs(childPath) do
        table.insert(dirPathDetails.childPath, transversePath(value, depthFromRoot + 1));
    end
    return dirPathDetails
end

---@class UtilityFn
---@field transversePath fun(path: string, depthFromRoot: integer): table
---@field isDirectory fun(path: string): boolean
---@field isFile fun(path: string): boolean|nil
---@field getPathType fun(path: string) : boolean|nil
---@field getChildPaths fun(path: string) : table

---@type UtilityFn
local M = {
    transversePath = transversePath,
    isDirectory = isDirectory,
    isFile = isFile,
    getPathType = getPathType,
    getChildPaths = getChildPaths,
}

return M

