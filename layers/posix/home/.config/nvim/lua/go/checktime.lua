local lib = require("go")

-- auto save file
vim.opt.autowrite = true
vim.opt.autowriteall = true

-- noskip backup
vim.opt.backupskip = ""

vim.api.nvim_create_autocmd(
  {"FocusGained", "VimResume", "WinEnter"},
  {group = lib.group, command = "silent! checktime"}
)

vim.api.nvim_create_autocmd({"VimLeavePre"}, {group = lib.group, once = true, command = [[silent! wall!]]})

do
  local check_time = function(lo)
    return function()
      if lo then
        if vim.api.nvim_buf_get_name(0) ~= "" then
          local nr = vim.api.nvim_get_current_buf()
          vim.cmd("checktime" .. nr)
        end
      else
        vim.cmd [[silent! checktime]]
      end

      vim.cmd [[silent! wall!]]
    end
  end

  vim.api.nvim_create_autocmd({"BufLeave", "FocusLost"}, {group = lib.group, callback = check_time(false)})
  vim.api.nvim_create_autocmd({"CursorHold", "CursorHoldI"}, {group = lib.group, callback = check_time(true)})

  local cycle = 600
  local check_times = nil
  check_times = function()
    local mode = vim.api.nvim_get_mode().mode
    if vim.startswith(mode, "i") then
      check_time(true)
    end
    vim.defer_fn(check_times, cycle)
  end
  vim.defer_fn(check_times, cycle)
end
