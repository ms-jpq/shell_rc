local async = require "goto.async"
local cmds = require "goto.commands"
local lib = require "goto.lib"

local exec = assert(unpack(vim.api.nvim_get_runtime_file("libexec/repl.sh", false)))
local rand = string.gsub(vim.fn.tempname(), "/", "-")

local socket = vim.env.__TMUX_ROOT_SOCKET__ or string.match(vim.env.TMUX or "", "^[^,]+")
local current_pane = vim.env.__TMUX_ROOT_PANE__ or vim.env.TMUX_PANE
local cmd = { "tmux", "-S", socket }

local tmux = function(stdin, args)
  local argv = vim.list_extend({ unpack(cmd) }, args)
  local proc = async.system(argv, { stdin = stdin })
  return proc.stdout
end

local parse_panes = function(pane_id)
  local fmt =
    { "#{pane_id}", "#{window_id}", "#{window_active}", "#{session_name} -> #{window_index} -> #{pane_index}" }
  local win = tmux(nil, { "display-message", "-t", pane_id, "-p", "-F", "#{window_id}" })
  local listed = tmux(nil, { "list-panes", "-a", "-F", table.concat(fmt, rand) })

  local win_id = string.match(win, "%S+")
  local lines = vim.gsplit(listed, lib.LF, { plain = true, trimempty = true })
  return win_id, lines
end

local pick_pane = function(buf, pane_id)
  local state = vim.b[buf]
  if state.__tmux_target__ then
    return state.__tmux_target__
  end

  local win_id, lines = parse_panes(pane_id)

  local acc = vim
    .iter(lines)
    :enumerate()
    :map(function(idx, line)
      local p_id, w_id, w_active, info = unpack(vim.split(line, rand, { plain = true }))
      if p_id ~= pane_id then
        local this = w_id == win_id
        local active = w_active == "1"
        local pid = tonumber(string.sub(p_id, 2))

        return { active, this, idx, pid, p_id, info }
      end
    end)
    :totable()

  table.sort(acc, function(lhs, rhs)
    local l_active, l_this, l_idx, l_pid = unpack(lhs)
    local r_active, r_this, r_idx, r_pid = unpack(rhs)

    if l_active ~= r_active then
      return l_active
    elseif l_this ~= r_this then
      return l_this
    elseif l_idx ~= r_idx then
      return l_idx < r_idx
    else
      return l_pid < r_pid
    end
  end)

  local format = function(item)
    local active, this, _, _, _, info = unpack(item)
    local postfix = (function()
      if this then
        return "▣"
      elseif active then
        return "⛶"
      else
        return nil
      end
    end)()
    return table.concat({ info, postfix }, " ")
  end

  async.scheduled()
  local item = async.ui.select(acc, { format_item = format })
  if item == nil then
    return nil
  end

  local _, _, _, _, p_id = unpack(item)
  state.__tmux_target__ = p_id
  return p_id
end

local repl = function()
  if not socket or not current_pane then
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(buf)
  local name = vim.fn.fnamemodify(filename, [[:~]])
  local count = vim.api.nvim_buf_line_count(buf)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  local pane_id = pick_pane(buf, current_pane)
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
