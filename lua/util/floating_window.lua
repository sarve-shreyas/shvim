local colorUtil = require("util.color")
---@class FloatingWindowBufferOptions
---@field bufhidden? string
---@field buftype? string
---@field swapfile? boolean
---@field modifiable? boolean
---@field readonly? boolean
---@field filetype? string

---@class FloatingWindowWindowOptions
---@field wrap? boolean
---@field cursorline? boolean
---@field number? boolean
---@field relativenumber? boolean
---@field signcolumn? string
---@field winfixwidth? boolean
---@field winfixheight? boolean
---@field winhl? string

---@class FloatingWindowKeymap
---@field mode? string|string[]
---@field lhs string
---@field rhs? string|function
---@field callback? fun(instance: FloatingWindowInstance)
---@field opts? vim.keymap.set.Opts

---@class FloatingWindowAttachedKeymap
---@field lhs string
---@field desc string
---@field mode string|string[]

---@class FloatingWindowOptions
---@field width? number
---@field height? number
---@field row? number
---@field col? number
---@field buf? integer
---@field listed? boolean
---@field enter? boolean
---@field relative? string
---@field style? string
---@field border? string|string[]
---@field title? string
---@field title_pos? string
---@field zindex? integer
---@field buffer_options? FloatingWindowBufferOptions
---@field window_options? FloatingWindowWindowOptions
---@field initial_lines? string[]
---@field keymaps? FloatingWindowKeymap[]
---@field close_on_escape? boolean
---@field close_on_q? boolean
---@field enter_insert? boolean
---@field on_enter? fun(instance: FloatingWindowInstance)
---@field on_exit? fun(instance: FloatingWindowInstance)

---@class FloatingWindowInstance
---@field id string
---@field buf integer
---@field win integer
---@field opts FloatingWindowOptions
---@field close fun()
---@field set_lines fun(lines: string[])
---@field get_lines fun(): string[]
---@field focus fun()

---@class FloatingWindowState
---@field windows table<string, FloatingWindowInstance>

local M = {}
local hints_namespace = vim.api.nvim_create_namespace("FloatingWindowHints")

---@type FloatingWindowState
local state = {
    windows = {},
}

---@generic T
---@param value T|nil
---@param fallback T
---@return T
local function default(value, fallback)
    if value == nil then
        return fallback
    end
    return value
end

---@param value number|nil
---@param total integer
---@param fallback integer
---@return integer
local function normalize_size(value, total, fallback)
    value = default(value, fallback)

    if type(value) == "number" and value > 0 and value < 1 then
        return math.max(1, math.floor(total * value))
    end

    if type(value) == "number" then
        return math.max(1, math.floor(value))
    end

    return fallback
end

---@param total integer
---@param size integer
---@param value number|nil
---@param fallback integer
---@return integer
local function calc_position(total, size, value, fallback)
    value = default(value, fallback)

    if type(value) == "number" and value >= 0 and value < 1 then
        return math.max(0, math.floor((total - size) * value))
    end

    if type(value) == "number" then
        return math.max(0, math.floor(value))
    end

    return fallback
end

---@param win integer|nil
local function close_window(win)
    if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end
end

---@param id string
local function close_by_id(id)
    local instance = state.windows[id]
    if not instance then
        return
    end

    if instance.opts and type(instance.opts.on_exit) == "function" then
        pcall(instance.opts.on_exit, instance)
    end

    close_window(instance.win)
    state.windows[id] = nil
end

---@param buf integer
---@param win integer
---@param opts FloatingWindowOptions
local function apply_local_options(buf, win, opts)
    local floatingWindowBorderColor = colorUtil.get_contrast_normal_bg()
    vim.api.nvim_set_hl(0, "MyCustomFloatBorder", {fg = floatingWindowBorderColor, bg = "NONE"})
    local buffer_options = opts.buffer_options or {}
    local window_options = opts.window_options or {}

    vim.bo[buf].bufhidden = default(buffer_options.bufhidden, "wipe")
    vim.bo[buf].buftype = default(buffer_options.buftype, "nofile")
    vim.bo[buf].swapfile = default(buffer_options.swapfile, false)
    vim.bo[buf].modifiable = default(buffer_options.modifiable, true)
    vim.bo[buf].readonly = default(buffer_options.readonly, false)
    vim.bo[buf].filetype = default(buffer_options.filetype, "")

    vim.api.nvim_set_option_value("wrap", default(window_options.wrap, false), { win = win })
    vim.api.nvim_set_option_value("cursorline", default(window_options.cursorline, false), { win = win })
    vim.api.nvim_set_option_value("number", default(window_options.number, false), { win = win })
    vim.api.nvim_set_option_value("relativenumber", default(window_options.relativenumber, false), { win = win })
    vim.api.nvim_set_option_value("signcolumn", default(window_options.signcolumn, "no"), { win = win })
    vim.api.nvim_set_option_value("winfixwidth", default(window_options.winfixwidth, false), { win = win })
    vim.api.nvim_set_option_value("winfixheight", default(window_options.winfixheight, false), { win = win })

    if window_options.winhl then
        vim.api.nvim_set_option_value("winhl", window_options.winhl, { win = win })
    else
        vim.api.nvim_set_option_value("winhl", "Normal:NormalFloat,FloatBorder:MyCustomFloatBorder", {win = win})
    end
end

---@param buf integer
---@param lines string[]|nil
local function set_buffer_lines(buf, lines)
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines or {})
    if vim.bo[buf].readonly then
        vim.bo[buf].modifiable = false
    end
end

