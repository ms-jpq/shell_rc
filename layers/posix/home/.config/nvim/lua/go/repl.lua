local lib = require("go")

local tmux_buf = string.gsub("nvim-" .. vim.fn.tempname(), "/", "-")
local ns = vim.api.nvim_create_namespace(tmux_buf)
local tmux_send = function(buf, pane, lo, hi)
  local sep = lib.buf_linefeed(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, lo, hi, true)
  local text = table.concat(lines, sep)

  local ok, err =
    pcall(
    function()
      for _, stdin in ipairs {text, sep} do
        local proc1 = vim.system({"tmux", "load-buffer", "-b", tmux_buf, "--", "-"}, {stdin = stdin}):wait()
        assert(proc1.code == 0, vim.inspect(proc1))
        local proc2 = vim.system("tmux", "paste-buffer", "-r", "-p", "-t", pane, "-b", tmux_buf):wait()
        assert(proc2.code == 0, vim.inspect(proc2))
      end
    end
  )

  if not ok then
    vim.notify(err, vim.log.levels.ERROR)

    local proc3 = vim.system({"tmux", "delete-buffer", "-b", tmux_buf}):wait()
    assert(proc3.code == 0, vim.inspect(proc3))
  end
end

local pick_pane = function()
  local sep = "u"
  local proc1 = vim.system({"tmux", "display-message", "-p", "-F", "#{window_id}"}):wait()
  assert(proc1.code == 0, vim.inspect(proc1))
  local proc2 =
    vim.system(
    "tmux",
    "list-panes",
    "-a",
    "-F",
    table.concat(
      {"#{pane_id}", "#{window_id}", "#{window_active}", "#{session_name} -> #{window_index} -> #{pane_index}"},
      sep
    )
  ):wait()
  assert(proc2.code == 0, vim.inspect(proc2))

  local acc = {}
  local win_id = vim.fn.trim(proc1.stdout)
  for idx, line in vim.split(proc2.stdout, "\n", {plain = true}) do
    local p_id, w_id, w_active, info = unpack(vim.split(line, sep, {plain = true}))
    if p_id ~= pane_id then
      local this = w_id == win_id
      local active = w_active == "1"
    end
  end
end

vim.keymap.set(
  "n",
  [[<leader>e]],
  function()
    local buf = vim.api.nvim_get_current_buf()
    local pane = pick_pane()
    tmux_send(buf, pane, 0, -1)
  end
)
