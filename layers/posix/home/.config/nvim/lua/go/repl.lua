local lib = require("go")

local filters = vim.fs.joinpath(vim.fn.stdpath("config"), "repl")
local rand = string.gsub(vim.fn.tempname(), "/", "-")
local ns = vim.api.nvim_create_namespace(rand)
local tmux_buf = "nvim-" .. rand

vim.api.nvim_create_user_command(
  "ReplClear",
  function()
    vim.b.__tmux_target__ = nil
  end,
  {}
)

local parse_panes = function()
  local proc1 = vim.system({"tmux", "display-message", "-p", "-F", "#{window_id}"}):wait()
  assert(proc1.code == 0)
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
  assert(proc2.code == 0)

  local win_id = vim.fn.trim(proc1.stdout)
  local lines = vim.split(proc2.stdout, "\n", {plain = true, trimempty = true})
  return win_id, lines
end
local pick_pane = function(buf, pane_id, callback)
  local state = vim.b[buf]
  if state.__tmux_target__ then
    callback(state.__tmux_target__)
    return
  end

  local win_id, lines = parse_panes()
  local acc = {}
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
    return table.concat({info, postfix}, " ")
  end

  local pick = function(item)
    if item ~= nil then
      local _, _, _, _, p_id = unpack(item)
      state.__tmux_target__ = p_id
      callback(p_id)
    end
  end

  vim.ui.select(acc, {format_item = format}, pick)
end

local process = function(buf, text)
  local prefix = vim.fs.joinpath(filters, vim.bo[buf].filetype)
  local found = unpack(vim.api.nvim_get_runtime_file(prefix .. ".*", true))
  if not found then
    found = vim.fs.joinpath(filters, "_.awk")
  end

  local ok, rsp =
    pcall(
    function()
      local proc = vim.system({found}, {stdin = text}):wait()
      assert(proc.code == 0)
      return proc.stdout
    end
  )

  if not ok then
    vim.notify(rsp, vim.log.levels.ERROR)
    return ""
  end
  return rsp
end

local tmux_send = function(pane, text)
  local ok, err =
    pcall(
    function()
      local proc1 = vim.system({"tmux", "load-buffer", "-b", tmux_buf, "--", "-"}, {stdin = text}):wait()
      assert(proc1.code == 0)
      local proc2 = vim.system({"tmux", "paste-buffer", "-r", "-p", "-b", tmux_buf, "-t", pane}):wait()
      assert(proc2.code == 0)
    end
  )

  local _, _ =
    pcall(
    function()
      local proc3 = vim.system({"tmux", "delete-buffer", "-b", tmux_buf}):wait()
      assert(proc3.code == 0)
    end
  )

  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end
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

local highlight = function(buf, lo, hi)
  hi = math.max(0, hi - 1)
  local line = unpack(vim.api.nvim_buf_get_lines(0, hi, hi + 1, true))
  vim.highlight.range(buf, ns, "HighlightedyankRegion", {lo, 0}, {hi, #line}, {inclusive = false})
end

local nohighlight = function(buf)
  vim.defer_fn(
    function()
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    end,
    99
  )
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

  local callback = function(pane)
    local sep = lib.buf_linefeed(buf)
    local lo = seek(match, row, -1)
    local hi = seek(match, row, 1)

    local lines = vim.api.nvim_buf_get_lines(buf, lo, hi, true)
    local text = table.concat(lines, sep)
    local processed = process(buf, text)
    if processed == "" then
      return
    end

    highlight(buf, lo, hi)
    tmux_send(pane, processed)
    nohighlight(buf)
  end

  pick_pane(buf, pane_id, callback)
end

vim.keymap.set("n", [[<leader>w]], repl)
