local async = require "go.async"
local lib = require "go.lib"

-- failable options instead ask for intervention
vim.opt.confirm = true

-- auto save file
vim.opt.autowrite = true
vim.opt.autowriteall = true

-- noskip backup
vim.opt.backupskip = ""

vim.api.nvim_create_autocmd({ "VimLeavePre" }, { group = lib.group, once = true, command = [[silent! wall! ++p]] })

local alive = lib.generation "checktime"

do
  local cycle = 1888
  local focused = true

  vim.api.nvim_create_autocmd({ "FocusGained", "VimResume", "WinEnter" }, {
    group = lib.group,
    callback = function()
      focused = true
      vim.cmd.checktime { mods = { silent = true, emsg_silent = true } }
    end,
  })

  vim.api.nvim_create_autocmd({ "FocusLost" }, {
    group = lib.group,
    callback = function()
      focused = false
      if vim.api.nvim_buf_get_name(0) ~= "" then
        vim.cmd.checktime { count = vim.api.nvim_get_current_buf(), mods = { silent = true, emsg_silent = true } }
      end
      vim.cmd [[silent! wall! ++p]]
    end,
  })

  vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    group = lib.group,
    callback = function()
      vim.cmd [[silent! wall! ++p]]
    end,
  })

  local sweep = function()
    for _, b in pairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buftype == "" and vim.api.nvim_buf_get_name(b) ~= "" then
        vim.cmd.checktime { count = b, mods = { silent = true, emsg_silent = true } }
      end
    end
  end

  async.run(function()
    while alive() do
      async.sleep(cycle)

      if not focused or not vim.startswith(vim.api.nvim_get_mode().mode, "i") then
        lib.report(sweep)
      end
    end
  end)
end