---@param keymaps FloatingWindowAttachedKeymap[]
---@return string?
local function build_keymap_hint_lines(keymaps)
    if #keymaps == 0 then
        return nil
    end

    local lines = { "Keymaps:" }
    for _, map in ipairs(keymaps) do
        table.insert(lines, string.format("%s — %s", map.lhs, map.desc))
    end
    return table.concat(lines, " ")
end

---@param buf integer
---@param keymaps FloatingWindowKeymap[]|nil
---@param instance FloatingWindowInstance
---@param attached_keymaps FloatingWindowAttachedKeymap[]
local function set_keymaps(buf, keymaps, instance, attached_keymaps)
    for _, map in ipairs(keymaps or {}) do
        local mode = map.mode or "n"
        local lhs = map.lhs
        local rhs = map.rhs
        local opts = vim.tbl_extend("force", { buffer = buf, silent = true, nowait = false }, map.opts or {})
        table.insert(attached_keymaps, {
            lhs = lhs,
            mode = mode,
            desc = (map.opts and map.opts.desc) or "No description",
        })

        if map.callback then
            vim.keymap.set(mode, lhs, function()
                map.callback(instance)
            end, opts)
        elseif rhs then
            vim.keymap.set(mode, lhs, rhs, opts)
        end
    end
end

---@param buf integer
---@param instance FloatingWindowInstance
---@param attached_keymaps FloatingWindowAttachedKeymap[]
local function setup_autocmds(buf, instance, attached_keymaps)
    local group = vim.api.nvim_create_augroup("FloatingWindow_" .. instance.id, { clear = true })

    vim.api.nvim_create_autocmd("BufWipeout", {
        group = group,
        buffer = buf,
        callback = function()
            if state.windows[instance.id] and state.windows[instance.id].opts and type(state.windows[instance.id].opts.on_exit) == "function" then
                pcall(state.windows[instance.id].opts.on_exit, state.windows[instance.id])
            end
            state.windows[instance.id] = nil
        end,
    })

    if instance.opts.close_on_escape ~= false then
        vim.keymap.set("n", "<Esc>", function()
            close_by_id(instance.id)
        end, { buffer = buf, silent = true })
        table.insert(attached_keymaps, {
            lhs = "<Esc>",
            mode = "n",
            desc = "Close window",
        })
    end

    if instance.opts.close_on_q then
        vim.keymap.set("n", "q", function()
            close_by_id(instance.id)
        end, { buffer = buf, silent = true })
        table.insert(attached_keymaps, {
            lhs = "q",
            mode = "n",
            desc = "Close window",
        })
    end
end

---Open and configure a floating window instance.
---
---Options support either absolute values or ratio values (`0 < n < 1`) for
---`width`, `height`, `row`, and `col`.
---@param opts? FloatingWindowOptions
---@return FloatingWindowInstance
function M.open(opts)
    opts = opts or {}

    local editor_width = vim.o.columns
    local editor_height = vim.o.lines

    local width = normalize_size(opts.width, editor_width, math.floor(editor_width * 0.7))
    local height = normalize_size(opts.height, editor_height, math.floor(editor_height * 0.7))
    local row = calc_position(editor_height, height, opts.row, math.floor((editor_height - height) / 2 - 1))
    local col = calc_position(editor_width, width, opts.col, math.floor((editor_width - width) / 2))

    local buf = opts.buf
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
        buf = vim.api.nvim_create_buf(default(opts.listed, false), true)
    end

    local enter = default(opts.enter, true)
    local win = vim.api.nvim_open_win(buf, enter, {
        relative = "win",
        row = row,
        col = col,
        width = width,
        height = height,
        style =  opts.style or "minimal",
        border = opts.border or  "rounded",
        title = opts.title,
        title_pos = opts.title_pos or  "center",
        zindex = opts.zindex,
        footer= build_keymap_hint_lines(opts.keymaps),
        footer_pos = 'center' 
    })

    local id = tostring(win)
    ---@type FloatingWindowAttachedKeymap[]
    local attached_keymaps = {}
    local instance = {
        id = id,
        buf = buf,
        win = win,
        opts = opts,
        close = function()
            close_by_id(id)
        end,
        set_lines = function(lines)
            set_buffer_lines(buf, lines)
            render_keymap_hints(buf, attached_keymaps)
        end,
        get_lines = function()
            return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        end,
        focus = function()
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_set_current_win(win)
            end
        end,
    }

    state.windows[id] = instance

    apply_local_options(buf, win, opts)
    set_buffer_lines(buf, opts.initial_lines or {})
    set_keymaps(buf, opts.keymaps, instance, attached_keymaps)
    setup_autocmds(buf, instance, attached_keymaps)

    if opts.enter_insert then
        vim.api.nvim_set_current_win(win)
        vim.cmd("startinsert")
    end

    if type(opts.on_enter) == "function" then
        pcall(opts.on_enter, instance)
    end

    return instance
end

---Close a tracked floating window by Neovim window id or internal instance id.
---@param win_or_id integer|string
function M.close(win_or_id)
    print("This close was called")
    if type(win_or_id) == "number" then
        close_by_id(tostring(win_or_id))
        return
    end

    if type(win_or_id) == "string" then
        close_by_id(win_or_id)
    end
end

---Get a tracked floating window instance by Neovim window id or internal id.
---@param win_or_id integer|string
---@return FloatingWindowInstance|nil
function M.get(win_or_id)
    if type(win_or_id) == "number" then
        return state.windows[tostring(win_or_id)]
    end

    if type(win_or_id) == "string" then
        return state.windows[win_or_id]
    end
end

return M

