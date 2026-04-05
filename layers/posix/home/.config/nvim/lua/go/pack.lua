local lib = require("go")

local base = vim.fs.joinpath(vim.uv.os_homedir(), ".cache", "helix-rt", "nvim")
local packed = vim.fs.joinpath(base, "pack")
local lsp_path = vim.fs.joinpath(vim.fn.stdpath("config"), "apriori", "lsp.json")

local safe_require = function(module)
  local ok, err = pcall(require, module)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end
end

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

local lsp_on = function()
  for name, conf in pairs(lib.read_json(lsp_path)) do
    local keys = {"filetypes", "init_options", "settings"}
    local overrides = {detached = false}
    for _, k in pairs(keys) do
      if conf[k] then
        overrides[k] = conf[k]
      end
    end

    local argv = conf.args and {{""}, conf.args} or {(vim.lsp.config[name] or {}).cmd or {}}
    local cmds = vim.iter(argv):flatten():totable()
    cmds[1] = conf.bin
    overrides.cmd = cmds

    if coq then
      overrides = coq.lsp_ensure_capabilities(overrides)
    end
    vim.lsp.config(name, overrides)

    if vim.fn.executable(conf.bin) ~= 0 then
      vim.lsp.enable(name)
    end
  end
end

do
  safe_require("go.pack.coq-nvim")

  vim.opt.packpath:append(packed)
  local ok, err = pcall(vim.cmd.packloadall)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end

  safe_require("go.pack.treesitter")
  safe_require("go.pack.theme")
  lsp_on()
end

vim.api.nvim_create_autocmd(
  {"VimEnter"},
  {
    group = lib.group,
    once = true,
    callback = vim.schedule_wrap(
      function()
        packloadopt()

        safe_require("go.pack.copilot")
        safe_require("go.pack.coq-3p")
        safe_require("go.pack.easyalign")
        safe_require("go.pack.fzf")
        safe_require("go.pack.gitsigns")
        safe_require("go.pack.illuminate")
        safe_require("go.pack.leap")
      end
    )
  }
)
