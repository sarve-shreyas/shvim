-- Claude Code integration (coder/claudecode.nvim)
-- =================================================
-- Makes Neovim Claude Code's "IDE": when Claude proposes an edit it opens a
-- NATIVE nvim diff that you accept/reject BEFORE it touches disk. This is the
-- review-gate: you cannot let Claude change code without seeing the diff first.
--
-- Accept a diff with  :w   or  <leader>ay   (yes)
-- Reject a diff with   :q   or  <leader>ad
-- (<leader>aa is intentionally left as your existing "Select all" map.)

local ok, claudecode = pcall(require, "claudecode")
if not ok then
  return
end

-- State + helper for the tmux pane running Claude for THIS nvim. The pane is
-- tagged with the nvim IDE server port via the tmux pane option @claude_server,
-- so we focus/kill exactly our pane and never a stray or stale one.
local claude_tmux = { port = nil, session_id = nil, resume_id = nil }

local function find_claude_pane(port)
  if not port or port == "" then
    return nil
  end
  local ok_q, panes =
    pcall(vim.fn.systemlist, { "tmux", "list-panes", "-s", "-F", "#{pane_id}\t#{@claude_server}" })
  if not ok_q then
    return nil
  end
  for _, line in ipairs(panes) do
    local id, tag = line:match("^(%%%d+)\t(.*)$")
    if id and tag == tostring(port) then
      return id
    end
  end
  return nil
end

-- True if the launch cmd already says which conversation to use, so we don't also
-- inject our own session tracking (respects manual <leader>aC / <leader>ar).
local function has_session_flag(cmd)
  return cmd:find("%-%-continue") ~= nil
    or cmd:find("%-%-resume") ~= nil
    or cmd:find("%-%-session%-id") ~= nil
end

local function gen_uuid()
  local out = vim.fn.systemlist({ "uuidgen" })
  if out and out[1] and out[1] ~= "" then
    return vim.trim(out[1]):lower()
  end
  return nil
end

-- ─── Session picker (the <leader>ac floating menu) ──────────────────────────
local function rel_time(t)
  local d = os.time() - t
  if d < 60 then
    return "just now"
  elseif d < 3600 then
    return math.floor(d / 60) .. "m ago"
  elseif d < 86400 then
    return math.floor(d / 3600) .. "h ago"
  end
  return math.floor(d / 86400) .. "d ago"
end

-- First real user prompt in a session file, as a short label (tags stripped).
local function first_user_snippet(file)
  local fh = io.open(file, "r")
  if not fh then
    return ""
  end
  local snippet = ""
  for line in fh:lines() do
    if line:find('"type":"user"', 1, true) then
      if #line < 100000 then
        local ok, obj = pcall(vim.json.decode, line)
        if ok and type(obj) == "table" and obj.message then
          local c, text = obj.message.content, nil
          if type(c) == "string" then
            text = c
          elseif type(c) == "table" and type(c[1]) == "table" then
            text = c[1].text or c[1].content
          end
          if type(text) == "string" then
            local s = text:gsub("<[^>]*>", " "):gsub("%s+", " ")
            snippet = (s:gsub("^%s+", ""))
          end
        end
      end
      break -- first user line wins
    end
  end
  fh:close()
  return snippet:sub(1, 60)
end

