#!/usr/bin/env -S -- nvim -l

local cfg = vim.fs.dirname(vim.fs.dirname(arg[0]))
vim.opt.rtp:append {
  cfg,
  vim.fs.joinpath(vim.fn.stdpath "cache", "..", "helix-rt", "nvim", "pack", "start", "nvim-lspconfig"),
}

require "lspconfig"
local libexec = require "go.libexec"
local lsp_on = require "go.pack.lsps"

local filetypes = libexec.filetypes()

local acc = vim.iter(lsp_on()):fold({}, function(acc, row)
  local merged, exts = unpack(row)

  local extensions = vim
    .iter(merged.filetypes or {})
    :map(function(filetype)
      return vim
        .iter(filetypes[filetype] or {})
        :map(function(ext)
          return { "." .. ext, filetype }
        end)
        :totable()
    end)
    :flatten()
    :fold(vim.empty_dict(), function(extensions, pair)
      extensions[pair[1]] = pair[2]
      return extensions
    end)

  local mapping = vim.tbl_extend("force", extensions, exts)
  if not vim.tbl_isempty(mapping) then
    local command = merged.cmd[1]
    acc[command] = {
      file_exts = mapping,
      command = command,
      args = vim.list_slice(merged.cmd, 2),
      initializationOptions = merged.init_options,
      settings = merged.settings,
    }
  end

  return acc
end)

local json = libexec.json_encode(acc)
io.stdout:write(json)
