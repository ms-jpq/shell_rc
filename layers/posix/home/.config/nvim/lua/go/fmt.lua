local async = require "go.async"
local lib = require "go"

local timeout = 8888

local data = nil

local fmt_command = function(workdir, buf)
  if data == nil then
    local loadpath = vim.fs.joinpath(vim.fn.stdpath "config", "apriori", "fmt.json")
    data = lib.read_json(loadpath)
  end

  local name = vim.api.nvim_buf_get_name(buf)
  local filetype = vim.bo[buf].filetype
  local spec = data[filetype]

  if spec ~= nil then
    if vim.fn.executable(spec.command) == 1 then
      local mapped = vim
        .iter({ lib.sandbox(workdir, {}), { spec.command }, spec.args == vim.NIL and {} or spec.args })
        :flatten()
        :map(function(val)
          local l1 = string.gsub(val, [[%%{buffer_name}]], name)
          return l1
        end)
        :totable()

      return mapped
    end
  end

  return { "sed", "-E", "-e", [[:l1]], "-e", [[/./,$!d]], "-e", [[/^\n*$/{$d;N;}]], "-e", [[/\n$/bl1]] }
end

local fmt = function()
  if not vim.bo.modifiable then
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  -- local name = vim.api.nvim_buf_get_name(buf)
  local cwd = vim.fn.getcwd()

  local cmd = fmt_command(cwd, buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local opts = { cwd = cwd, stdin = lines, text = true }

  vim.notify([[⏳...]], vim.log.levels.INFO)

  local resolve, await = async.future()
  local proc = vim.system(cmd, opts, resolve)
  async.run(function()
    async.sleep(timeout)
    proc:kill(9)
  end)

  local waited = await()
  async.scheduled()

  if waited.signal ~= 0 then
    vim.notify([[☠️ ]] .. vim.inspect(waited), vim.log.levels.ERROR)
    return
  elseif waited.code ~= 0 then
    vim.notify([[⚠️ ]] .. vim.inspect(waited), vim.log.levels.ERROR)
    return
  end

  if vim.api.nvim_get_current_buf() == buf then
    local result = vim.split(waited.stdout, "\n", { plain = true })

    if result[#result] == "" then
      result[#result] = nil
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, result)
    vim.notify([[✅...]], vim.log.levels.INFO, {})
  end
end

Go.run_fmt = function()
  async.run(fmt)
  return 0
end

vim.opt.formatexpr = "v:lua.Go.run_fmt()"

vim.keymap.set("n", "gq", Go.run_fmt, { noremap = true, nowait = true })
