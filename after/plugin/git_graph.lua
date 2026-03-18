local state = {
  buf = nil,
  win = nil,
  root = nil,
  commits = {},
}

local function repo_root()
  local out = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })
  if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
    return nil
  end
  return out[1]
end

local function git_lines(root, args)
  return vim.fn.systemlist(vim.list_extend({ "git", "-C", root }, args))
end

local function close_graph()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.buf = nil
  state.win = nil
  state.root = nil
  state.commits = {}
end

local function parse_log(root)
  local format = table.concat({
    "%H",
    "%P",
    "%h",
    "%an",
    "%ad",
    "%d",
    "%s",
  }, "\31")

  local lines = git_lines(root, {
    "log",
    "--all",
    "--date=format:%H:%M:%S %d-%m-%Y",
    "--decorate=short",
    "--topo-order",
    "--pretty=format:" .. format,
    "-n",
    "300",
  })

  if vim.v.shell_error ~= 0 then
    return nil
  end

  local commits = {}

  for _, line in ipairs(lines) do
    local parts = vim.split(line, "\31", { plain = true })
    local hash = parts[1] or ""
    local parents = {}
    if parts[2] and parts[2] ~= "" then
      parents = vim.split(parts[2], " ", { trimempty = true })
    end

    table.insert(commits, {
      hash = hash,
      parents = parents,
      short = parts[3] or "",
      author = parts[4] or "",
      date = parts[5] or "",
      refs = parts[6] or "",
      subject = parts[7] or "",
    })
  end

  return commits
end

local function lane_index(lanes, hash)
  for i, v in ipairs(lanes) do
    if v == hash then
      return i
    end
  end
  return nil
end

local function remove_lane(lanes, idx)
  table.remove(lanes, idx)
end

local function insert_lane(lanes, idx, value)
  table.insert(lanes, idx, value)
end

local function set_lane(lanes, idx, value)
  lanes[idx] = value
end

local function render_connector_cell(kind)
  if kind == "empty" then
    return "  "
  end
  if kind == "line" then
    return "│ "
  end
  if kind == "merge_right" then
    return "├─"
  end
  if kind == "merge_down" then
    return "╰─"
  end
  if kind == "join" then
    return "┴─"
  end
  return "  "
end

local function render_commit_prefix(lanes, current_idx, commit)
  local cells = {}

  for i = 1, #lanes do
    if i == current_idx then
      if #commit.parents > 1 then
        table.insert(cells, "M ")
      else
        table.insert(cells, "* ")
      end
    else
      table.insert(cells, lanes[i] and "│ " or "  ")
    end
  end

  return table.concat(cells)
end

local function render_post_line(lanes, current_idx, parent_count)
  local cells = {}

  for i = 1, #lanes do
    if i < current_idx then
      table.insert(cells, lanes[i] and "│ " or "  ")
    elseif i == current_idx then
      if parent_count > 1 then
        table.insert(cells, "├─")
      else
        table.insert(cells, "│ ")
      end
    else
      if i <= current_idx + parent_count - 1 then
        if i == current_idx + parent_count - 1 then
          table.insert(cells, "╮ ")
        else
          table.insert(cells, "─")
        end
      else
        table.insert(cells, lanes[i] and "│ " or "  ")
      end
    end
  end

  return table.concat(cells)
end

