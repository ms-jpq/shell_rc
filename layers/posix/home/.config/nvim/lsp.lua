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
  local command = merged.cmd[1]
  if next(extensions) ~= nil then
    acc[command] = {
      extensionToLanguage = extensions,
      command = command,
      args = vim.list_slice(merged.cmd, 2),
      initializationOptions = merged.init_options,
      settings = merged.settings,
    }
  end
end

local json = vim.json.encode(acc, { indent = [[  ]], sort_keys = true })
io.stdout:write(json)
