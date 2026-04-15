local async = require "go.async"
local lib = require "go"

-- failable options instead ask for intervention
vim.opt.confirm = true

-- auto save file
vim.opt.autowrite = true
vim.opt.autowriteall = true

-- noskip backup
vim.opt.backupskip = ""

vim.api.nvim_create_autocmd(
  { "FocusGained", "VimResume", "WinEnter" },
  { group = lib.group, command = "silent! checktime" }
)

vim.api.nvim_create_autocmd({ "VimLeavePre" }, { group = lib.group, once = true, command = [[silent! wall! ++p]] })

do
  local check_time = function(lo)
    return function()
      if lo then
        if vim.api.nvim_buf_get_name(0) ~= "" then
          local nr = vim.api.nvim_get_current_buf()
          vim.cmd.checktime(nr)
        end
      else
        vim.cmd [[silent! checktime]]
      end

      vim.cmd [[silent! wall! ++p]]
    end
  end

  vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, { group = lib.group, callback = check_time(false) })
  vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, { group = lib.group, callback = check_time(true) })

  local cycle = 1888
  async.run(function()
    while true do
      async.sleep(cycle)

      local mode = vim.api.nvim_get_mode().mode
      if not vim.startswith(mode, "i") then
        check_time(true)()
      end
    end
  end)
end
