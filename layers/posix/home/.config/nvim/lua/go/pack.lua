local lib = require "go"

local base = vim.fs.joinpath(vim.uv.os_homedir(), ".cache", "helix-rt", "nvim")
local packed = vim.fs.joinpath(base, "pack")

local safe_require = function(module)
  local ok, err = pcall(require, module)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end
  return err
end

local packloadopt = function()
  local opt = vim.fs.joinpath(base, "pack", "opt")
  for name in vim.fs.dir(opt) do
    local path = vim.fs.joinpath(opt, name)
    vim.cmd.packadd(vim.fn.escape(name, [[\ ]]))
    vim.opt.runtimepath:append { path }

    for _, dir in pairs { "plugin", "lua" } do
      local pat = vim.fs.joinpath(path, dir, "*.{vim,lua}")
      for _, f in ipairs(vim.fn.glob(pat, false, true)) do
        vim.cmd.source(f)
      end
    end
  end
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

  safe_require "go.pack.theme"
  local lsp_on = safe_require "go.pack.lsp"
  lsp_on()
end

vim.api.nvim_create_autocmd({ "VimEnter" }, {
  group = lib.group,
  once = true,
  callback = vim.schedule_wrap(function()
    packloadopt()

    safe_require "go.pack.coq-3p"
    safe_require "go.pack.easyalign"
    safe_require "go.pack.fzf"
    safe_require "go.pack.gitsigns"
    safe_require "go.pack.illuminate"
    safe_require "go.pack.leap"
    safe_require "go.pack.treesitter"
  end),
})
