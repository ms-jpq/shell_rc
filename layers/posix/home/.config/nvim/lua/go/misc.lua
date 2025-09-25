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
