local async = require "go.async"
local lib = require "go.lib"
local loop = require "go.checktime.loop"
local reload = require "go.checktime.reload"
local snapshot = require "go.checktime.snapshot"

-- failable options instead ask for intervention
vim.opt.confirm = true

-- auto save file
vim.opt.autowrite = false
vim.opt.autowriteall = false
vim.opt.autoread = false

-- noskip backup
vim.opt.backup = true
vim.opt.backupskip = ""

local check = function(buf)
  local args = buf and { tostring(buf) } or {}
  args.mods = { silent = true, emsg_silent = true }
  vim.cmd.checktime(args)
end

do
  local alive = lib.generation "checktime"
  local interval = 199
  local state = loop.new(interval)

  vim.api.nvim_create_autocmd("BufReadPost", {
    group = lib.group,
    callback = function(args)
      snapshot.save(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("BufWritePre", {
    group = lib.group,
    callback = function(args)
      local name = vim.api.nvim_buf_get_name(args.buf)
      if name == "" then
        return
      end
      if not reload.prepare_write(args.buf, name) then
        error("checktime: refusing to write without a current file snapshot", 0)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = lib.group,
    callback = function(args)
      local name = vim.api.nvim_buf_get_name(args.buf)
      if name ~= "" then
        reload.apply(args.buf, name)
      else
        snapshot.save(args.buf)
      end
    end,
  })

  async.run(function()
    while alive() do
      async.sleep(interval)
      check()
    end
  end)

  vim.api.nvim_create_autocmd({ "FileChangedShell" }, {
    group = lib.group,
    callback = async(function(args)
      vim.v.fcs_choice = ""
      if args.file == "" then
        return
      end
      state.queue_change(args.buf, args.file)
    end),
  })

  async.run(function()
    for q in state.iter(alive) do
      for buf, spec in pairs(q) do
        if vim.api.nvim_buf_is_valid(buf) then
          reload.apply(buf, spec.name)
        end
      end
    end
  end)
end
