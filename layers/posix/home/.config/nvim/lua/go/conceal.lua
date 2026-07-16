local async = require "go.async"
local lib = require "go.lib"

do
  local conceal = 2
  vim.opt.conceallevel = conceal
  vim.opt.concealcursor = [[nc]]

  local toggle = function()
    vim.opt.conceallevel = vim.o.conceallevel == 0 and conceal or 0
  end

  vim.keymap.set({ "n" }, [[<leader>Y]], toggle)
  vim.api.nvim_create_user_command([[ToggleConcealCursor]], toggle, {})
end

vim.cmd.syntax "manual"

do
  local prefix = "cole_"

  local enable = function(buf)
    async.scheduled()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end

    local ft = vim.bo[buf].filetype
    local syntax = prefix .. ft
    if ft ~= "" and vim.bo[buf].syntax ~= syntax then
      vim.bo[buf].syntax = syntax
    end
  end

  vim.api.nvim_create_autocmd({ "Syntax" }, {
    group = lib.group,
    pattern = prefix .. "*",
    callback = function(args)
      if vim.treesitter.highlighter.active[args.buf] then
        return
      end

      local ft = string.sub(args.match, #prefix + 1)
      local tax = vim.fs.joinpath("syntax", ft .. ".vim")

      vim.cmd.runtime { tax, bang = true }
    end,
  })

  vim.api.nvim_create_autocmd({ "BufReadPost", "FileChangedShellPost", "FileType" }, {
    group = lib.group,
    callback = async(function(args)
      enable(args.buf)
    end),
  })

  vim.api.nvim_create_autocmd({ "VimEnter" }, {
    group = lib.group,
    once = true,
    callback = async(function()
      for _, buf in pairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          enable(buf)
        end
      end
    end),
  })
end
