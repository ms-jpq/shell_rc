local async = require "go.async"
local lib = require "go"

vim.api.nvim_create_autocmd({ "VimEnter" }, {
  group = lib.group,
  once = true,
  callback = async(function()
    async.scheduled()
    vim.api.nvim_create_autocmd({ "TermOpen" }, { group = lib.group, command = [[startinsert]] })
  end),
})

vim.api.nvim_create_autocmd({ "TermLeave" }, { group = lib.group, command = [[set nomodified]] })
