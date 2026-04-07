local cwd = vim.fn.getcwd()

local cycle = 666
local check_cwd = nil
check_cwd = function()
  local chk = function()
    if vim.fn.getcwd() == "" then
      vim.fn.mkdir(cwd, "p")
      vim.cmd.cd(vim.fn.fnameescape(cwd))
    end
  end

  local go, err = pcall(chk)
  if not go then
    vim.notify(err, vim.log.levels.ERROR)
  else
    vim.defer_fn(check_cwd, cycle)
  end
end

vim.defer_fn(check_cwd, cycle)
