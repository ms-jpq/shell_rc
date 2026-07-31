local async = require "goto.async"
local lib = require "goto.lib"

local cwd = vim.fn.getcwd()
local alive = lib.generation "cwd"

async.run(function()
  while alive() do
    async.sleep(666)

    local ok = lib.report(function()
      if vim.fn.getcwd() == "" then
        vim.fn.mkdir(cwd, "p")
        vim.cmd.cd { cwd }
      end
    end)

    if not ok then
      return
    end
  end
end)
