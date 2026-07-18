vim.bo.commentstring = [[*> %s]]
vim.b.noindent = true

do
  local group = vim.api.nvim_create_augroup([[lv_cobol]], { clear = true })

  local colorcolumn = function()
    vim.wo.colorcolumn = vim.bo.filetype == "cobol" and "7" or ""
  end

  vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
    group = group,
    callback = colorcolumn,
  })
  colorcolumn()
end
