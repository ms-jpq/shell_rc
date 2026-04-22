local lib = require "go"
local lsp_path = vim.fs.joinpath(vim.fn.stdpath "config", "apriori", "lsp.json")

return function()
  local acc = {}

  for name, conf in pairs(lib.read_json(lsp_path)) do
    local keys = { "cmd", "filetypes", "init_options", "settings" }
    local overrides = { detached = false }
    for _, k in pairs(keys) do
      if conf[k] then
        overrides[k] = conf[k]
      end
    end

    if coq then
      overrides = coq.lsp_ensure_capabilities(overrides)
    end

    vim.lsp.config(name, overrides)
    local merged = vim.lsp.config[name]

    local argv = merged.cmd
    if type(argv) == "table" then
      local bin = unpack(argv)

      if bin and vim.fn.executable(bin) == 1 then
        overrides.cmd = function(dispatchers, config)
          local workdir = (config or {}).root_dir or vim.fn.getcwd()
          local cmd = vim.iter({ lib.sandbox(workdir), argv }):flatten():totable()

          return vim.lsp.rpc.start(cmd, dispatchers)
        end
        vim.lsp.config(name, overrides)
        vim.lsp.enable(name)
      end

      table.insert(acc, { merged, conf.extensions or vim.empty_dict() })
    else
      vim.notify([[☠️ ]] .. name, vim.log.levels.ERROR)
    end
  end

  return acc
end
