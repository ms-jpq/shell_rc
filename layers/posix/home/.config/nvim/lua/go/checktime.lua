-- auto save file
vim.opt.autowrite = true
vim.opt.autowriteall = true

-- noskip backup
vim.opt.backupskip = ""

-- persistent undo
vim.opt.undofile = true

vim.api.nvim_create_autocmd({"FocusGained", "VimResume", "WinEnter"}, {command = "silent! checktime"})

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

vim.api.nvim_create_autocmd({"BufLeave", "FocusLost"}, {callback = check_time(false)})

vim.api.nvim_create_autocmd({"CursorHold", "CursorHoldI"}, {callback = check_time(true)})

vim.api.nvim_create_autocmd({"VimLeavePre"}, {command = [[silent! wall!]]})

local cycle = 600
local check_times = nil
check_times = function()
  local mode = vim.api.nvim_get_mode().mode
  if vim.startswith(mode, "i") then
    check_time(true)
  end
  vim.defer_fn(check_times, cycle)
end
vim.defer_fn(check_times, 600)
