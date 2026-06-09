local async = require "go.async"
local lib = require "go"

-- limit session restoration info
vim.opt.sessionoptions:remove { "blank", "buffers", "curdir", "help", "terminal" }
vim.opt.sessionoptions:append { "skiprtp" }

-- scratch buffer
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  group = lib.group,
  callback = function(args)
    if vim.api.nvim_buf_get_name(args.buf) == "" and vim.bo[args.buf].buftype == "" then
      vim.bo[args.buf].buftype = "nofile"
    end
  end,
})

local argv_names = function(cwd)
  local argv = vim.fn.argv(-1) --[[@as string[] ]]
  local acc = {}
  local mapping = {}
  for i, name in ipairs(argv) do
    local joined = string.sub(name, 1, 1) == lib.os.sep and name or vim.fs.joinpath(cwd, name)
    local norm = vim.fs.normalize(joined, { expand_env = false })
    table.insert(acc, norm)
    mapping[norm] = i
  end
  return acc, mapping
end

local detect_stdin = function(cwd)
  local _, mapping = argv_names(cwd)

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local dirty = function()
      if vim.api.nvim_buf_line_count(buf) > 1 then
        return true
      end

      local lines = vim.api.nvim_buf_get_lines(buf, -2, -1, true)
      return #lines > 0 and #lines[1] > 0
    end

    local name = vim.api.nvim_buf_get_name(buf)
    if not mapping[name] and dirty() then
      return true
    end
  end

  return false
end

local no_session = (function()
  local cached = nil

  return function(cwd)
    if cwd == "" then
      return true
    end

    if cached ~= nil then
      return cached
    end

    cached = vim.fn.getcwd() == vim.uv.os_homedir() or vim.o.diff or detect_stdin(cwd)

    return cached
  end
end)()

local safe_name = function(key)
  return (string.gsub(key, "[^%w._-]", function(c)
    return string.format("%%%02x", string.byte(c))
  end))
end

local session_path = function(cwd)
  local argv = vim.fn.argv(-1) --[[@as string[] ]]
  local name = safe_name(cwd or vim.fn.getcwd())
  local postfix = table.concat(vim.tbl_map(safe_name, argv), "&")
  local dir = vim.fs.joinpath(vim.fn.stdpath "cache", "sessions", name)
  local path = vim.fs.joinpath(dir, postfix .. ".vim")

  local norm = vim.fs.normalize(path, { expand_env = false })
  local escaped = vim.fn.fnameescape(norm)
  return norm, escaped
end

local mk_session = function(kill)
  local cwd = vim.fn.getcwd()
  if not kill and no_session(cwd) then
    return
  end

  local path, escaped = session_path(cwd)
  local parent = vim.fs.dirname(path)
  vim.fn.mkdir(parent, "p")
  vim.fn.setfperm(parent, [[rwxr-xr-x]])

  vim.cmd.mksession { escaped, bang = true }
end

local prune_buffers = function()
  vim
    .iter(vim.api.nvim_list_bufs())
    :filter(function(buf)
      return vim.bo[buf].buflisted and vim.fn.filereadable(vim.api.nvim_buf_get_name(buf)) == 0
    end)
    :each(function(buf)
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
end

vim.api.nvim_create_user_command("PS", function()
  prune_buffers()
  mk_session(true)
end, {})

vim.api.nvim_create_user_command("KS", function()
  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  mk_session(true)
end, {})

vim.api.nvim_create_autocmd({ "VimSuspend", "FocusLost", "CursorHold" }, { group = lib.group, callback = mk_session })

vim.api.nvim_create_autocmd({ "QuitPre" }, {
  group = lib.group,
  once = true,
  callback = function()
    if no_session(nil) then
      return
    end

    prune_buffers()
    mk_session()
  end,
})

local restore = function(cwd)
  if no_session(cwd) then
    return
  end

  local path, escaped = session_path(cwd)
  if vim.fn.filereadable(path) == 1 then
    async.scheduled()
    vim.cmd.source { escaped, mods = { silent = true, emsg_silent = true } }
  end
end

local move_tabs = function(cwd)
  local argv, mapping = argv_names(cwd)
  if #argv == 0 or vim.wo.diff then
    return
  end

  async.scheduled()
  local wins = {}
  for name in vim.iter(argv):rev() do
    vim.cmd [[0tabnew]]
    local win = vim.api.nvim_get_current_win()
    local blank = vim.api.nvim_win_get_buf(win)
    wins[name] = { win, blank }
  end

  local acc = {}
  for tab in vim.iter(vim.api.nvim_list_tabpages()):skip(#argv) do
    for _, win in pairs(vim.api.nvim_tabpage_list_wins(tab)) do
      local buf = vim.api.nvim_win_get_buf(win)
      local name = vim.api.nvim_buf_get_name(buf)
      if mapping[name] then
        acc[name] = buf
        vim.api.nvim_win_close(win, true)
      end
    end
  end

  for name in pairs(mapping) do
    local buf = acc[name]
    local win, blank = unpack(wins[name])
    if buf then
      vim.api.nvim_win_set_buf(win, buf)
    else
      local escaped = vim.fn.fnameescape(name)
      vim.api.nvim_win_call(win, function()
        vim.cmd.edit(escaped)
      end)
    end
    vim.api.nvim_buf_delete(blank, { force = true })
  end

  vim.cmd [[tabfirst]]
end

vim.api.nvim_create_autocmd({ "VimEnter" }, {
  group = lib.group,
  once = true,
  callback = async(function()
    local cwd = vim.fn.getcwd()
    restore(cwd)
    move_tabs(cwd)
  end),
})
