local async = require "go.async"
local lib = require "go"
local base = vim.fs.joinpath(vim.uv.os_homedir(), ".cache", "helix-rt", "nvim")
local packed = vim.fs.joinpath(base, "pack")
local opt = vim.fs.joinpath(packed, "opt")

do
  vim.opt.rtp:append { vim.fs.joinpath(opt, "*") }
  vim.opt.packpath:append { packed }
end

local safe_require = function(module)
  local ok, err = pcall(require, module)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end
  return err
end

do
  safe_require "go.pack.coq-nvim"

  local ok, err = pcall(vim.cmd.packloadall)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end

  if not coq then
    -- basic autocomplete
    vim.opt.autocomplete = true
  end

  safe_require "go.pack.coq-3p"
  safe_require "go.pack.theme"
  safe_require "go.pack.treesitter"

  local lsp_on = safe_require "go.pack.lsp"
  lsp_on()
end

vim.api.nvim_create_autocmd({ "VimEnter" }, {
  group = lib.group,
  once = true,
  callback = async(function()
    async.scheduled()
    local globbed = vim.fn.globpath(opt, "*/plugin/*.{lua,vim}", true, true)
    for _, file in pairs(globbed) do
      vim.cmd.source(file)
    end

    safe_require "go.pack.easyalign"
    safe_require "go.pack.fzf"
    safe_require "go.pack.gitsigns"
    safe_require "go.pack.illuminate"

    safe_require "go.pack.leap"
  end),
})
