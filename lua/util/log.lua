-- lua/log.lua
local M = {}

-- Default log file path
M.log_file = vim.fn.stdpath("data") .. "/nvim.log"

-- Map levels to strings
M.levels = {
    DEBUG = 1,
    INFO  = 2,
    WARN  = 3,
    ERROR = 4,
}

-- Current minimum log level
M.level = M.levels.DEBUG

-- internal helper: write to file
local function write_file(msg)
    local f = io.open(M.log_file, "a")
    if not f then return end
    f:write(msg .. "\n")
    f:close()
end

-- log function
local function log(level, msg)
    if M.levels[level] < M.level then return end

    if type(msg) ~= "string" then
        msg = vim.inspect(msg)
    end

    local line = string.format(
        "[%s] [%s] %s",
        os.date("%Y-%m-%d %H:%M:%S"),
        level,
        msg
    )

    write_file(line)
end

-- public functions
function M.debug(msg) log("DEBUG", msg) end

function M.info(msg) log("INFO", msg) end

function M.warn(msg) log("WARN", msg) end

function M.error(msg) log("ERROR", msg) end

-- convenience: clear log
function M.clear()
    local f = io.open(M.log_file, "w")
    if f then f:close() end
end

-- command to open log
vim.api.nvim_create_user_command("LogShow", function()
    vim.cmd("edit " .. M.log_file)
end, {})

return M

