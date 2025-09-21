Go.run_fmt = function()
  local name = vim.api.nvim_buf_get_name(0)
  local cwd = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
  local timeout = 99

  local cmd = {"tee", "--"}

  local on_stderr = function()
  end
  local on_exit = function()
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  local opts = {cwd = cwd, stdin = lines, stderr = on_stderr, text = true}
  local proc = vim.system(cmd, opts, on_exit)

  proc:wait(timeout)
end

vim.opt.formatexpr = "v:Go.run_fmt()"

vim.keymap.set("n", "gq", Go.run_fmt, {noremap = true, nowait = true})
