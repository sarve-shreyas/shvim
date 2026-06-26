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

    -- Hide the Claude terminal window so it isn't captured in the saved layout.
    -- (claudecode.lua's ExitPre stamps the .claude_open marker + kills the job;
    -- restore reopens it with --continue.)
    pcall(vim.cmd, "ClaudeCodeClose")

    vim.cmd("silent! mksession! " .. vim.fn.fnameescape(session_file))
end

local function should_restore()
    local argc = vim.fn.argc()
    if argc == 0 then
        return true
    end
    -- Allow `nvim .` / `nvim <dir>`: a lone directory argument means "open this
    -- project", so restore its session instead of showing the netrw listing.
    if argc == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
        return true
    end
    return false
end

local function restore_session()
    if not should_restore() then
        return
    end

    local function finish()
        local _, session_file = get_session_paths()
        if vim.fn.filereadable(session_file) == 1 then
            vim.cmd("silent! source " .. vim.fn.fnameescape(session_file))
        end
    end

    if vim.fn.argc() == 1 then
        -- `nvim .`/`nvim <dir>`: defer past startup so netrw's directory handling
        -- settles (a synchronous source at VimEnter races with it and silently
        -- no-ops). cd in, source from a clean scratch buffer, then drop the
        -- leftover netrw/dir explorer buffer the argument opened.
        local dir = vim.fn.argv(0)
        vim.defer_fn(function()
            vim.cmd("cd " .. vim.fn.fnameescape(dir))
            vim.cmd("enew")
            finish()
            for _, b in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_valid(b) then
                    local nm = vim.api.nvim_buf_get_name(b)
                    local ft = vim.bo[b].filetype
                    if ft == "netrw" or ft == "neo-tree" or (nm ~= "" and vim.fn.isdirectory(nm) == 1) then
                        pcall(vim.api.nvim_buf_delete, b, { force = true })
                    end
                end
            end
        end, 100)
    else
        finish()
    end
end

vim.opt.sessionoptions = {
    "buffers",
    "curdir",
    "folds",
    "help",
    "tabpages",
    "winsize",
    -- "terminal" removed: mksession can't serialize the Claude (or shell) terminal
    -- buffer, which caused E676 on save and a dead terminal window on restore.
    -- The Claude window is reopened by claudecode.lua via a marker instead.
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

-- Write the current buffer only if it's a real, named file buffer; skip
-- terminal/nofile buffers (Claude usage float, Claude terminal, etc.) which
-- can't be written and would raise E382.
local function safe_write_current()
    if vim.bo.buftype == "" and vim.fn.expand("%") ~= "" then
        pcall(vim.cmd, "write")
    end
end

vim.api.nvim_create_user_command("Wqs", function()
    safe_write_current()
    save_session()
    vim.cmd("q")
end, {})

vim.api.nvim_create_user_command("Wqas", function()
    pcall(vim.cmd, "silent! wall") -- writes all real file buffers; skips special ones
    save_session()
    vim.cmd("qa")
end, {})

vim.cmd([[
cnoreabbrev <expr> qs getcmdtype() == ':' && getcmdline() == 'qs' ? 'Qs' : 'qs'
cnoreabbrev <expr> qas getcmdtype() == ':' && getcmdline() == 'qas' ? 'Qas' : 'qas'
cnoreabbrev <expr> wqs getcmdtype() == ':' && getcmdline() == 'wqs' ? 'Wqs' : 'wqs'
cnoreabbrev <expr> wqas getcmdtype() == ':' && getcmdline() == 'wqas' ? 'Wqas' : 'wqas'
]])

