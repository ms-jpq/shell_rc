local async = require "go.async"
local lib = require "go.lib"
local reload = require "go.checktime.reload"
local snapshot = require "go.checktime.snapshot"

-- failable options instead ask for intervention
vim.opt.confirm = true

-- auto save file
vim.opt.autowriteall = true
vim.opt.autoread = false

-- no backup
vim.opt.backup = false
vim.opt.writebackup = false

local check_visible = function()
  local checked = {}

  for _, win in pairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if not checked[buf] then
      checked[buf] = true
      vim.cmd.checktime { tostring(buf), mods = { silent = true, emsg_silent = true } }
    end
  end
end

do
  local alive = lib.generation "checktime"
  local check_interval = 99

  local sync_visible = function()
    check_visible()
    vim.cmd [[silent! wall! ++p]]
  end

  vim.api.nvim_create_autocmd({ "VimLeavePre", "FocusLost" }, {
    group = lib.group,
    command = [[silent! wall! ++p]],
  })

  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    group = lib.group,
    callback = function(args)
      local name = vim.api.nvim_buf_get_name(args.buf)
      if name == "" then
        return
      end
      if not reload.apply(args.buf, name) then
        error("checktime: " .. name, 0)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "BufReadPost" }, {
    group = lib.group,
    callback = function(args)
      local lines = vim.api.nvim_buf_get_lines(args.buf, 0, -1, true)
      snapshot.set(args.buf, lines)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = lib.group,
    callback = function(args)
      local name = vim.api.nvim_buf_get_name(args.buf)
      if name ~= "" then
        reload.apply(args.buf, name)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "FileChangedShell" }, {
    group = lib.group,
    callback = function(args)
      local name = vim.api.nvim_buf_get_name(args.buf)
      vim.v.fcs_choice = name ~= "" and reload.apply(args.buf, name) and "" or "ask"
    end,
  })

  async.run(function()
    while alive() do
      async.sleep(check_interval)
      if alive() then
        sync_visible()
      end
    end
  end)
end
