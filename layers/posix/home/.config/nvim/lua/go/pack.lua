local lib = require("go")

local base = vim.fs.joinpath(vim.uv.os_homedir(), ".cache", "helix-rt", "nvim")
local packed = vim.fs.joinpath(base, "pack")
local lsp_path = vim.fs.joinpath(vim.fn.stdpath("config"), "apriori", "lsp.json")

require("go.pack.coq-nvim")

vim.opt.packpath:append(packed)
vim.cmd.packloadall()

local packloadopt = function()
  local opt = vim.fs.joinpath(base, "pack", "opt")
  for name in vim.fs.dir(opt) do
    local path = vim.fs.joinpath(opt, name)
    vim.cmd.packadd(vim.fn.escape(name, [[\ ]]))
    vim.opt.runtimepath:append(path)

    for _, dir in pairs {"plugin", "lua"} do
      local pat = vim.fs.joinpath(path, dir, "*.{vim,lua}")
      for _, f in ipairs(vim.fn.glob(pat, false, true)) do
        vim.cmd.source(f)
      end
    end
  end
end

vim.api.nvim_create_autocmd(
  {"VimEnter"},
  {
    callback = vim.schedule_wrap(
      function()
        packloadopt()

        require("go.pack.copilot")
        require("go.pack.coq-3p")
        require("go.pack.easyalign")
        require("go.pack.fzf")
        require("go.pack.gitsigns")
        require("go.pack.illuminate")
        require("go.pack.leap")
        require("go.pack.treesitter")
      end
    )
  }
)

require("go.pack.theme")

for name, conf in pairs(lib.read_json(lsp_path)) do
  local overrides = {}
  if conf.filetypes then
    overrides.filetypes = conf.filetypes
  end
  if conf.init_options then
    overrides.init_options = conf.init_options
  end
  if conf.settings then
    overrides.settings = conf.settings
  end
  local cmds =
    conf.args and vim.iter({{""}, conf.args}):flatten():totable() or
    vim.iter({(vim.lsp.config[name] or {}).cmd or {}}):flatten():totable()
  cmds[1] = conf.bin
  overrides.cmd = cmds

  overrides = require("coq").lsp_ensure_capabilities(overrides)
  vim.lsp.config(name, overrides)

  if vim.fn.executable(conf.bin) ~= 0 then
    vim.lsp.enable(name)
  end
end
