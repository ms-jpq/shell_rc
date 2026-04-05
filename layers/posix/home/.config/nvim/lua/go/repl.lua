local lib = require("go")
local ns = vim.api.nvim_create_namespace()

local tmux_buf = "nvim"
local run = function(lo, hi)
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, lo, hi, true)
  local sep = lib.buf_linefeed(buf)
  local text = table.concat(lines, sep)

  local proc = vim.system({"tmux", "load-buffer", "-b", tmux_buf, "--", "-"}, {stdin = text}):wait()
end

run()
