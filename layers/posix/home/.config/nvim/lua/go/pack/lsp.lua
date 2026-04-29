local lib = require "go"
local lsp_path = vim.fs.joinpath(vim.fn.stdpath "config", "apriori", "lsp.json")

return function()
  local acc = {}

  local json = lib.read_json(lsp_path)
  for name, conf in pairs(json) do
    if conf == vim.NIL then
      conf = {}
    end

    local overrides = { detached = false }
    for _, k in pairs { "cmd", "filetypes", "init_options", "settings" } do
      if conf[k] and conf[k] ~= vim.NIL then
        overrides[k] = conf[k]
      end
    end

    vim.lsp.config(name, overrides)
    local merged = vim.lsp.config[name]
    local argv = merged.cmd

    if type(argv) == "table" then
      vim.api.nvim_create_autocmd("FileType", {
        group = lib.group,
        pattern = merged.filetypes or { "*" },
        once = true,
        callback = function()
          local bin = unpack(argv)
          if bin and vim.fn.executable(bin) == 1 then
            if coq then
              overrides = coq.lsp_ensure_capabilities(overrides)
            end

            overrides.cmd = function(dispatchers, config)
              local workdir = (config or {}).root_dir or vim.fn.getcwd()
              local cmd = vim.iter({ lib.sandbox(workdir, conf.sandbox or {}), argv }):flatten():totable()

              return vim.lsp.rpc.start(cmd, dispatchers)
            end
            vim.lsp.config(name, overrides)
            vim.lsp.enable(name)
          end
        end,
      })

      table.insert(acc, { merged, conf.extensions or vim.empty_dict() })
    else
      vim.notify([[☠️ ]] .. name, vim.log.levels.ERROR)
    end
  end

  return acc
end
