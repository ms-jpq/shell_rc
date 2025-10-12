local pid = vim.fn.getpid()

vim.api.nvim_create_autocmd(
  {"BufEnter"},
  {
    pattern = {"*.txt"},
    callback = function()
      if vim.bo.filetype == "help" then
        vim.cmd.wincmd("T")
      end
    end
  }
)

vim.api.nvim_create_autocmd(
  {"VimLeave"},
  {
    callback = function()
      local children = vim.api.nvim_get_proc_children(pid)
      for _, child in ipairs(children) do
        vim.fn.jobstop(child)
      end
      os.exit(1)
    end
  }
)
