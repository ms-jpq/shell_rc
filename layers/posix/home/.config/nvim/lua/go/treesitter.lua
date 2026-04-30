local lib = require "go"

vim.keymap.set({ "n" }, "<M-o>", "van", { remap = true })
vim.keymap.set({ "x", "o" }, "<M-o>", "an", { remap = true })
vim.keymap.set({ "x", "o" }, "<M-i>", "in", { remap = true })

vim.api.nvim_create_autocmd({ "FileType" }, {
  group = lib.group,
  callback = function(args)
    local parser = vim.treesitter.get_parser(args.buf)
    if parser then
      vim.treesitter.start(args.buf)
    end
  end,
})
