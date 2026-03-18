local floating = require("util.floating_window")

local state = {
    win = nil,
    buf = nil,
    mode = "commit",
}

vim.api.nvim_set_hl(0, "GitCommitPopupBorder", { fg = "#ffffff" })

local function repo_root()
    local out = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })
    if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
        return nil
    end
    return out[1]
end

local function git_dir(root)
    local out = vim.fn.systemlist({ "git", "-C", root, "rev-parse", "--git-dir" })
    if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
        return nil
    end
    if vim.fn.fnamemodify(out[1], ":p"):sub(1, 1) == "/" then
        return out[1]
    end
    return root .. "/" .. out[1]
end

local function read_file(path)
    if vim.fn.filereadable(path) == 0 then
        return {}
    end
    return vim.fn.readfile(path)
end

local function merge_msg_path(root)
    local gd = git_dir(root)
    if not gd then
        return nil
    end
    return gd .. "/MERGE_MSG"
end

local function merge_head_path(root)
    local gd = git_dir(root)
    if not gd then
        return nil
    end
    return gd .. "/MERGE_HEAD"
end

local function merge_in_progress(root)
    local path = merge_head_path(root)
    return path and vim.fn.filereadable(path) == 1
end

local function close_popup()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end
    state.win = nil
    state.buf = nil
    state.mode = "commit"
end

local function prepare_default_message()
    local root = repo_root()
    if not root then
        return { "" }
    end

    local staged_files_cmd = { "git", "-C", root, "diff", "--staged", "--name-only" }
    local staged_files = vim.fn.systemlist(staged_files_cmd)

    local lines = {
        "",
        "# Please enter the commit message for your changes. Lines starting",
        "# with '#' will be ignored, and an empty message aborts the commit.",
        "#",
    }

    if #staged_files == 0 then
        table.insert(lines, "# No staged files")
    else
        table.insert(lines, "# Changes to be committed:")
        for _, file in ipairs(staged_files) do
            table.insert(lines, "#\t" .. file)
        end
    end

    return lines
end

local function build_initial_lines(mode, root)
    if mode == "merge" then
        local lines = read_file(merge_msg_path(root))
        if #lines == 0 then
            lines = { "" }
        end
        return lines
    end
    return prepare_default_message()
end

