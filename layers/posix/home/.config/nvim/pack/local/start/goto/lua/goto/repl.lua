local async = require "goto.async"
local cmds = require "goto.commands"

local REPL_IFS = string.char(31)
local exec = assert(unpack(vim.api.nvim_get_runtime_file("libexec/repl.sh", false)))

local metadata = function(buf, target)
  local filename = vim.fn.fnamemodify(vim.fn.bufname(buf), [[:p]])
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local paths = vim.iter(vim.fs.parents(filename)):totable()
  table.remove(paths)

  return {
    REPL_ANCESTOR_PATHS = table.concat(paths, ":"),
    REPL_FILE_NAME = filename,
    REPL_IFS = REPL_IFS,
    REPL_LINE_COL = tostring(col + 1),
    REPL_LINE_COUNT = tostring(vim.api.nvim_buf_line_count(buf)),
    REPL_LINE_ROW = tostring(row),
    REPL_PARENT_PATH = vim.fs.dirname(filename),
    REPL_PRETTY_NAME = vim.fn.fnamemodify(filename, [[:~]]),
    REPL_TARGET = target,
  }
end
local pick = function(buf)
  local target = vim.b[buf].__repl_target__
  if target and string.find(target, REPL_IFS, 1, true) then
    return target
  end

  local proc = async.system({ exec }, { env = metadata(buf, "") })
  async.scheduled()
  if proc.code ~= 0 or proc.stderr ~= "" then
    vim.notify(proc.stderr .. proc.stdout, vim.log.levels.ERROR)
    return
  end
  if proc.stdout == "" then
    vim.notify([[🚫]], vim.log.levels.ERROR)
    return
  end

  local choices = vim.split(proc.stdout, "\0", { plain = true, trimempty = true })
  if #choices == 0 then
    return nil
  end
  async.scheduled()
  target = async.ui.select(choices, {
    format_item = function(choice)
      local line = string.gsub(choice, "^[^" .. REPL_IFS .. "]*" .. REPL_IFS, "")
      return string.gsub(line, REPL_IFS, " ")
    end,
  })
  vim.b[buf].__repl_target__ = target
  return target
end

local repl = function()
  local buf = vim.api.nvim_get_current_buf()
  local target = pick(buf)
  if not target then
    return
  end

  vim.api.nvim_buf_call(buf, function()
    vim.cmd [[silent! write! ++p]]
  end)
  local proc = async.system({ exec }, { env = metadata(buf, target) })

  async.scheduled()
  vim.notify(proc.stdout, vim.log.levels.INFO)
  vim.notify(proc.stderr, vim.log.levels.ERROR)
end

local clear = function()
  vim.b.__repl_target__ = nil
end

cmds.register { repl = async(repl), ["repl-clear"] = clear }
