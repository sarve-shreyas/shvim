local remap = require("util.remaps")
local function openSplitWindow()
    vim.cmd("botright 15split")
    local wimwod = vim.api.nvim_get_current_win()
    return wimwod
end

local DEFAULT_TERMINAL_STATE = {
    win = nil,
    buf = nil,
    open = false,
    state_loaded = false
}
local function loadStateToGlobal(terminalState)
    if _G.terminalState == nil then
        _G.terminalState = terminalState
    elseif not _G.terminalState.state_loaded then
        _G.terminalState = terminalState
        _G.terminalState.state_loaded = true
    end
end
local function loadStateFromGlobal()
    if _G.terminalState == nil then
        return DEFAULT_TERMINAL_STATE
    elseif not _G.terminalState.state_loaded then
        return DEFAULT_TERMINAL_STATE
    end
    return _G.terminalState
end

local function updatateTerminalState(terminalState)
    _G.terminalState = terminalState
end

local function openNewTerminalBuffer(win)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(win, buf)
    local shell = vim.env.SHELL or "sh"
    vim.fn.termopen({ shell })
    return buf
end

local function init()
    --- Load state to global variable
    loadStateToGlobal(DEFAULT_TERMINAL_STATE)
    --- Load state from global to local variable
    return loadStateFromGlobal()

end
local function toggleTerminal()
    local terminalState = init()
    if terminalState.open then
        vim.api.nvim_win_hide(terminalState.win)
        terminalState.win = DEFAULT_TERMINAL_STATE.win
        terminalState.open = false
    else
        terminalState.win = openSplitWindow()
        terminalState.open = true
    end
    updatateTerminalState(terminalState)

    if terminalState.buf == nil then
        terminalState.buf = openNewTerminalBuffer(terminalState.win)
        updatateTerminalState(terminalState)
    end
    if terminalState.open then
        vim.api.nvim_win_set_buf(terminalState.win, terminalState.buf)
    end
end

vim.api.nvim_create_user_command("ToggleTerminal", toggleTerminal, {})
remap.nomap("<C-t>", "<CMD>ToggleTerminal<CR>", {desc = "Toggle Bottom Terminal", silent = false})

