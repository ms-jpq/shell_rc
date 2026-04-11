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

    local bin = unpack(merged.cmd)
    if bin and vim.fn.executable(bin) ~= 0 then
      vim.lsp.enable(name)
    end

    table.insert(acc, { merged, conf.extensions or {} })
  end

  return acc
end
