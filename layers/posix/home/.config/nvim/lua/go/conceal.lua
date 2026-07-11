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

  local apply = function(buf)
    local ft = vim.bo[buf].filetype
    if ft == "" then
      return false
    end

    local path = vim.fs.joinpath(syn, ft .. ".vim")

    vim.api.nvim_buf_call(buf, function()
      vim.cmd.source(tax)
      if vim.fn.filereadable(path) == 1 then
        vim.cmd.source(path)
      end
    end)

    return true
  end

  vim.api.nvim_create_autocmd({ "FileType", "FileChangedShellPost" }, {
    group = lib.group,
    callback = async(function(args)
      local buf = args.buf
      if vim.b[buf].__conceal__ and args.event ~= "FileChangedShellPost" then
        return
      end

      async.scheduled()
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end

      vim.b[buf].__conceal__ = apply(buf)
    end),
  })
end
