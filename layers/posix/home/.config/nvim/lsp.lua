#!/usr/bin/env -S -- nvim -l

local cfg = vim.fn.stdpath "config"
vim.opt.rtp:append {
  cfg,
  vim.fs.joinpath(vim.fn.stdpath "cache", "..", "helix-rt", "nvim", "pack", "start", "nvim-lspconfig"),
}

require "lspconfig"
local lsp_on = require "go.pack.lsp"

local acc = {}
for _, row in pairs(lsp_on()) do
  local merged, extensions = unpack(row)
  local mapping = vim.empty_dict()
  for _, ext in pairs(extensions) do
    mapping[ext] = merged.filetypes[1]
  end

  local command = merged.cmd[1]
  local stem = vim.fn.fnamemodify(command, ":t:r")
  if #extensions ~= 0 then
    acc[stem] = {
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
