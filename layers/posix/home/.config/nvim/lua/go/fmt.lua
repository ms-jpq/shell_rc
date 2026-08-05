local async = require "goto.async"
local hunks = require "goto.checktime.hunks"
local lib = require "goto.lib"
local proc = require "go.proc"
local snapshot = require "goto.checktime.snapshot"

local timeout = 8888

local data = nil

local fmt_command = function(workdir, buf)
  if data == nil then
    local loadpath = vim.fs.joinpath(proc.cfg, "apriori", "fmt.json")
    data = lib.read_json(loadpath)
  end

  local name = vim.api.nvim_buf_get_name(buf)
  local filetype = vim.bo[buf].filetype
  local spec = data[filetype]

  if spec ~= nil then
    if vim.fn.executable(spec.command) == 1 then
      local mapped = vim
        .iter({
          proc.sandbox(workdir, {}),
          { spec.command },
          spec.args == vim.NIL and {} or spec.args,
        })
        :flatten()
        :map(function(val)
          local l1 = string.gsub(val, [[%%{buffer_name}]], name)
          return l1
        end)
        :totable()

      return mapped
    end
  end

  return { vim.fs.joinpath(proc.cfg, "libexec", "fmt.sed") }
end

local fmt = function()
  if not vim.bo.modifiable then
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local changedtick = vim.api.nvim_buf_get_changedtick(buf)
  -- local name = vim.api.nvim_buf_get_name(buf)
  local cwd = vim.fn.getcwd()

  local cmd = fmt_command(cwd, buf)
  local stdin = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local opts = { cwd = cwd, stdin = stdin, text = true }

  vim.notify([[⏳...]], vim.log.levels.INFO)

  local f = async.future()
  local proc = vim.system(cmd, opts, f.resolve)
  local timer = vim.defer_fn(function()
    proc:kill(9)
  end, timeout)

  local waited = f.await()
  timer:stop()
  timer:close()
  async.scheduled()

  if waited.signal ~= 0 then
    vim.notify([[☠️ ]] .. vim.inspect(waited), vim.log.levels.ERROR)
    return
  elseif waited.code ~= 0 then
    vim.notify([[⚠️ ]] .. vim.inspect(waited), vim.log.levels.ERROR)
    return
  end

  if not vim.api.nvim_buf_is_valid(buf) or not vim.bo[buf].modifiable then
    return
  end

  if vim.api.nvim_buf_get_changedtick(buf) ~= changedtick then
    vim.notify([[🖐️...]], vim.log.levels.WARN)
    return
  end

  local current = snapshot.current(buf)
  local lines = vim.split(waited.stdout, lib.LF, { plain = true })
  if lines[#lines] == "" then
    lines[#lines] = nil
  end
  local formatted = snapshot.fit(current, table.concat(lines, current.linefeed))
  hunks.replace(buf, current, formatted, function() end)
  vim.notify([[✅...]], vim.log.levels.INFO)
end

Go.run_fmt = function()
  async.run(fmt)
  return 0
end

vim.opt.formatexpr = "v:lua.Go.run_fmt()"

vim.keymap.set({ "n" }, "gq", Go.run_fmt, { noremap = true, nowait = true })
