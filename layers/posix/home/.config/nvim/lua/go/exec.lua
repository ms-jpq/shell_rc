local async = require "go.async"
local lib = require "go.lib"
local operators = require "go.operators"

local db = vim.fs.joinpath(vim.fn.stdpath "state", "user-trust")

local is_ok = function(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  local sha = path ~= "" and vim.fs.joinpath(db, vim.fn.sha256(path))

  if not sha or vim.fn.filereadable(sha) == 1 then
    return true
  end

  local format = function(x)
    return x
  end
  local choice = async.ui.select({ "oui", "nein" }, { format_item = format })
  if choice ~= "oui" then
    return false
  end

  assert(vim.fn.mkdir(db, "p"))
  assert(vim.fn.writefile("", sha))
  return true
end

local run = function(visual)
  return async(function()
    local buf = vim.api.nvim_get_current_buf()
    if not is_ok(buf) then
      return
    end

    local lines = (function()
      if visual then
        return operators.visual_lines()
      else
        return { vim.api.nvim_get_current_line() }
      end
    end)()

    local cmd = table.concat(lines, lib.buf_linefeed(buf))

    local proc = async.system({ vim.o.shell }, { stdin = cmd, text = true })
    async.scheduled()
    vim.notify(proc.stderr, vim.log.levels.WARN)
    vim.notify(proc.stdout, vim.log.levels.INFO)
  end)
end

vim.keymap.set({ "n" }, "<leader>m", run(false))
vim.keymap.set({ "x" }, "<leader>m", run(true))