local function current_message_lines()
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
        return nil
    end

    local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
    local message_lines = {}

    for _, line in ipairs(lines) do
        if not vim.startswith(line, "#") then
            table.insert(message_lines, line)
        end
    end

    while #message_lines > 0 and message_lines[1]:match("^%s*$") do
        table.remove(message_lines, 1)
    end

    while #message_lines > 0 and message_lines[#message_lines]:match("^%s*$") do
        table.remove(message_lines, #message_lines)
    end

    return message_lines
end

local function submit_message()
    local root = repo_root()
    if not root then
        vim.notify("Not inside a git repository", vim.log.levels.ERROR)
        return
    end

    local message_lines = current_message_lines()
    if not message_lines or #message_lines == 0 then
        vim.notify("Commit message is empty", vim.log.levels.ERROR)
        return
    end

    local tmpfile = vim.fn.tempname()
    vim.fn.writefile(message_lines, tmpfile)

    local cmd = { "git", "-C", root, "commit", "-F", tmpfile }
    local result = vim.fn.systemlist(cmd)
    local ok = vim.v.shell_error == 0

    vim.fn.delete(tmpfile)
    close_popup()

    if ok then
        vim.notify(table.concat(result, "\n"), vim.log.levels.INFO)
        vim.cmd("checktime")
    else
        vim.notify(table.concat(result, "\n"), vim.log.levels.ERROR)
    end
end

---@param instance FloatingWindowInstance
local function do_commit(instance)
    local commit_lines = instance.get_lines()
    instance.close()
    local processed_commit_message = {}
    if commit_lines then
        for _, v in ipairs(commit_lines) do
            if v == nil or v == "" then
                goto continue
            end
            if not vim.startswith(v, "#") then
                table.insert(processed_commit_message, v)
            end
            ::continue::
        end
    end
    if next(processed_commit_message) ~= nil then
        local root = repo_root()
        local tmpfile = vim.fn.tempname()
        vim.fn.writefile(processed_commit_message, tmpfile)
        local git_commit_cmd = { "git", "-C", root, "commit", "-F", tmpfile }
        local reply = vim.fn.systemlist(git_commit_cmd)
        vim.fn.delete(tmpfile)
    else
        vim.notify("Empty commit message skipping commit")
    end
end

local function open_popup(mode)
    local root = repo_root()
    if not root then
        vim.notify("Not inside a git repository", vim.log.levels.ERROR)
        return
    end

    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_set_current_win(state.win)
        return
    end

    prepare_default_message()
    local width = 0.5
    local height = 0.5

    local lines = build_initial_lines(mode, root)
    floating.open({
        title = "Git Commit",
        width = width,
        height = height,
        close_on_q = true,
        initial_lines = lines,
        relative = "editor",
        buffer_options = {
            filetype = "gitcommit",
        },
        border = "rounded",
        enter_insert = true,
        keymaps = {
            {
                mode = "n",
                lhs = "<leader>cs",
                callback = do_commit,
                desc = "Submit commit"
            },
        },
        on_exit = function(instance) end,
    })

    -- vim.keymap.set("n", "<leader>cs", submit_message, { buffer = buf, silent = true, desc = "Submit git commit" })
    -- vim.keymap.set("n", "<leader>cq", close_popup, { buffer = buf, silent = true, desc = "Close git commit popup" })
    -- vim.keymap.set("n", "q", close_popup, { buffer = buf, silent = true, desc = "Close git commit popup" })
    --
    -- vim.cmd("startinsert")
end

local function open_commit_popup()
    local root = repo_root()
    if not root then
        vim.notify("Not inside a git repository", vim.log.levels.ERROR)
        return
    end

    if merge_in_progress(root) then
        open_popup("merge")
        return
    end

    open_popup("commit")
end

local function has_upstream(root)
    vim.fn.system({ "git", "-C", root, "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}" })
    return vim.v.shell_error == 0
end

local function current_branch(root)
    local out = vim.fn.systemlist({ "git", "-C", root, "branch", "--show-current" })
    if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
        return nil
    end
    return out[1]
end

local function git_pull_popup()
    local root = repo_root()
    if not root then
        vim.notify("Not inside a git repository", vim.log.levels.ERROR)
        return
    end

    if merge_in_progress(root) then
        open_popup("merge")
        return
    end
    if has_upstream(root) then
        cmd = { "git", "-C", root, "pull", "--no-rebase", "--no-commit" }
    else
        local branch = current_branch(root)
        if not branch then
            vim.notify("Could not determine current branch", vim.log.levels.ERROR)
            return
        end
        cmd = { "git", "-C", root, "pull", "origin", branch, "--no-rebase", "--no-commit" }
    end
    local result = vim.fn.systemlist(cmd)
    local output = table.concat(result, "\n")

    if vim.v.shell_error ~= 0 then
        if merge_in_progress(root) then
            vim.notify(
                "Pull created a merge state. Resolve conflicts, then commit from the popup.",
                vim.log.levels.WARN
            )
            open_popup("merge")
            return
        end
        vim.notify(output, vim.log.levels.ERROR)
        return
    end

    if merge_in_progress(root) then
        open_popup("merge")
        return
    end

    if output == "" then
        output = "Git pull completed"
    end

    vim.notify(output, vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("GitCommitPopup", open_commit_popup, {})
vim.api.nvim_create_user_command("GitCommitClose", close_popup, {})
vim.api.nvim_create_user_command("GitPullPopup", git_pull_popup, {})

vim.keymap.set("n", "<leader>gc", open_commit_popup, { desc = "Open git commit popup" })
vim.keymap.set("n", "<leader>gpl", git_pull_popup, { desc = "Git pull and open merge popup" })

