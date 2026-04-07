local lib = require "go"

local timeout = 8888

local data = nil

local fmt_command = function(buf)
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
        .iter({ { spec.command }, spec.args })
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

Go.run_fmt = function()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  local cwd = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()

  local cmd = fmt_command(buf)

  local handle = nil
  local on_exit = function(waited)
    if handle then
      vim.uv.timer_stop(handle)
    end

    if waited.signal ~= 0 then
      vim.notify([[☠️ ]] .. vim.inspect(waited), vim.log.levels.ERROR)
      return
    elseif waited.code ~= 0 then
      vim.notify([[⚠️ ]] .. vim.inspect(waited), vim.log.levels.ERROR)
      return
    end

    if vim.api.nvim_get_current_buf() == buf then
      local lines = vim.split(waited.stdout, "\n", { plain = true })

      if lines[#lines] == "" then
        lines[#lines] = nil
      end
      vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
      vim.notify([[✅...]], vim.log.levels.INFO, {})
    end
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local opts = { cwd = cwd, stdin = lines, text = true }

  vim.notify([[⏳...]], vim.log.levels.INFO, {})
  local proc = nil
  handle = vim.defer_fn(function()
    if proc then
      proc:kill(9)
      proc:wait(0)
      vim.notify([[⚠️ ]] .. vim.inspect(proc), vim.log.levels.ERROR)
    end
  end, timeout)
  proc = vim.system(cmd, opts, vim.schedule_wrap(on_exit))

  return 0
end

vim.opt.formatexpr = "v:lua.Go.run_fmt()"

vim.keymap.set("n", "gq", Go.run_fmt, { noremap = true, nowait = true })
