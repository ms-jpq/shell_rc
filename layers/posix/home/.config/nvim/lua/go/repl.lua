local async = require "go.async"
local lib = require "go"

local filters = vim.fs.joinpath(vim.fn.stdpath "config", "repl")
local rand = string.gsub(vim.fn.tempname(), "/", "-")
local ns = vim.api.nvim_create_namespace(rand)
local tmux_buf = "nvim-" .. rand

vim.api.nvim_create_user_command("REPLclear", function()
  vim.b.__tmux_target__ = nil
end, {})

local run = function(stdin, args)
  local proc = async.system(args, { stdin = stdin })
  return proc.stdout
end

local parse_panes = function()
  local fmt =
    { "#{pane_id}", "#{window_id}", "#{window_active}", "#{session_name} -> #{window_index} -> #{pane_index}" }
  local win = run(nil, { "tmux", "display-message", "-p", "-F", "#{window_id}" })
  local listed = run(nil, { "tmux", "list-panes", "-a", "-F", table.concat(fmt, rand) })

  local win_id = vim.fn.trim(win)
  local lines = vim.split(listed, "\n", { plain = true, trimempty = true })
  return win_id, lines
end

local pick_pane = function(buf, pane_id)
  local state = vim.b[buf]
  if state.__tmux_target__ then
    return state.__tmux_target__
  end

  local win_id, lines = parse_panes()

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
  local found = unpack(vim.api.nvim_get_runtime_file(prefix .. ".*", true))
  if not found then
    found = vim.fs.joinpath(filters, "_.awk")
  end

  return run(stdin, { found })
end

local tmux_send = function(pane_id, text)
  lib.scope(function(defer)
    defer(function()
      run(nil, { "tmux", "delete-buffer", "-b", tmux_buf })
    end)

    run(text, { "tmux", "load-buffer", "-b", tmux_buf, "--", "-" })
    run(nil, { "tmux", "paste-buffer", "-r", "-p", "-b", tmux_buf, "-t", pane_id })
  end)
end

local eof = function(pane_id)
  async.sleep(99)
  run(nil, { "tmux", "send-keys", "-t", pane_id, "--", "Enter" })
end

local matching = function(buf)
  local re = vim.b[buf].__page_regex__
  return function(line)
    return re and vim.fn.match(line, re) ~= -1
  end
end

local seek = function(match, row, direction)
  local count = direction < 0 and 0 or vim.api.nvim_buf_line_count(0)
  for i = row, count, direction do
    if i == count then
      return i
    end

    local line = unpack(vim.api.nvim_buf_get_lines(0, i, i + 1, true))
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
  lib.scope(function(defer)
    async.scheduled()
    defer(function()
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    end)

    hi = math.max(0, hi - 1)
    local line = unpack(vim.api.nvim_buf_get_lines(0, hi, hi + 1, true))
    vim.highlight.range(buf, ns, "HighlightedyankRegion", { lo, 0 }, { hi, #line }, { inclusive = false })

    fn()
    async.sleep(66)
  end)
end

local repl = function()
  local current_pane = vim.env.TMUX_PANE
  if not current_pane then
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
  local lo = seek(match, row, -1)
  local hi = seek(match, row, 1)

  local lines = vim.api.nvim_buf_get_lines(buf, lo, hi, true)
  local text = table.concat(lines, sep)
  local processed = process(buf, text)
  if processed == "" then
    return
  end

  highlight(buf, lo, hi, function()
    tmux_send(pane_id, processed)
  end)
  eof(pane_id)
end

vim.keymap.set({ "n" }, [[<leader>w]], async(repl))
