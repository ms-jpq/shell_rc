local async = require "go.async"
local lib = require "go.lib"
local to = require "go.text_objects"

local is_ok = function(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" then
    return true
  end
  return vim.secure.read(path)
end

local run = function(visual)
  return async(function()
    local buf = vim.api.nvim_get_current_buf()
    if not is_ok(buf) then
      return
    end

    local lines = (function()
      if visual then
        local r1, c1, r2, c2 = to.operator_marks(buf, nil)
        return vim.api.nvim_buf_get_text(buf, r1, c1, r2 + 1, c2, {})
      else
        return { vim.api.nvim_get_current_line() }
      end
    end)()

    local cmd = table.concat(lines, lib.buf_linefeed(buf))
    vim.notify(cmd, vim.log.levels.WARN)

    local proc = async.system({ vim.o.shell }, { stdin = cmd, text = true })
    vim.notify(proc.stderr, vim.log.levels.WARN)
    vim.notify(proc.stdout, vim.log.levels.INFO)
  end)
end

vim.keymap.set({ "n" }, "<leader>!", run(false))
vim.keymap.set({ "x" }, "<leader>!", run(true))
