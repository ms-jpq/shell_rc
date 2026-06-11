local async = require "go.async"
local lib = require "go.lib"
local base = vim.fs.joinpath(vim.uv.os_homedir(), ".cache", "helix-rt", "nvim")
local packed = vim.fs.joinpath(base, "pack")
local opt = vim.fs.joinpath(packed, "opt")

do
  vim.opt.rtp:append { vim.fs.joinpath(opt, "*") }
  vim.opt.packpath:append { packed }
end

do
  lib.report(vim.cmd.packloadall)
  lib.pack "theme"
end

vim.api.nvim_create_autocmd({ "VimEnter" }, {
  group = lib.group,
  once = true,
  callback = async(function()
    local lsp_on = require "go.pack.lsps"
    lsp_on()

    async.scheduled()

    lib.pack "coq-nvim"
    local globbed = vim.fn.globpath(opt, "*/plugin/*.{lua,vim}", true, true)
    for _, file in pairs(globbed) do
      vim.cmd.source(file)
    end

    lib.pack "easyalign"
    lib.pack "fzf"
    lib.pack "gitsigns"
    lib.pack "illuminate"
    lib.pack "leap"
    lib.pack "treesitter"
    -- lib.report(require, "go.pack.coq-3p")
  end),
})
