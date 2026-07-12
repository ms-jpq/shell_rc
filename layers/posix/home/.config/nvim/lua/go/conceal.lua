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
  local prefix = "__go_conceal__"
  local syn = vim.fs.joinpath(lib.cfg, "after", "syntax")
  local tax = vim.fs.joinpath(syn, "_.vim")

  local syntax_name = function(ft)
    return prefix .. ft
  end

  local syntax_ft = function(syntax)
    return string.match(syntax, "^" .. prefix .. "(.+)$")
  end

  local enable = function(buf)
    local ft = vim.bo[buf].filetype
    if ft ~= "" and vim.bo[buf].syntax ~= syntax_name(ft) then
      vim.bo[buf].syntax = syntax_name(ft)
    end
  end

  vim.api.nvim_create_autocmd({ "VimEnter" }, {
    group = lib.group,
    once = true,
    callback = function()
      vim.cmd.syntax "manual"

      vim.api.nvim_create_autocmd({ "Syntax" }, {
        group = lib.group,
        callback = function(args)
          local ft = syntax_ft(args.match)
          if not ft then
            return
          end

          local path = vim.fs.joinpath(syn, ft .. ".vim")

          vim.cmd.source(tax)
          if vim.fn.filereadable(path) == 1 then
            vim.cmd.source(path)
          end
        end,
      })

      vim.api.nvim_create_autocmd({ "BufReadPost", "FileChangedShellPost", "FileType" }, {
        group = lib.group,
        callback = function(args)
          enable(args.buf)
        end,
      })

      for _, buf in pairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          enable(buf)
        end
      end
    end,
  })
end
