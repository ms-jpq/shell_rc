local async = require "go.async"
local lib = require "go"

local cwd = vim.fn.getcwd()

async.run(function()
  while true do
    async.sleep(666)

    local ok = lib.report(function()
      if vim.fn.getcwd() == "" then
        vim.fn.mkdir(cwd, "p")
        vim.cmd.cd(vim.fn.fnameescape(cwd))
      end
    end)

    if not ok then
      return
    end
  end
end)
