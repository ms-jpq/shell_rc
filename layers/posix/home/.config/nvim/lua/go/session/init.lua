local async = require "go.async"
local lib = require "go.lib"
local scope = require "go.session.scope"

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

    cached = vim.fn.getcwd() == vim.uv.os_homedir() or vim.o.diff or detect_stdin(cwd) or vim.fn.argc(-1) > 0

    return cached
  end
end)()

local session_path = function(cwd)
  local argv = vim.fn.argv(-1) --[[@as string[] ]]
  local key = vim.fn.sha256(table.concat({ cwd or vim.fn.getcwd(), unpack(argv) }, "\0"))
  local dir = vim.fs.joinpath(vim.fn.stdpath "cache", "sessions")
  local path = vim.fs.joinpath(dir, key .. ".vim")

  local norm = vim.fs.normalize(path, { expand_env = false })
  return norm
end

local mk_session = function(kill)
  local cwd = vim.fn.getcwd()
  if not kill and no_session(cwd) then
    return
  end

  local path = session_path(cwd)
  local parent = vim.fs.dirname(path)
  vim.fn.mkdir(parent, "p")
  vim.fn.setfperm(parent, [[rwxr-xr-x]])

  scope.prune_buffers(cwd)
  local restore_windows = scope.hide_external_windows(cwd)
  local ok, result = pcall(function()
    vim.cmd.mksession { args = { path }, bang = true }
    scope.scrub_session(cwd, path)
  end)
  restore_windows()
  if not ok then
    error(result)
  end
end

vim.api.nvim_create_user_command("PS", function()
  mk_session(true)
end, {})

vim.api.nvim_create_user_command("KS", function()
  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  mk_session(true)
end, {})

vim.api.nvim_create_autocmd({ "VimSuspend", "FocusLost", "CursorHold" }, {
  group = lib.group,
  callback = lib.throttle(300, function()
    mk_session()
  end),
})

vim.api.nvim_create_autocmd({ "QuitPre" }, {
  group = lib.group,
  once = true,
  callback = function()
    if no_session(nil) then
      return
    end

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
    scope.prune_buffers(cwd)
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
      vim.api.nvim_win_call(win, function()
        vim.cmd("keepalt buffer " .. buf)
      end)
    else
      vim.api.nvim_win_call(win, function()
        vim.cmd.edit { args = { name }, mods = { keepalt = true } }
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
