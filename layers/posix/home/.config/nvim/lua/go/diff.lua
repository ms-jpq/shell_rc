local async = require "go.async"
local lib = require "go.lib"

-- vimdiff options
vim.opt.diffexpr = ""
vim.opt.diffopt:append { "followwrap", "algorithm:patience" }

vim.api.nvim_create_autocmd({ "OptionSet" }, {
  pattern = "diff",
  group = lib.group,
  callback = function()
    if vim.v.option_new ~= "0" then
      vim.bo.bufhidden = "wipe"
    end
  end,
})

vim.api.nvim_create_autocmd({ "WinClosed" }, {
  group = lib.group,
  callback = async(function()
    local tab = vim.api.nvim_get_current_tabpage()

    async.scheduled()

    if not vim.api.nvim_tabpage_is_valid(tab) then
      return
    end

    local wins = vim.api.nvim_tabpage_list_wins(tab)
    local diff_wins = vim.tbl_filter(function(win)
      return vim.wo[win].diff
    end, wins)

    if #diff_wins == 1 then
      vim.api.nvim_win_close(unpack(diff_wins), true)
    end
  end),
})

vim.cmd.packadd [[nvim.difftool]]
