-- persistent undo
vim.opt.undofile = true
vim.opt.undolevels = 60

do
  vim.cmd.packadd [[nvim.undotree]]
  local undotree = require "undotree"

  vim.keymap.set({ "n" }, "U", undotree.open)
end
