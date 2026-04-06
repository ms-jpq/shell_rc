local lib = require "go"

vim.keymap.set("n", "<M-o>", "van", { remap = true })
vim.keymap.set({ "x", "o" }, "<M-o>", "an", { remap = true })
vim.keymap.set({ "x", "o" }, "<M-i>", "in", { remap = true })

vim.api.nvim_create_autocmd("FileType", {
  group = lib.group,
  callback = function(args)
    local _, _ = pcall(vim.treesitter.start, args.buf)
  end,
})
