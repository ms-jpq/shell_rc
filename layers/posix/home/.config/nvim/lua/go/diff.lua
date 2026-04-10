local lib = require "go"

-- vimdiff options
vim.opt.diffexpr = ""
vim.opt.diffopt:append { "followwrap", "algorithm:patience" }

vim.api.nvim_create_autocmd("WinClosed", {
  group = lib.group,
  callback = function()
    local tab = vim.api.nvim_get_current_tabpage()

    local close = function()
      local wins = vim.api.nvim_tabpage_list_wins(tab)
      local diff_wins = vim.tbl_filter(function(win)
        return vim.wo[win].diff
      end, wins)

      if #diff_wins == 1 then
        vim.api.nvim_win_close(unpack(diff_wins), true)
      end
    end

    vim.schedule(close)
  end,
})

vim.api.nvim_create_autocmd("BufWinLeave", {
  group = lib.group,
  callback = function(args)
    if not vim.wo.diff then
      return
    end

    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(args.buf) and vim.fn.bufwinid(args.buf) == -1 then
        vim.api.nvim_buf_delete(args.buf, { force = true })
      end
    end)
  end,
})

vim.cmd.packadd [[nvim.difftool]]
