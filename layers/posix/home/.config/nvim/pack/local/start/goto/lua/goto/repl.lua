local async = require "goto.async"
local cmds = require "goto.commands"

local exec = assert(unpack(vim.api.nvim_get_runtime_file("libexec/repl.sh", false)))

local metadata = function(buf, target)
  local filename = vim.api.nvim_buf_get_name(buf)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local paths = vim
    .iter(vim.fs.parents(filename))
    :filter(function(path)
      return path ~= "/"
    end)
    :join ":"

  return {
    REPL_FILE_NAME = filename,
    REPL_LINE_COL = tostring(col + 1),
    REPL_LINE_COUNT = tostring(vim.api.nvim_buf_line_count(buf)),
    REPL_LINE_ROW = tostring(row),
    REPL_PRETTY_NAME = vim.fn.fnamemodify(filename, [[:~]]),
    REPL_TARGET = target,
    REPL_TARGET_PATH = paths,
  }
end
local pick = function(buf)
  local target = vim.b[buf].__repl_target__
  if target then
    return target
  end

  local proc = async.system({ exec }, { env = metadata(buf, "") })
  if proc.code ~= 0 then
    vim.notify(proc.stderr, vim.log.levels.ERROR)
    return
  end

  local choices = vim.split(proc.stdout, "\0", { plain = true, trimempty = true })
  if #choices == 0 then
    return nil
  end
  async.scheduled()
  target = async.ui.select(choices, {
    format_item = function(choice)
      return string.match(choice, "^[^\t]*\t(.*)") or choice
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

  local proc = async.system({ exec }, { env = metadata(buf, target) })

  async.scheduled()
  vim.notify(proc.stdout, vim.log.levels.INFO)
  vim.notify(proc.stderr, vim.log.levels.ERROR)
end

local clear = function()
  vim.b.__repl_target__ = nil
end

cmds.register { repl = async(repl), ["repl-clear"] = clear }
