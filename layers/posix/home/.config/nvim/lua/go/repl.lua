local lib = require("go")

local rand = string.gsub(vim.fn.tempname(), "/", "-")
local tmux_buf = "nvim-" .. rand
local tmux_send = function(buf, pane, lo, hi)
  local sep = lib.buf_linefeed(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, lo, hi, true)
  local text = table.concat(lines, sep)

  if text == "" then
    return
  end

  local ok, err =
    pcall(
    function()
      for _, stdin in ipairs {text, sep} do
        local proc1 = vim.system({"tmux", "load-buffer", "-b", tmux_buf, "--", "-"}, {stdin = stdin}):wait()
        assert(proc1.code == 0, vim.inspect(proc1))
        local proc2 = vim.system({"tmux", "paste-buffer", "-r", "-p", "-b", tmux_buf, "-t", pane}):wait()
        assert(proc2.code == 0, vim.inspect(proc2))
      end
    end
  )

  local proc3 = vim.system({"tmux", "delete-buffer", "-b", tmux_buf}):wait()
  assert(proc3.code == 0, vim.inspect(proc3))

  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end
end

vim.api.nvim_create_user_command(
  "ReplClear",
  function()
    vim.b.__tmux_target__ = nil
  end,
  {}
)

local pick_pane = function(buf, pane_id, callback)
  local state = vim.b[buf]
  if state.__tmux_target__ then
    callback(state.__tmux_target__)
    return
  end

  local proc1 = vim.system({"tmux", "display-message", "-p", "-F", "#{window_id}"}):wait()
  assert(proc1.code == 0, vim.inspect(proc1))
  local proc2 =
    vim.system(
    {
      "tmux",
      "list-panes",
      "-a",
      "-F",
      table.concat(
        {"#{pane_id}", "#{window_id}", "#{window_active}", "#{session_name} -> #{window_index} -> #{pane_index}"},
        rand
      )
    }
  ):wait()
  assert(proc2.code == 0, vim.inspect(proc2))

  local acc = {}
  local win_id = vim.fn.trim(proc1.stdout)
  local lines = vim.split(proc2.stdout, "\n", {plain = true, trimempty = true})
  for idx, line in ipairs(lines) do
    local p_id, w_id, w_active, info = unpack(vim.split(line, rand, {plain = true}))
    if p_id ~= pane_id then
      local this = w_id == win_id
      local active = w_active == "1"
      local pid = tonumber(string.sub(p_id, 2))

      table.insert(acc, {active, this, idx, pid, p_id, info})
    end
  end

  table.sort(
    acc,
    function(lhs, rhs)
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
    end
  )

  vim.ui.select(
    acc,
    {
      format_item = function(item)
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
        return table.concat({info, postfix}, " ")
      end
    },
    function(item)
      if item ~= nil then
        local _, _, _, _, p_id = unpack(item)
        state.__tmux_target__ = p_id
        callback(p_id)
      end
    end
  )
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

local matching = function(buf)
  local re = vim.b[buf].__page_regex__
  return function(line)
    return re and vim.fn.match(line, re) ~= -1
  end
end

local repl = function()
  local pane_id = vim.env.TMUX_PANE
  if not pane_id then
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1
  local match = matching(buf)

  pick_pane(
    buf,
    pane_id,
    function(pane)
      local lo = seek(match, row, -1)
      local hi = seek(match, row, 1)
      tmux_send(buf, pane, lo, hi)
    end
  )
end

vim.keymap.set("n", [[<leader>w]], repl)
