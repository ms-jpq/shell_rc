local async = require "go.async"

local cwd = vim.fn.getcwd()

async.run(function()
  while true do
    async.sleep(666)

    local ok, err = pcall(function()
      if vim.fn.getcwd() == "" then
        vim.fn.mkdir(cwd, "p")
        vim.cmd.cd(vim.fn.fnameescape(cwd))
      end
    end)

    if not ok then
      vim.notify(err, vim.log.levels.ERROR)
      return
    end
  end
end)
