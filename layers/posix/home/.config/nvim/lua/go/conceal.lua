local async = require "go.async"
local lib = require "go.lib"

vim.opt.conceallevel = 2
vim.opt.concealcursor = [[nc]]

do
  local toggle = function()
    vim.opt.conceallevel = vim.o.conceallevel == 0 and 2 or 0
  end

  vim.keymap.set({ "n" }, [[<leader>Y]], toggle)
  vim.api.nvim_create_user_command([[ToggleConcealCursor]], toggle, {})
end

do
  local syn = vim.fs.joinpath(lib.cfg, "after", "syntax")
  local tax = vim.fs.joinpath(syn, "_.vim")

  vim.api.nvim_create_autocmd({ "Syntax" }, {
    group = lib.group,
    callback = async(function(args)
      if vim.b[args.buf].__conceal__ then
        return
      end
      vim.b[args.buf].__conceal__ = true

      local ft = vim.bo[args.buf].filetype
      local path = vim.fs.joinpath(syn, ft .. ".vim")

      async.scheduled()
      vim.cmd.source(tax)
      if vim.fn.filereadable(path) == 1 then
        vim.cmd.source(path)
      end
    end),
  })
end
