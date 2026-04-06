vim.opt.background = [[light]]

do
  -- https://github.com/EdenEast/nightfox.nvim
  -- vim.cmd [[colorscheme dayfox]]
end

do
  vim.cmd.colorscheme [[iceberg]]

  -- theme
  vim.cmd.source(vim.fs.joinpath(vim.fn.stdpath "config", "plugin", "theme.vim"))
end
