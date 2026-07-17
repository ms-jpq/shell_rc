local async = require "go.async"
local lib = require "go.lib"
local loop = require "go.checktime.loop"
local reload = require "go.checktime.reload"

-- failable options instead ask for intervention
vim.opt.confirm = true

-- auto save file
vim.opt.autowrite = true
vim.opt.autowriteall = true
vim.opt.autoread = false

-- noskip backup
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

  async.run(function()
    while alive() do
      async.sleep(interval)
      check()
    end
  end)

  vim.api.nvim_create_autocmd({ "FocusLost", "VimSuspend", "VimLeavePre" }, {
    group = lib.group,
    callback = function()
      state.queue_wall()
    end,
  })

  vim.api.nvim_create_autocmd({ "FileChangedShell" }, {
    group = lib.group,
    callback = async(function(args)
      vim.v.fcs_choice = ""
      if args.file == "" then
        return
      end
      state.queue_change(args.buf, args.file, vim.v.fcs_reason)
    end),
  })

  async.run(function()
    for q, needs_wall in state.iter(alive) do
      local acc = {}
      for buf, spec in pairs(q) do
        if vim.api.nvim_buf_is_valid(buf) then
          local name, reason = spec.name, spec.reason
          if reason == "deleted" then
            acc[buf] = name
          elseif reason == "conflict" or reason == "changed" then
            needs_wall = reload.apply(buf, name) or needs_wall
          end
        end
      end

      if not vim.tbl_isempty(acc) then
        async.sleep(66)
        for buf, name in pairs(acc) do
          if vim.api.nvim_buf_is_valid(buf) then
            if vim.uv.fs_stat(name) then
              check(buf)
            else
              vim.api.nvim_buf_delete(buf, { force = true })
            end
          end
        end
      end

      if needs_wall then
        vim.cmd [[silent! wall! ++p]]
      end
    end
  end)
end
