#!/usr/bin/env -S -- nvim -l

local cfg = vim.fn.stdpath "config"
vim.opt.rtp:append {
  cfg,
  vim.fs.joinpath(vim.fn.stdpath "cache", "..", "helix-rt", "nvim", "pack", "start", "nvim-lspconfig"),
}

require "lspconfig"
local lsp_on = require "go.pack.lsps"

local filetypes = {}
vim
  .iter(vim.filetype.inspect().extension)
  :filter(function(_, filetype)
    return type(filetype) == "string"
  end)
  :each(function(ext, filetype)
    filetypes[filetype] = filetypes[filetype] or {}
    table.insert(filetypes[filetype], ext)
  end)

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
      extensionToLanguage = mapping,
      command = command,
      args = vim.list_slice(merged.cmd, 2),
      initializationOptions = merged.init_options,
      settings = merged.settings,
    }
  end

  return acc
end)

local json = vim.json.encode(acc, { indent = [[  ]], sort_keys = true })
io.stdout:write(json)
