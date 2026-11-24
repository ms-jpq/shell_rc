local async = require "goto.async"
local autocmd = require "goto.autocmd"
local context = require "go.session.context"
local lib = require "goto.lib"
local scope = require "go.session.scope"

-- limit session restoration info
vim.opt.sessionoptions:remove { "blank", "buffers", "curdir", "help", "terminal" }
vim.opt.sessionoptions:append { "skiprtp" }

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
    local cwd = vim.fn.getcwd()
    scope.prune_session(cwd)
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

    local cwd = context.startup_cwd
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

local session_ready = false
local saved_path = nil

local mk_session = function(update)
  if not session_ready or no_session() then
    return
  end

  local path = context.save_path(update)
  local parent = vim.fs.dirname(path)
  vim.fn.mkdir(parent, "p")
  vim.fn.setfperm(parent, [[rwxr-xr-x]])

  vim.cmd.mksession { path, bang = true }
  if saved_path and saved_path ~= path then
    vim.fn.delete(saved_path)
  end
  saved_path = path
end

local restore = function()
  if no_session() then
    return
  end

  local path = context.restore_path()
  if path then
    async.scheduled()
    vim.cmd.source { path, mods = { silent = true, emsg_silent = true } }
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

vim.api.nvim_create_autocmd({ "FocusLost" }, {
  group = lib.group,
  callback = async(function()
    mk_session(true)
  end),
})

vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
  group = lib.group,
  callback = function()
    mk_session(false)
  end,
})

autocmd.vim_enter(function()
  restore()
  move_tabs(context.startup_cwd)
  session_ready = true
end)
