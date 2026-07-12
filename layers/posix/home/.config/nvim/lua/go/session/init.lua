local async = require "go.async"
local lib = require "go.lib"
local scope = require "go.session.scope"

-- limit session restoration info
vim.opt.sessionoptions:remove { "blank", "buffers", "curdir", "help", "terminal" }
vim.opt.sessionoptions:append { "skiprtp" }

local session_dir = vim.fs.joinpath(vim.fn.stdpath "cache", "sessions")

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

  return vim.iter(vim.api.nvim_list_bufs()):any(function(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    if mapping[name] then
      return false
    end

    if vim.api.nvim_buf_line_count(buf) > 1 then
      return true
    end

    local lines = vim.api.nvim_buf_get_lines(buf, -2, -1, true)
    return #lines > 0 and #lines[1] > 0
  end)
end

local no_session = function(cwd)
  if cwd == "" then
    return true
  end

  return cwd == vim.uv.os_homedir() or vim.o.diff or detect_stdin(cwd) or vim.fn.argc(-1) > 0
end

local session_path = function(cwd)
  local argv = vim.fn.argv(-1) --[[@as string[] ]]
  local key = vim.fn.sha256(table.concat({ cwd, unpack(argv) }, "\0"))
  local path = vim.fs.joinpath(session_dir, key .. ".vim")

  local norm = vim.fs.normalize(path, { expand_env = false })
  return norm
end

local mk_session = function(force)
  local cwd = vim.fn.getcwd()
  if not force and no_session(cwd) then
    return
  end

  local path = session_path(cwd)
  local parent = vim.fs.dirname(path)
  vim.fn.mkdir(parent, "p")
  vim.fn.setfperm(parent, [[rwxr-xr-x]])

  vim.cmd.mksession { args = { path }, bang = true }
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
    if no_session(vim.fn.getcwd()) then
      return
    end

    mk_session()
  end,
})

local restore = function(cwd)
  if no_session(cwd) then
    return
  end

  local path = session_path(cwd)
  if vim.fn.filereadable(path) == 1 then
    async.scheduled()
    vim.cmd.source { args = { path }, mods = { silent = true, emsg_silent = true } }
    scope.prune_session(cwd)
  end
end

local move_tabs = function(cwd)
  local argv = argv_names(cwd)
  if #argv < 2 or vim.wo.diff then
    return
  end

  async.scheduled()
  for i = 2, #argv do
    local name = argv[i]
    vim.cmd.tabnew { args = { vim.fn.fnameescape(name) }, mods = { keepalt = true } }
  end

  vim.cmd.tabfirst()
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
