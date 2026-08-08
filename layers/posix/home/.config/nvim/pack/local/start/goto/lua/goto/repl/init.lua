local async = require "goto.async"
local cmds = require "goto.commands"
local tmux = require "goto.repl.tmux"

local exec = assert(unpack(vim.api.nvim_get_runtime_file("libexec/repl.sh", false)))

local pick_pane = function(buf)
  local state = vim.b[buf]
  if state.__tmux_target__ then
    return state.__tmux_target__
  end

  local panes = tmux.panes()
  table.sort(panes, function(lhs, rhs)
    if lhs.active ~= rhs.active then
      return lhs.active
    elseif lhs.same_window ~= rhs.same_window then
      return lhs.same_window
    elseif lhs.order ~= rhs.order then
      return lhs.order < rhs.order
    else
      return lhs.id < rhs.id
    end
  end)

  local format = function(pane)
    local postfix = (function()
      if pane.same_window then
        return "▣"
      elseif pane.active then
        return "⛶"
      else
        return nil
      end
    end)()
    return table.concat({ pane.location, pane.path, postfix }, " ")
  end

  async.scheduled()
  local pane = async.ui.select(panes, { format_item = format })
  if pane == nil then
    return nil
  end

  state.__tmux_target__ = pane.id
  return pane.id
end

local repl = function()
  if not tmux.CURRENT_PANE then
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(buf)
  local name = vim.fn.fnamemodify(filename, [[:~]])
  local count = vim.api.nvim_buf_line_count(buf)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  local pane_id = pick_pane(buf)
  if not pane_id then
    return
  end

  local argv = { exec, filename, tostring(count), tostring(row), tostring(col + 1), pane_id, name }
  local proc = async.system(argv)

  async.scheduled()
  vim.notify(proc.stdout, vim.log.levels.INFO)
  vim.notify(proc.stderr, vim.log.levels.ERROR)
end

local clear = function()
  vim.b.__tmux_target__ = nil
end

cmds.register { repl = async(repl), ["repl-clear"] = clear }
