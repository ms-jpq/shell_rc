local async = require "go.async"
local lib = require "go.lib"

local filters = vim.fs.joinpath(lib.cfg, "repl")
local rand = string.gsub(vim.fn.tempname(), "/", "-")
local ns = vim.api.nvim_create_namespace(rand)
local send_text = vim.fs.joinpath(lib.cfg, "..", "tmux", "libexec", "send-text.sh")

local socket = vim.env.__TMUX_ROOT_SOCKET__ or string.match(vim.env.TMUX or "", "^[^,]+")
local current_pane = vim.env.__TMUX_ROOT_PANE__ or vim.env.TMUX_PANE
local cmd = { "tmux", "-S", socket }

vim.api.nvim_create_user_command("REPLclear", function()
  vim.b.__tmux_target__ = nil
end, {})

local run = function(stdin, args)
  local proc = async.system(args, { stdin = stdin })
  return proc.stdout
end

local tmux = function(stdin, args)
  local argv = { unpack(cmd) }
  return run(stdin, vim.list_extend(argv, args))
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
        return "✱"
      elseif active then
        return "◉"
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

local process = function(buf, stdin)
  local prefix = vim.fs.joinpath(filters, vim.bo[buf].filetype)
  local found = unpack(vim.fn.glob(prefix .. ".*", false, true))
  if not found then
    found = vim.fs.joinpath(filters, "_.awk")
  end

  return run(stdin, { found })
end

local matching = function(buf)
  local re = vim.b[buf].__page_regex__
  return function(line)
    return re and vim.fn.match(line, re) ~= -1
  end
end

local seek = function(buf, match, row, direction)
  local count = direction < 0 and 0 or vim.api.nvim_buf_line_count(buf)
  for i = row, count, direction do
    if i == count then
      return i
    end

    local line = unpack(vim.api.nvim_buf_get_lines(buf, i, i + 1, true))
    if match(line) then
      if direction < 0 then
        return i + (direction * -1)
      end
      return i
    end
  end
  return row
end

local highlight = function(buf, lo, hi, fn)
  async.scheduled()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  hi = math.max(0, hi - 1)
  local line = unpack(vim.api.nvim_buf_get_lines(buf, hi, hi + 1, true))
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  vim.hl.range(buf, ns, "HighlightedyankRegion", { lo, 0 }, { hi, #line }, { inclusive = false, timeout = 66 })
  fn()
end

local repl = function()
  if not socket or not current_pane then
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1

  local pane_id = pick_pane(buf, current_pane)
  if not pane_id then
    return
  end

  local match = matching(buf)
  local sep = lib.buf_linefeed(buf)
  local lo = seek(buf, match, row, -1)
  local hi = seek(buf, match, row, 1)

  local lines = vim.api.nvim_buf_get_lines(buf, lo, hi, true)
  local text = table.concat(lines, sep)
  local processed = process(buf, text)
  if processed == "" then
    return
  end

  highlight(buf, lo, hi, function()
    run(processed, { send_text, pane_id })
  end)
end

vim.keymap.set({ "n" }, [[<leader>w]], async(repl))
