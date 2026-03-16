local session_dir_name = ".nvim"
local session_file_name = "session.vim"

local function get_session_paths()
    local cwd = vim.fn.getcwd()
    local session_dir = cwd .. "/" .. session_dir_name
    local session_file = session_dir .. "/" .. session_file_name
    return session_dir, session_file
end

local function has_real_buffers()
    local bufs = vim.fn.getbufinfo({ buflisted = 1 })
    for _, buf in ipairs(bufs) do
        if buf.name ~= "" then
            return true
        end
    end
    return false
end

local function save_session()
    if not has_real_buffers() then
        return
    end

    local session_dir, session_file = get_session_paths()

    if vim.fn.isdirectory(session_dir) == 0 then
        vim.fn.mkdir(session_dir, "p")
    end

    vim.cmd("silent! mksession! " .. vim.fn.fnameescape(session_file))
end

local function restore_session()
    if vim.fn.argc() > 0 then
        return
    end

    local _, session_file = get_session_paths()

    if vim.fn.filereadable(session_file) == 1 then
        vim.cmd("silent! source " .. vim.fn.fnameescape(session_file))
    end
end

vim.opt.sessionoptions = {
    "buffers",
    "curdir",
    "folds",
    "help",
    "tabpages",
    "winsize",
    "terminal",
    "localoptions",
}

vim.api.nvim_create_user_command("SessionSave", save_session, {})
vim.api.nvim_create_user_command("SessionRestore", restore_session, {})

vim.api.nvim_create_autocmd("VimEnter", {
    callback = restore_session,
})

vim.api.nvim_create_user_command("Qs", function()
    save_session()
    vim.cmd("q")
end, {})

vim.api.nvim_create_user_command("Qas", function()
    save_session()
    vim.cmd("qa")
end, {})

vim.api.nvim_create_user_command("Wqs", function()
    vim.cmd("w")
    save_session()
    vim.cmd("q")
end, {})

vim.api.nvim_create_user_command("Wqas", function()
    vim.cmd("wa")
    save_session()
    vim.cmd("qa")
end, {})

vim.api.nvim_create_autocmd("VimEnter", {
    callback = restore_session,
})

vim.cmd([[
cnoreabbrev <expr> qs getcmdtype() == ':' && getcmdline() == 'qs' ? 'Qs' : 'qs'
cnoreabbrev <expr> qas getcmdtype() == ':' && getcmdline() == 'qas' ? 'Qas' : 'qas'
cnoreabbrev <expr> wqs getcmdtype() == ':' && getcmdline() == 'wqs' ? 'Wqs' : 'wqs'
cnoreabbrev <expr> wqas getcmdtype() == ':' && getcmdline() == 'wqas' ? 'Wqas' : 'wqas'
]])

