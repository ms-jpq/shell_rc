local base = vim.fs.joinpath(vim.uv.os_homedir(), ".cache", "helix-rt", "nvim")
local packed = vim.fs.joinpath(base, "pack")

local safe_require = function(module)
  local ok, err = pcall(require, module)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end
  return err
end

do
  safe_require "go.pack.coq-nvim"

  vim.opt.packpath:append { packed }
  local ok, err = pcall(vim.cmd.packloadall)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end

  if not coq then
    -- basic autocomplete
    vim.opt.autocomplete = true
  end

  safe_require "go.pack.coq-3p"
  safe_require "go.pack.easyalign"
  safe_require "go.pack.fzf"
  safe_require "go.pack.gitsigns"
  safe_require "go.pack.illuminate"
  safe_require "go.pack.leap"
  safe_require "go.pack.theme"

  local lsp_on = safe_require "go.pack.lsp"
  lsp_on()
end

vim.schedule(function()
  safe_require "go.pack.treesitter"
end)
