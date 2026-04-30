#!/usr/bin/env -S -- nvim -l

local cfg = vim.fn.stdpath "config"
vim.opt.rtp:append {
  cfg,
  vim.fs.joinpath(vim.fn.stdpath "cache", "..", "helix-rt", "nvim", "pack", "start", "nvim-lspconfig"),
}

require "lspconfig"
local lsp_on = require "go.pack.lsp"

local filetypes = {}
for ext, filetype in pairs(vim.filetype.inspect().extension) do
  if type(filetype) == "string" then
    if not filetypes[filetype] then
      filetypes[filetype] = {}
    end

    table.insert(filetypes[filetype], ext)
  end
end

local acc = {}
for _, row in pairs(lsp_on()) do
  local merged, exts = unpack(row)
  local extensions = vim.empty_dict()
  for _, filetype in pairs(merged.filetypes or {}) do
    for _, ext in pairs(filetypes[filetype] or {}) do
      extensions["." .. ext] = filetype
    end
  end

  local mapping = vim.tbl_extend("force", extensions, exts)
  if next(mapping) then
    local command = merged.cmd[1]
    acc[command] = {
      extensionToLanguage = mapping,
      command = command,
      args = vim.list_slice(merged.cmd, 2),
      initializationOptions = merged.init_options,
      settings = merged.settings,
    }
  end
end

local json = vim.json.encode(acc, { indent = [[  ]], sort_keys = true })
io.stdout:write(json)
