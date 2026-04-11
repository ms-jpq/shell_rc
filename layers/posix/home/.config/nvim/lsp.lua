#!/usr/bin/env -S -- nvim -l

local cfg = vim.fn.stdpath "config"
vim.opt.rtp:append {
  cfg,
  vim.fs.joinpath(vim.fn.stdpath "cache", "..", "helix-rt", "nvim", "pack", "start", "nvim-lspconfig"),
}

require "lspconfig"
local lsp_on = require "go.pack.lsp"

local acc = {}
for name, merged in pairs(lsp_on()) do
  acc[name] = {
    _filetypes = merged.filetypes,
    extensionToLanguage = {},
    command = merged.cmd[1],
    args = vim.list_slice(merged.cmd, 2),
    initializationOptions = merged.init_options,
    settings = merged.settings,
  }
end

local json = vim.json.encode(acc, { indent = [[  ]], sort_keys = true })
local jq = "map_values(.extensionToLanguage = [._filetypes[]? | ($map[0][.] // [])[]] | del(._filetypes))"

local proc = vim
  .system({ "jq", "-e", "--slurpfile", "map", vim.fs.joinpath(cfg, "ftdetect", "mappings.json"), jq }, { stdin = json })
  :wait()

assert(proc.code == 0)
io.stdout:write(proc.stdout)
