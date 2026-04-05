local lib = require("go")

vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"

vim.keymap.set("n", "<M-o>", "van", {remap = true})
vim.keymap.set({"x", "o"}, "<M-o>", "an", {remap = true})
vim.keymap.set({"x", "o"}, "<M-i>", "in", {remap = true})

vim.api.nvim_create_autocmd(
  "FileType",
  {
    group = lib.group,
    callback = function(args)
      local start = function()
        vim.treesitter.start(args.buf)
      end

      local _, _ = pcall(start)
    end
  }
)