local function build_graph_lines(commits)
  local lines = {}
  local lanes = {}
  local row_to_hash = {}

  for _, commit in ipairs(commits) do
    local idx = lane_index(lanes, commit.hash)

    if not idx then
      table.insert(lanes, 1, commit.hash)
      idx = 1
    end

    local prefix = render_commit_prefix(lanes, idx, commit)
    local refs = commit.refs ~= "" and (" " .. commit.refs) or ""
    local header = prefix .. commit.short .. " " .. commit.date .. " " .. commit.author .. refs
    local msg_prefix = {}
    for i = 1, #lanes do
      if i == idx then
        table.insert(msg_prefix, "│ ")
      else
        table.insert(msg_prefix, lanes[i] and "│ " or "  ")
      end
    end
    local msg = table.concat(msg_prefix) .. commit.subject

    table.insert(lines, header)
    row_to_hash[#lines] = commit.hash
    table.insert(lines, msg)
    row_to_hash[#lines] = commit.hash

    if #commit.parents == 0 then
      remove_lane(lanes, idx)
    elseif #commit.parents == 1 then
      set_lane(lanes, idx, commit.parents[1])
    else
      set_lane(lanes, idx, commit.parents[1])
      for p = #commit.parents, 2, -1 do
        insert_lane(lanes, idx + 1, commit.parents[p])
      end
      table.insert(lines, render_post_line(lanes, idx, #commit.parents))
      row_to_hash[#lines] = commit.hash
    end
  end

  return lines, row_to_hash
end

local function open_commit()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end

  local row = vim.api.nvim_win_get_cursor(state.win)[1]
  local hash = state.commits[row]

  if not hash then
    return
  end

  local lines = git_lines(state.root, {
    "show",
    "--stat",
    "--patch",
    "--color=never",
    hash,
  })

  if vim.v.shell_error ~= 0 then
    vim.notify("Could not open commit " .. hash, vim.log.levels.ERROR)
    return
  end

  vim.cmd("tabnew")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.filetype = "diff"
  vim.cmd("normal! gg")
end

local function copy_hash()
  local row = vim.api.nvim_win_get_cursor(state.win)[1]
  local hash = state.commits[row]

  if not hash then
    return
  end

  vim.fn.setreg("+", hash)
  vim.fn.setreg('"', hash)
  vim.notify("Copied " .. hash, vim.log.levels.INFO)
end

local function draw_graph()
  local root = repo_root()
  if not root then
    vim.notify("Not inside a git repository", vim.log.levels.ERROR)
    return
  end

  local commits = parse_log(root)
  if not commits then
    vim.notify("Failed to read git log", vim.log.levels.ERROR)
    return
  end

  local lines, row_to_hash = build_graph_lines(commits)

  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_set_current_win(state.win)
  else
    vim.cmd("botright vsplit")
    state.win = vim.api.nvim_get_current_win()
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(state.win, state.buf)
    vim.cmd("vertical resize 70")
  end

  state.root = root
  state.commits = row_to_hash

  vim.bo[state.buf].buftype = "nofile"
  vim.bo[state.buf].bufhidden = "wipe"
  vim.bo[state.buf].swapfile = false
  vim.bo[state.buf].modifiable = true
  vim.bo[state.buf].filetype = "git"

  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

  vim.bo[state.buf].modifiable = false

  vim.api.nvim_set_option_value("number", false, { win = state.win })
  vim.api.nvim_set_option_value("relativenumber", false, { win = state.win })
  vim.api.nvim_set_option_value("cursorline", true, { win = state.win })
  vim.api.nvim_set_option_value("wrap", false, { win = state.win })
  vim.api.nvim_set_option_value("signcolumn", "no", { win = state.win })
  vim.api.nvim_set_option_value("winfixwidth", true, { win = state.win })

  vim.keymap.set("n", "q", close_graph, { buffer = state.buf, silent = true })
  vim.keymap.set("n", "r", draw_graph, { buffer = state.buf, silent = true })
  vim.keymap.set("n", "<CR>", open_commit, { buffer = state.buf, silent = true })
  vim.keymap.set("n", "o", open_commit, { buffer = state.buf, silent = true })
  vim.keymap.set("n", "y", copy_hash, { buffer = state.buf, silent = true })
end

vim.api.nvim_create_user_command("GitGraphCustom", draw_graph, {})
vim.keymap.set("n", "<leader>gg", draw_graph, { desc = "Custom git graph" })

