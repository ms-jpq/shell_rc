local lib = require "go.lib"
local lsp_path = vim.fs.joinpath(vim.fn.stdpath "config", "apriori", "lsp.json")

local build_overrides = function(conf)
  local acc = { detached = false }
  for _, k in pairs { "cmd", "filetypes", "init_options", "settings" } do
    if conf[k] and conf[k] ~= vim.NIL then
      acc[k] = conf[k]
    end
  end
  return acc
end

return function()
  local acc = {}

  local json = lib.read_json(lsp_path)
  for name, conf in pairs(json) do
    if conf == vim.NIL then
      conf = {}
    end
    local overrides = build_overrides(conf)

    vim.lsp.config(name, overrides)
    local merged = vim.lsp.config[name]
    local argv = merged.cmd or {}

    if type(argv) ~= "table" then
      vim.notify([[☠️ ]] .. name, vim.log.levels.ERROR)
    else
      table.insert(acc, { merged, conf.extensions or vim.empty_dict() })
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = lib.group,
      pattern = merged.filetypes,
      once = true,
      callback = function()
        local bin = unpack(argv)
        if bin and vim.fn.executable(bin) == 1 then
          overrides.cmd = function(dispatchers, config)
            local workdir = (config or {}).root_dir or vim.fn.getcwd()
            local cmd = vim.list_extend(lib.sandbox(workdir, conf.sandbox or {}), argv)

            return vim.lsp.rpc.start(cmd, dispatchers)
          end
          vim.lsp.config(name, overrides)
          local ok, err = pcall(vim.lsp.enable, name)

          if not ok then
            vim.schedule(function()
              vim.notify(name .. ": " .. err, vim.log.levels.WARN)
            end)
          end
        end
      end,
    })
  end

  return acc
end
