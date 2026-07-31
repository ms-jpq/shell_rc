local async = require "goto.async"
local autocmd = require "goto.autocmd"
local lib = require "goto.lib"

autocmd.vim_enter(function()
  async.scheduled()
  vim.api.nvim_create_autocmd({ "TermOpen" }, { group = lib.group, command = [[startinsert]] })
end)

vim.api.nvim_create_autocmd({ "TermLeave" }, { group = lib.group, command = [[set nomodified]] })
