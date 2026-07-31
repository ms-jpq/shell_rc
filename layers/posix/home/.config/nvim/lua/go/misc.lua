local async = require "goto.async"
local lib = require "goto.lib"

-- fix stale treesitter commentstring cache
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = lib.group,
  callback = async(function(args)
    local bo = vim.bo[args.buf]
    async.scheduled()

    if vim.api.nvim_buf_is_valid(args.buf) and bo.commentstring == "" then
      bo.commentstring = [[# %s]]
    end
  end),
})
