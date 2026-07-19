local async = require "go.async"
local autocmd = require "go.autocmd"
local lib = require "go.lib"
local scope = require "go.session.scope"

-- limit session restoration info
vim.opt.sessionoptions:remove { "blank", "buffers", "curdir", "help", "terminal" }
vim.opt.sessionoptions:append { "skiprtp" }

local session_dir = vim.fs.joinpath(vim.fn.stdpath "cache", "sessions")
local startup_cwd = vim.fn.getcwd()

do
  -- scratch buffer
  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    group = lib.group,
    callback = function(args)
      if vim.api.nvim_buf_get_name(args.buf) == "" and vim.bo[args.buf].buftype == "" then
        vim.bo[args.buf].buftype = "nofile"
      end
    end,
  })

  vim.api.nvim_create_user_command("PS", function()
    scope.prune_session()
  end, {})

  vim.api.nvim_create_user_command("KS", function()
    for _, buf in pairs(vim.api.nvim_list_bufs()) do
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end, {})
end

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

local no_session = (function()
  local ret = nil

  return function()
    if ret ~= nil then
      return ret
    end

    local cwd = startup_cwd
    if cwd == "" then
      ret = true
      return ret
    end

    local _, mapping = argv_names(cwd)
    local stdin = vim.iter(vim.api.nvim_list_bufs()):any(function(buf)
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

    ret = cwd == vim.uv.os_homedir() or vim.o.diff or stdin or vim.fn.argc(-1) > 0
    return ret
  end
end)()

local session_path = function(cwd)
  local key = vim.fn.sha256(cwd)
  local path = vim.fs.joinpath(session_dir, key .. ".vim")

  local norm = vim.fs.normalize(path, { expand_env = false })
  return norm
end

local session_ready = false

local mk_session = function()
  if not session_ready or no_session() then
    return
  end

  local path = session_path(startup_cwd)
  local parent = vim.fs.dirname(path)
  vim.fn.mkdir(parent, "p")
  vim.fn.setfperm(parent, [[rwxr-xr-x]])

  vim.cmd.mksession { path, bang = true }
end

local restore = function()
  if no_session() then
    return
  end

  local path = session_path(startup_cwd)
  if vim.fn.filereadable(path) == 1 then
    async.scheduled()
    vim.cmd.source { path, mods = { silent = true, emsg_silent = true } }
    scope.prune_session(startup_cwd)
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
    vim.cmd.tabnew { vim.fn.fnameescape(name), mods = { keepalt = true } }
  end

  vim.cmd.tabfirst()
end

vim.api.nvim_create_autocmd({
  "BufEnter",
  "BufFilePost",
  "BufWinEnter",
  "BufWinLeave",
  "TabClosed",
  "TabNew",
  "VimResized",
  "WinClosed",
  "WinNew",
}, {
  group = lib.group,
  callback = lib.throttle(300, function()
    async.scheduled()
    mk_session()
  end),
})

vim.api.nvim_create_autocmd({ "QuitPre" }, {
  group = lib.group,
  once = true,
  callback = function()
    session_ready = true
    mk_session()
  end,
})

autocmd.vim_enter(function()
  restore()
  move_tabs(startup_cwd)
  session_ready = true
end)
