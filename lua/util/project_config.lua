local M = {}

local function read_file(path)
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end
  local lines = vim.fn.readfile(path)
  return table.concat(lines, "\n")
end

function M.read_json(root_dir, filename)
  filename = filename or ".nvim.json"
  local path = root_dir .. "/" .. filename

  local content = read_file(path)
  if not content then
    return nil
  end

  local ok, data = pcall(vim.fn.json_decode, content)
  if not ok then
    return nil
  end
  return data
end

function M.get(root_dir, keys, filename)
  local cfg = M.read_json(root_dir, filename)
  if not cfg then
    return nil
  end

  local cur = cfg
  for _, k in ipairs(keys) do
    if type(cur) ~= "table" then
      return nil
    end
    cur = cur[k]
    if cur == nil then
      return nil
    end
  end
  return cur
end

return M

