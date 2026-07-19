local async = require "go.async"
local autocmd = require "go.autocmd"
local lib = require "go.lib"

autocmd.vim_enter(function()
  async.scheduled()
  vim.api.nvim_create_autocmd({ "TermOpen" }, { group = lib.group, command = [[startinsert]] })
end)

vim.api.nvim_create_autocmd({ "TermLeave" }, { group = lib.group, command = [[set nomodified]] })
