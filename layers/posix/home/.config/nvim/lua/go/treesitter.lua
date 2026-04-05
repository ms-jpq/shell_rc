local lib = require("go")

vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.indentexpr = "v:lua.require('nvim-treesitter').indentexpr()"

vim.keymap.set("n", "<M-o>", "van", {remap = true})
vim.keymap.set({"x", "o"}, "<M-o>", "an", {remap = true})
vim.keymap.set({"x", "o"}, "<M-i>", "in", {remap = true})

do
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok then
    parsers = {}
  end

  local filetypes = {}
  for parser, _ in pairs(parsers) do
    for _, ft in pairs(vim.treesitter.language.get_filetypes(parser)) do
      table.insert(filetypes, ft)
    end
  end

  vim.api.nvim_create_autocmd(
    "FileType",
    {
      group = lib.group,
      pattern = filetypes,
      callback = function(args)
        local _, _ =
          pcall(
          function()
            vim.treesitter.start(args.buf)
          end
        )
      end
    }
  )
end
