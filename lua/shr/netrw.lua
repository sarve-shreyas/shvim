--- Customizing netrw Experience
---
--- Put cursor to opened file
--- Remember

local M = {
    splitSize = 40
}

local log = require("util.log")

-- setting the listing style to 3
vim.g.netrw_liststyle = 3

--- @class netrw_state
---@field have_buffer boolean
---@field bufnr integer|nil
---@field win integer|nil
---@field launchwin integer|nil
---@field launchtab integer|nil
---@field have_lock boolean

---@type netrw_state
local netrw_default_state = {
    have_buffer = false,
    bufnr = nil,
    win = nil,
    launchwin = nil,
    launchtab = nil,
    have_lock = true
}
--- Get fresh default state of netrw
--- @return netrw_state
local get_new_state = function()
    return vim.deepcopy(netrw_default_state)
end

_G.netrw_state = get_new_state()

--- Will check if the nertw window is valid or not
--- If valid then will delete the netrw window
--- As well will reset netrw.win state to default
--- @param T netrw_state | nil
local closeWindow = function(T)
    T = T or _G.netrw_state
    if vim.api.nvim_win_is_valid(T.win) then
        vim.api.nvim_win_close(T.win, true)
    end
    T.win = netrw_default_state.win
end

--- Will check if the netrw buffer is valid or not
--- If found valid then will delete the netrw buffer
--- As well will reset netrw buffer to defaul
--- @param T netrw_state | nil
local closeBuffer = function(T)
    T = T or _G.netrw_state
    if vim.api.nvim_buf_is_valid(T.bufnr) then
        vim.api.nvim_buf_delete(T.bufnr, {})
    end
    T.bufnr = netrw_default_state.bufnr
end

--- Reset netrw state to default state
--- if @class netrw_state not passed then current netrw state is used
--- @param T netrw_state|nil
local resetNetrwState = function(T)
    T = T or _G.netrw_state
    T.have_buffer = false
    T.launchtab = nil
    T.have_lock = true
end

--- set lock to true
--- not args passed then current netrw_state is used
--- @param T netrw_state | nil
local acquireLock = function(T)
    T = T or _G.netrw_state
    T.have_lock = true
end

--- set lock to false
--- no args passed then current netrw_state is used
--- @param T netrw_state | nil
local releaseLock = function(T)
    T = T or _G.netrw_state
    T.have_lock = false
end
--- If we have netrw buffer then will closeWindow & closeBuffer
--- As well will reset the netrw state to default
--- no args passed then will use current netrw state
--- @param T netrw_state | nil
local closeBufferAndWindow = function(T)
    acquireLock()
    T = T or _G.netrw_state
    if not T.have_buffer then
        return
    end
    closeWindow(T)
    closeBuffer(T)
    resetNetrwState(T)
    releaseLock(T)
    log.info("Closed our netrw buffer & window")
end

--- Open a window for netrw buffer
--- return the windowId
--- return nil in case of errors
--- @return integer|nil
local openSplitWindow = function()
    local cmd = "topleft" .. " " .. M.splitSize .. "vsplit"
    vim.cmd(cmd)
    local win = vim.api.nvim_get_current_win()
    return win
end

--- Open a netrw buffer in given window
--- return bufferId
--- return nil in case of errors
--- @param win integer
--- @return integer|nil
local openNetrwBuffer = function(win)
    local cmd = "Ex"
    vim.api.nvim_set_current_win(win)
    vim.cmd(cmd)
    local bufnr = vim.api.nvim_get_current_buf()
    return bufnr
end

--- Open netrw window
--- Save launchwin - window from which netrw explorer launched
--- Save launchtab - tab from which netrw exploreer launched
--- open split window of size 40
--- Save win - netrw instance window
--- Save bufnr - netrw buffer
local openNetrwWindow = function()
    acquireLock()
    _G.netrw_state.have_buffer = true
    _G.netrw_state.launchwin = vim.api.nvim_get_current_win()
    _G.netrw_state.launchtab = vim.api.nvim_get_current_tabpage()
    _G.netrw_state.win = openSplitWindow()
    _G.netrw_state.bufnr = openNetrwBuffer(_G.netrw_state.win)
    log.info("Opened Netrw Window")
    releaseLock()
end

--- Toogle the netrw window state ( open / close )
local toggleNetrwExplorer = function(opts)
    if _G.netrw_state.have_buffer then
        closeBufferAndWindow()
    else
        openNetrwWindow()
    end
end

--- Move the opened buffer from netrw window to launchwin
--- Close netrw win
--- if launchwin is closed then not to close win
--- delete netrw buffer
--- reset netrw state
local moveBfnrInLaunchWindow = function()
    local cur_bfnr = vim.api.nvim_get_current_buf()
    if vim.api.nvim_win_is_valid(_G.netrw_state.launchwin) then
        vim.api.nvim_win_set_buf(_G.netrw_state.launchwin, cur_bfnr)
        closeBufferAndWindow()
    else
        closeBuffer()
    end
    resetNetrwState()
end

local netrw_group = vim.api.nvim_create_augroup("nertw_group", { clear = true })
vim.api.nvim_create_autocmd("BufWinEnter", {
    callback = function(ev)
        --- Ignore when lock is aquired cannot make changes to state
        if _G.netrw_state.have_lock then
            return
        end
        -- Ignore when we dont have any buffer to reference from
        if not _G.netrw_state.have_buffer then
            return
        end
        -- Ignore when netrw window
        if vim.bo[ev.buf].filetype == "netrw" then
            return
        end
        -- Ignore when not in same tab
        if vim.api.nvim_get_current_tabpage() ~= _G.netrw_state.launchtab then
            return
        end
        -- Check if action was done from netrw
        local prev_buf_type = vim.fn.bufname("#")
        if prev_buf_type:match("Netrw") or vim.bo[vim.fn.bufnr("#")].filetype == "netrw" then
            log.info("Moving the buffer")
            moveBfnrInLaunchWindow()
        end
    end,
    group = netrw_group
})
--- Close the opened Netrw Explorer before switching tab
vim.api.nvim_create_autocmd("TabLeave", {
    callback = function()
        if _G.netrw_state.have_buffer then
            closeBufferAndWindow()
        end
    end
})
--- User command to Open/Close Explorer
--- Will be used in keymapping
vim.api.nvim_create_user_command("ToggleNetrwExplorer",
    toggleNetrwExplorer,
    {}
)

