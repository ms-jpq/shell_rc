local lib = require "go.lib"

vim.opt.background = [[light]]

vim.api.nvim_create_autocmd({ "ColorScheme" }, {
  group = lib.group,
  callback = function()
    vim.opt.background = [[light]]
  end,
})

do
  -- https://github.com/EdenEast/nightfox.nvim
  -- vim.cmd [[colorscheme dayfox]]
end

do
  vim.cmd.colorscheme [[iceberg]]

  -- theme
  vim.cmd.source(vim.fs.joinpath(vim.fn.stdpath "config", "plugin", "theme.vim"))
end
