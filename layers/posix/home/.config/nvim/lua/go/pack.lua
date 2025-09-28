local lib = require("go")

local base = vim.fs.joinpath(vim.uv.os_homedir(), ".cache", "helix-rt", "nvim")
local packed = vim.fs.joinpath(base, "pack")
local lsp_path = vim.fs.joinpath(vim.fn.stdpath("config"), "apriori", "lsp.json")

vim.opt.packpath:append(packed)

require("go.pack.start.coq")
require("go.pack.start.fzf")

vim.cmd.packloadall()

local packloadopt = function()
  local opt = vim.fs.joinpath(base, "pack", "opt")
  for name in vim.fs.dir(opt) do
    local path = vim.fs.joinpath(opt, name)
    vim.cmd.packadd(vim.fn.escape(name, [[\ ]]))
    vim.opt.runtimepath:append(path)

    for ext, dir in pairs {vim = "plugin", lua = "lua"} do
      local pat = vim.fs.joinpath(path, dir, "*." .. ext)
      for _, f in ipairs(vim.fn.glob(pat, false, true)) do
        vim.cmd.source(f)
      end
    end
  end
end

require("go.pack.start.leap")
require("go.pack.start.theme")
require("go.pack.start.treesitter")

for name, conf in pairs(lib.read_json(lsp_path)) do
  local overrides = {
    cmd = conf.args and vim.iter({{conf.bin}, conf.args}):flatten():totable() or nil,
    filetypes = conf.filetypes,
    init_options = conf.init_options,
    settings = conf.settings
  }

  local config = {}
  for key, val in pairs(overrides) do
    if val ~= nil then
      config[key] = val
    end
  end

  config = require("coq").lsp_ensure_capabilities(config)
  vim.lsp.config(name, config)

  if vim.fn.executable(conf.bin) ~= 0 then
    vim.lsp.enable(name)
  end
end

vim.api.nvim_create_autocmd(
  {"VimEnter"},
  {
    callback = vim.schedule_wrap(
      function()
        packloadopt()

        require("go.pack.opt.copilot")
        require("go.pack.opt.easyalign")
        require("go.pack.opt.gitsigns")
        require("go.pack.opt.illuminate")
      end
    )
  }
)
