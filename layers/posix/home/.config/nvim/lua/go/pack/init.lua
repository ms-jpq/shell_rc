local async = require "goto.async"
local autocmd = require "goto.autocmd"
local lib = require "goto.lib"
local proc = require "go.proc"
local base = vim.fs.joinpath(vim.uv.os_homedir(), ".cache", "helix-rt", "nvim")
local packed = vim.fs.joinpath(base, "pack")
local opt = vim.fs.joinpath(packed, "opt")

do
  vim.opt.rtp:append { vim.fs.joinpath(opt, "*") }
  vim.opt.packpath:append { packed }
end

do
  lib.report(vim.cmd.packloadall)
  proc.pack "theme"
end

autocmd.vim_enter(function()
  local lsp_on = proc.pack "lsps"
  if lsp_on then
    lsp_on()
  end

  async.scheduled()

  proc.pack "coq-nvim"
  local globbed = vim.fn.globpath(opt, "*/plugin/*.{lua,vim}", true, true)
  for _, file in pairs(globbed) do
    vim.cmd.source(file)
  end

  proc.pack "easyalign"
  proc.pack "fzf"
  proc.pack "gitsigns"
  proc.pack "illuminate"
  proc.pack "leap"
  proc.pack "treesitter"
  -- lib.report(require, "go.pack.coq-3p")
end)