-- Recent Claude sessions for a directory (most recent first, capped).
local function list_sessions(cwd)
  local enc = (cwd:gsub("/", "-"):gsub("%.", "-"))
  local dir = vim.fn.expand("~/.claude/projects/") .. enc
  if vim.fn.isdirectory(dir) == 0 then
    return {}
  end
  local files = vim.fn.glob(dir .. "/*.jsonl", false, true)
  local sessions = {}
  for _, f in ipairs(files) do
    sessions[#sessions + 1] = { id = vim.fn.fnamemodify(f, ":t:r"), file = f, mtime = vim.fn.getftime(f) }
  end
  table.sort(sessions, function(a, b)
    return a.mtime > b.mtime
  end)
  local out = {}
  for i = 1, math.min(#sessions, 12) do
    out[i] = sessions[i]
  end
  return out
end

local function claude_menu()
  -- Already have our Claude pane up? Just focus it (we have a live session).
  local existing = find_claude_pane(claude_tmux.port)
  if existing then
    vim.fn.system({ "tmux", "select-window", "-t", existing })
    vim.fn.system({ "tmux", "select-pane", "-t", existing })
    return
  end

  local entries = { { label = "✨  New session", action = "new" } }
  for _, s in ipairs(list_sessions(vim.fn.getcwd())) do
    local snip = first_user_snippet(s.file)
    local label = string.format("%-9s  %s", rel_time(s.mtime), (snip ~= "" and snip or ("(" .. s.id:sub(1, 8) .. ")")))
    entries[#entries + 1] = { label = label, action = "resume", id = s.id }
  end

  local lines, width = {}, 24
  for _, e in ipairs(entries) do
    lines[#lines + 1] = "  " .. e.label
    width = math.max(width, #lines[#lines] + 2)
  end
  width = math.min(width, math.floor(vim.o.columns * 0.85))
  local height = math.min(#lines, math.max(1, math.floor(vim.o.lines * 0.6)))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2 - 1),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Claude — pick a session (Enter · q) ",
    title_pos = "center",
  })
  vim.wo[win].cursorline = true
  local ok_c, colorUtil = pcall(require, "util.color")
  local bfg = ok_c and colorUtil.get_contrast_normal_bg and colorUtil.get_contrast_normal_bg()
  if bfg then
    pcall(vim.api.nvim_set_hl, 0, "ClaudeUsageBorder", { fg = bfg, bg = "NONE" })
    pcall(function()
      vim.wo[win].winhighlight = "FloatBorder:ClaudeUsageBorder,FloatTitle:ClaudeUsageBorder"
    end)
  end

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  local function choose()
    local lnum = vim.api.nvim_win_get_cursor(win)[1]
    local e = entries[lnum]
    close()
    if not e then
      return
    end
    vim.schedule(function()
      claude_tmux.resume_id = (e.action == "resume") and e.id or nil
      pcall(vim.cmd, "ClaudeCode")
    end)
  end
  vim.keymap.set("n", "<CR>", choose, { buffer = buf, nowait = true })
  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
end

claudecode.setup({
  -- Run the nvim Claude in `auto` so routine tools (bash, reads, web, MCP) don't
  -- prompt, but force your approval for FILE EDITS via an inline `ask` rule. The
  -- --settings JSON layers ON TOP of your global ~/.claude/settings.json (deny
  -- list etc. still apply) and is scoped to THIS launch only, so ops/global
  -- sessions are unaffected. Net: auto-allow everything except Edit/Write/
  -- NotebookEdit, which always wait for you. (MultiEdit isn't a real tool here.)
  terminal_cmd = 'claude --permission-mode auto --settings {"permissions":{"ask":["Edit","Write","NotebookEdit"]}}',
  terminal = {
    -- Run Claude in a tmux pane beside nvim (not an in-nvim :terminal). nvim
    -- still hosts the IDE WebSocket server, so diffs / selection-send /
    -- @-mentions / diagnostics keep working; the pane's claude connects back via
    -- the env vars (injected with tmux -e) + the ~/.claude/ide lockfile. Bonus:
    -- a real terminal renders Claude's faint hint text correctly.
    -- REQUIRES nvim running inside tmux. To revert to the in-nvim split, set
    -- provider = "native" and delete provider_opts.
    provider = "external",
    provider_opts = {
      external_terminal_cmd = function(cmd, env)
        local port = env.CLAUDE_CODE_SSE_PORT
        claude_tmux.port = port -- remember so ExitPre can close exactly this pane
        -- Focus OUR pane (tagged with this nvim's server port) if it's already up.
        -- Precise: never matches a stray/stale Claude not tied to this nvim.
        local existing = find_claude_pane(port)
        if existing then
          return { "tmux", "select-window", "-t", existing, ";", "select-pane", "-t", existing }
        end
        -- Otherwise open a side-by-side split beside nvim, inject the connection
        -- env (tmux panes don't inherit it), and tag the new pane with our port.
        local parts = { "tmux", "split-window", "-h", "-l", "40%" }
        if vim.env.TMUX_PANE and vim.env.TMUX_PANE ~= "" then
          vim.list_extend(parts, { "-t", vim.env.TMUX_PANE })
        end
        for k, v in pairs(env) do
          vim.list_extend(parts, { "-e", k .. "=" .. tostring(v) })
        end
        -- Build the claude argv with session tracking: resume the EXACT session we
        -- recorded (reopen), else pin a fresh session id so THIS conversation is
        -- resumable later — instead of trusting --continue's "most recent" guess.
        local toks = vim.split(cmd, " ", { trimempty = true })
        if not has_session_flag(cmd) then
          if claude_tmux.resume_id and claude_tmux.resume_id ~= "" then
            table.insert(toks, 2, claude_tmux.resume_id)
            table.insert(toks, 2, "--resume")
            claude_tmux.session_id = claude_tmux.resume_id
            claude_tmux.resume_id = nil
          else
            local uuid = gen_uuid()
            if uuid then
              table.insert(toks, 2, uuid)
              table.insert(toks, 2, "--session-id")
              claude_tmux.session_id = uuid
            end
          end
        end
        vim.list_extend(parts, toks)
        if port then
          vim.list_extend(parts, { ";", "set-option", "-p", "@claude_server", tostring(port) })
        end
        return parts
      end,
    },
  },
})

local map = vim.keymap.set

-- Session ---------------------------------------------------------------------
map("n", "<leader>ac", claude_menu,                      { desc = "Claude: session menu" })
map("n", "<leader>af", "<cmd>ClaudeCodeFocus<cr>",       { desc = "Claude: focus" })
map("n", "<leader>ar", "<cmd>ClaudeCode --resume<cr>",   { desc = "Claude: resume" })
map("n", "<leader>aC", "<cmd>ClaudeCode --continue<cr>", { desc = "Claude: continue" })
map("n", "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", { desc = "Claude: select model" })

-- Send context ----------------------------------------------------------------
map("n", "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", { desc = "Claude: add current buffer" })
map("v", "<leader>as", "<cmd>ClaudeCodeSend<cr>",  { desc = "Claude: send selection" })

-- In a file tree (neo-tree/etc), <leader>as adds the file/dir under the cursor.
-- Scoped to tree filetypes so it doesn't shadow the visual-mode send above.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
  callback = function(ev)
    vim.keymap.set("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>",
      { buffer = ev.buf, desc = "Claude: add file (tree)" })
  end,
})

-- Diff accept / reject --------------------------------------------------------
map("n", "<leader>ay", "<cmd>ClaudeCodeDiffAccept<cr>",    { desc = "Claude: accept diff (yes)" })
map("n", "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",      { desc = "Claude: reject diff" })
map("n", "<leader>aq", "<cmd>ClaudeCodeCloseAllDiffs<cr>", { desc = "Claude: close all diffs" })

-- Auto-reload files Claude changes on disk when you have them open elsewhere
-- and haven't modified them in nvim. (The diff-gate handles the in-flight file;
-- this catches sibling files.) CursorHold entries are a fallback for when
-- terminal/tmux focus events don't fire.
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  command = "checktime",
})

-- ─── Quit + session integration (tmux Claude pane) ──────────────────────────
-- Claude runs in a tmux pane tied to this nvim. On exit we close that pane (so we
-- never leave a stale pane bound to a dead server) and record whether it was open;
-- a restored session then reopens it with --continue. We also kill any in-nvim
-- terminal jobs (e.g. the <C-t> shell) so :qa/:qas don't hit E948.

local function session_paths()
  local cwd = vim.fn.getcwd()
  return cwd .. "/.nvim/session.vim", cwd .. "/.nvim/.claude_open"
end

local grp = vim.api.nvim_create_augroup("ClaudeCodeQuitSession", { clear = true })

-- On exit: close OUR Claude tmux pane and stamp the session marker if it was open;
-- also kill in-nvim terminal jobs (e.g. the <C-t> shell) so :qa/:qas are clean.
vim.api.nvim_create_autocmd("ExitPre", {
  group = grp,
  desc = "Close Claude tmux pane on exit + stamp session marker",
  callback = function()
    local pane = find_claude_pane(claude_tmux.port)
    local _, marker = session_paths()
    -- Mark "Claude was open" INDEPENDENTLY of the file session (.nvim/session.vim)
    -- — create .nvim/ if needed — so Claude reopens even when no file session was
    -- saved. Then close our pane.
    if pane then
      local ndir = vim.fn.getcwd() .. "/.nvim"
      if vim.fn.isdirectory(ndir) == 0 then
        pcall(vim.fn.mkdir, ndir, "p")
      end
      pcall(vim.fn.writefile, { claude_tmux.session_id or "1" }, marker)
      pcall(vim.fn.system, { "tmux", "kill-pane", "-t", pane })
    elseif vim.fn.filereadable(marker) == 1 then
      pcall(vim.fn.delete, marker)
    end
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(b) and vim.bo[b].buftype == "terminal" then
        local jid = vim.b[b].terminal_job_id
        if jid then
          pcall(vim.fn.jobstop, jid)
        end
        pcall(vim.api.nvim_buf_delete, b, { force = true })
      end
    end
  end,
})

-- On startup: if a session is being restored for this dir AND Claude was open when
-- we left, reopen it resumed — deferred so it lands after the session layout.
vim.api.nvim_create_autocmd("VimEnter", {
  group = grp,
  desc = "Reopen Claude (--continue) if it was open in the restored session",
  callback = function()
    -- Resolve the project dir from argv (this fires before session.lua's cd):
    -- bare `nvim` -> cwd; `nvim .`/`nvim <dir>` -> that dir; a file arg -> skip.
    local argc = vim.fn.argc()
    local dir
    if argc == 0 then
      dir = vim.fn.getcwd()
    elseif argc == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
      dir = (vim.fn.fnamemodify(vim.fn.argv(0), ":p")):gsub("/$", "")
    else
      return
    end
    local marker = dir .. "/.nvim/.claude_open"
    -- Reopen whenever Claude was open in this dir (independent of the file session).
    if vim.fn.filereadable(marker) == 1 then
      local content = vim.fn.readfile(marker)
      local sid = (content and content[1]) or ""
      pcall(vim.fn.delete, marker)
      -- Delay so this lands AFTER session.lua's deferred restore.
      vim.defer_fn(function()
        if sid ~= "" and sid ~= "1" then
          claude_tmux.resume_id = sid -- external_terminal_cmd turns this into --resume <sid>
          pcall(vim.cmd, "ClaudeCode")
        else
          pcall(vim.cmd, "ClaudeCode --continue")
        end
      end, 250)
    end
  end,
})

-- Terminal windows (the Claude split, shells) shouldn't carry the global
-- number/relativenumber/signcolumn — they clutter TUIs like Claude Code. Strip
-- them whenever a terminal opens.
vim.api.nvim_create_autocmd("TermOpen", {
  group = grp,
  desc = "Clean terminal UI: no line numbers / sign column",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})

-- ─── Floating "usage UI" (Claude subscription limits) ──────────────────────
-- Floating window showing your Claude Code SUBSCRIPTION limits via
-- `claude -p /usage`: current session %, weekly all-models %, weekly Sonnet %,
-- and reset times (same data as the in-app Usage screen). It's a plain (nofile)
-- buffer, captured async with vim.system -- no terminal job. Toggle with
-- <leader>au or :ClaudeUsage; press r to refresh, q / <Esc> to close.
local usage = { win = nil, buf = nil }

local function close_usage()
  if usage.win and vim.api.nvim_win_is_valid(usage.win) then
    vim.api.nvim_win_close(usage.win, true)
  end
  usage.win, usage.buf = nil, nil
end

-- Bar rendering for the "X% used" limit lines. Threshold-coloured, theme-linked.
local BAR_W = 28
local usage_ns = vim.api.nvim_create_namespace("ClaudeUsageBars")
vim.api.nvim_set_hl(0, "ClaudeUsageLow", { link = "DiagnosticOk", default = true })
vim.api.nvim_set_hl(0, "ClaudeUsageMid", { link = "DiagnosticWarn", default = true })
vim.api.nvim_set_hl(0, "ClaudeUsageHigh", { link = "DiagnosticError", default = true })
vim.api.nvim_set_hl(0, "ClaudeUsageEmpty", { link = "Comment", default = true })

local function bar_for(pct)
  local filled = math.max(0, math.min(BAR_W, math.floor(pct / 100 * BAR_W + 0.5)))
  return string.rep("█", filled) .. string.rep("░", BAR_W - filled), filled
end

local function usage_hl(pct)
  if pct >= 80 then
    return "ClaudeUsageHigh"
  elseif pct >= 50 then
    return "ClaudeUsageMid"
  end
  return "ClaudeUsageLow"
end

-- Parse `claude -p /usage` text -> (lines, highlights). "<label>: N% used …" lines
-- become labelled bars; everything else is kept as plain indented text. Each
-- highlight is {row, start_col, end_col, group} in BYTE columns (█/░ are 3 bytes).
local function format_usage(out)
  local lines, hls = {}, {}
  for _, raw in ipairs(vim.split(vim.trim(out), "\n", { plain = true })) do
    local label, pct = raw:match("^(.-):%s*(%d+)%%%s+used")
    if label and pct then
      pct = tonumber(pct)
      local reset = raw:match("(resets[^(]+)")
      reset = reset and ("  · " .. vim.trim(reset)) or ""
      local bar, filled = bar_for(pct)
      local prefix = string.format("  %-26s [", label)
      lines[#lines + 1] = string.format("%s%s] %3d%%%s", prefix, bar, pct, reset)
      local row, s = #lines - 1, #prefix
      if filled > 0 then
        hls[#hls + 1] = { row, s, s + filled * 3, usage_hl(pct) }
      end
      if filled < BAR_W then
        hls[#hls + 1] = { row, s + filled * 3, s + BAR_W * 3, "ClaudeUsageEmpty" }
      end
      lines[#lines + 1] = "" -- blank line for spacing between bars
    else
      lines[#lines + 1] = (raw == "") and "" or ("  " .. raw)
    end
  end
  return lines, hls
end

local function set_usage(lines, hls)
  if not (usage.buf and vim.api.nvim_buf_is_valid(usage.buf)) then
    return
  end
  vim.bo[usage.buf].modifiable = true
  vim.api.nvim_buf_set_lines(usage.buf, 0, -1, false, lines)
  vim.bo[usage.buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(usage.buf, usage_ns, 0, -1)
  for _, h in ipairs(hls or {}) do
    pcall(vim.api.nvim_buf_set_extmark, usage.buf, usage_ns, h[1], h[2], { end_col = h[3], hl_group = h[4] })
  end
end

local function fetch_usage()
  set_usage({ "", "  Loading Claude usage…", "" }, {})
  local claude = vim.fn.exepath("claude")
  if claude == "" then
    claude = "claude"
  end
  vim.system({ claude, "-p", "/usage" }, { text = true, timeout = 30000 }, function(res)
    vim.schedule(function()
      local out = res.stdout or ""
      if vim.trim(out) == "" then
        out = (res.stderr ~= nil and res.stderr ~= "") and res.stderr or "(no output from `claude -p /usage`)"
      end
      local lines, hls = format_usage(out)
      table.insert(lines, 1, "") -- leading blank; shift highlight rows to match
      for _, h in ipairs(hls) do
        h[1] = h[1] + 1
      end
      lines[#lines + 1] = ""
      set_usage(lines, hls)
    end)
  end)
end

local function toggle_usage_float()
  if usage.win and vim.api.nvim_win_is_valid(usage.win) then
    close_usage()
    return
  end

  local width = math.max(72, math.floor(vim.o.columns * 0.7))
  local height = math.max(16, math.floor(vim.o.lines * 0.7))
  usage.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[usage.buf].bufhidden = "wipe"
  usage.win = vim.api.nvim_open_win(usage.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2 - 1),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Claude usage — /usage  (r refresh · q close) ",
    title_pos = "center",
  })
  vim.wo[usage.win].wrap = true

  -- Make the rounded border + title visible (match the rest of the UI's floats,
  -- which colour the border to contrast against Normal bg).
  local ok_color, colorUtil = pcall(require, "util.color")
  local border_fg = ok_color and colorUtil.get_contrast_normal_bg and colorUtil.get_contrast_normal_bg()
  if border_fg then
    pcall(vim.api.nvim_set_hl, 0, "ClaudeUsageBorder", { fg = border_fg, bg = "NONE" })
  else
    pcall(vim.api.nvim_set_hl, 0, "ClaudeUsageBorder", { link = "Title", default = true })
  end
  pcall(function()
    vim.wo[usage.win].winhighlight = "FloatBorder:ClaudeUsageBorder,FloatTitle:ClaudeUsageBorder"
  end)

  vim.keymap.set("n", "q", close_usage, { buffer = usage.buf, nowait = true, desc = "Close usage" })
  vim.keymap.set("n", "<Esc>", close_usage, { buffer = usage.buf, nowait = true, desc = "Close usage" })
  vim.keymap.set("n", "r", fetch_usage, { buffer = usage.buf, nowait = true, desc = "Refresh usage" })

  fetch_usage()
end

vim.api.nvim_create_user_command("ClaudeUsage", toggle_usage_float, {
  desc = "Toggle Claude usage limits (/usage) floating window",
})
map("n", "<leader>au", toggle_usage_float, { desc = "Claude: usage limits (float)" })
