local lib = require("go")
local ns = vim.api.nvim_create_namespace()

local tmux_buf = string.gsub("nvim-" .. vim.fn.tempname(), "/", "-")
local send = function(buf, lo, hi, pane)
  local sep = lib.buf_linefeed(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, lo, hi, true)
  local text = table.concat(lines, sep)

  local ok, err =
    pcall(
    function()
      for _, stdin in ipairs {text, sep} do
        local proc1 = vim.system({"tmux", "load-buffer", "-b", tmux_buf, "--", "-"}, {stdin = text}):wait()
        assert(proc1.code == 0, vim.inspect(proc1))
        local proc2 = vim.system("tmux", "paste-buffer", "-r", "-p", "-t", pane, "-b", tmux_buf):wait()
        assert(proc2.code == 0, vim.inspect(proc2))
      end
    end
  )

  if not ok then
    vim.notify(err, vim.log.levels.ERROR)

    local proc3 = vim.system({"tmux", "delete-buffer", "-b", tmux_buf}, {stdin = text}):wait()
    assert(proc3.code == 0, vim.inspect(proc3))
  end
end

-- local buf = vim.api.nvim_get_current_buf()
-- send()
